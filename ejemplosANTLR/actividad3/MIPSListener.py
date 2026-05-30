"""
MIPSListener — Compilador RaraLang → MIPS (QtSPIM)

Iteración 4: operadores enteros Unicode (⊞, ⊠, ≈, ±) sobre la base de
las tres iteraciones anteriores (literales, variables, aritmética).

Arquitectura (no cambia):
  - Sólo patrón Listener de ANTLR. Sin Visitor, sin intérprete.
  - Cada `expr` deja su resultado en un registro temporal asignado
    desde un pool LIFO. El operador padre, en su `exit*`, reusa el
    registro del operando izquierdo como destino y libera el derecho.
  - La precedencia la decide la GRAMÁTICA por el orden de las
    alternativas: ± > (× ÷ ⊞) > (⊠ ≈) > (+ -). No hay lógica de
    precedencia en el listener.

Operadores nuevos de iter 4:
  ⊞ (módulo) — `div rl, rr; mfhi rl` (toma el residuo, no el cociente).
  ⊠ (doble más) — `sll rl, rl, 1; add rl, rl, rr` (×2 vía shift + suma).
  ≈ (promedio piso) — `add rl, rl, rr; sra rl, rl, 1` (sra = arith.
      shift right, que redondea hacia -infinito incluso con negativos).
  ± (negación)    — `sub rl, $zero, rl`.

Decisiones documentadas (para auditar):
  1. ≈ se implementa con `add + sra`, NO con `div by 2 + mflo`. La
     diferencia es exactamente lo que la guía pide: `sra` redondea
     hacia -∞ (floor), mientras que `div` trunca hacia 0. Con
     positivos da lo mismo; con negativos NO.
  2. ⊠ usa `sll` (shift logical left por 1) en vez de `mult` con 2.
     Es más rápido y más legible. Limitación: si 2a desborda 32 bits,
     `sll` simplemente descarta el bit alto (igual que `mult` con `mflo`).
  3. ⊞ (módulo) usa `mfhi`. SPIM define el residuo como "lo que sobra
     después de la división trunca-hacia-cero". O sea, `(-10) ⊞ 3`
     da -1 (no 2 como en Python).
  4. ± reusa el registro del operando (no asigna uno nuevo). Doble
     negación `± ±x` emite dos `sub` consecutivos sobre el mismo
     registro — no es bug, es el camino natural del post-order.
  5. La precedencia de ⊠ y ≈ es DECIDIDA por mí, no por matemática.
     Las puse en un nivel propio entre × y +. Es una decisión defendible
     pero no la única correcta. Ver §auditoría.
"""

from antlr.generated.RaraLangListener import RaraLangListener
from antlr.generated.RaraLangParser import RaraLangParser


# Unicode literales — los uso para comparar con ctx.op.text sin pegar
# bytes raros en el código:
_MUL  = "\u00D7"   # ×
_DIV  = "\u00F7"   # ÷
_MOD  = "\u229E"   # ⊞
_DPLS = "\u22A0"   # ⊠
_AVG  = "\u2248"   # ≈


class _RegisterPool:
    """Pool LIFO de registros temporales $t0..$t9."""

    def __init__(self) -> None:
        self._free: list[str] = [f"$t{i}" for i in range(10)]

    def allocate(self) -> str:
        if not self._free:
            raise RuntimeError(
                "Sin registros temporales: la expresión es demasiado "
                "profunda (>10 valores vivos simultáneamente)."
            )
        return self._free.pop(0)

    def release(self, reg: str) -> None:
        self._free.insert(0, reg)


class MIPSListener(RaraLangListener):
    def __init__(self) -> None:
        super().__init__()
        self._data: list[str] = []
        self._text: list[str] = []
        self._str_counter: int = 0
        self._symbols: dict[str, str] = {}
        self._regs = _RegisterPool()

    # ─── Helpers ───────────────────────────────────────────────────────────

    def _emit(self, line: str) -> None:
        self._text.append(line)

    def _new_str_label(self) -> str:
        label = f"str_{self._str_counter}"
        self._str_counter += 1
        return label

    def _intern_var(self, name: str) -> str:
        if name not in self._symbols:
            label = f"v_{name}"
            self._symbols[name] = label
            self._data.append(f"{label}: .word 0")
        return self._symbols[name]

    def _emit_newline(self) -> None:
        self._emit("    # newline (LF)")
        self._emit("    li   $v0, 11")
        self._emit("    li   $a0, 10")
        self._emit("    syscall")

    def _require_int(self, ctx, where: str) -> None:
        if ctx.kind != "int":
            line = ctx.start.line
            raise TypeError(
                f"Línea {line}: el operador {where!r} requiere enteros, "
                f"no {ctx.kind!r}."
            )

    # ─── expr: hojas ───────────────────────────────────────────────────────

    def exitInt(self, ctx: RaraLangParser.IntContext):
        text = ctx.INT().getText()
        value = int(text)
        reg = self._regs.allocate()
        self._emit(f"    # INT {text} → {reg}")
        self._emit(f"    li   {reg}, {value}")
        ctx.reg = reg
        ctx.kind = "int"

    def exitBased(self, ctx: RaraLangParser.BasedContext):
        token = ctx.BASED_NUMBER().getText()
        body = token[1:-1]
        digits, base_str = body.split(":", 1)
        try:
            base = int(base_str)
            value = int(digits, base)
        except ValueError as e:
            line = ctx.start.line
            col = ctx.start.column
            raise ValueError(
                f"Línea {line}:{col}: literal con base inválido {token!r} — "
                f"'{digits}' no es representable en base {base_str} ({e})"
            ) from e
        reg = self._regs.allocate()
        self._emit(f"    # BASED {token} (= {value}) → {reg}")
        self._emit(f"    li   {reg}, {value}")
        ctx.reg = reg
        ctx.kind = "int"

    def exitString(self, ctx: RaraLangParser.StringContext):
        raw = ctx.STRING().getText()
        text = raw[1:-1]
        label = self._new_str_label()
        self._data.append(f'{label}: .asciiz "{text}"')
        reg = self._regs.allocate()
        self._emit(f"    # STRING {raw} → {reg}")
        self._emit(f"    la   {reg}, {label}")
        ctx.reg = reg
        ctx.kind = "string"

    def exitVar(self, ctx: RaraLangParser.VarContext):
        name = ctx.ID().getText()
        label = self._intern_var(name)
        reg = self._regs.allocate()
        self._emit(f"    # VAR {name} ({label}) → {reg}")
        self._emit(f"    lw   {reg}, {label}")
        ctx.reg = reg
        ctx.kind = "int"

    def exitParens(self, ctx: RaraLangParser.ParensContext):
        inner = ctx.expr()
        ctx.reg = inner.reg
        ctx.kind = inner.kind

    # ─── expr: unario ± ────────────────────────────────────────────────────

    def exitNeg(self, ctx: RaraLangParser.NegContext):
        inner = ctx.expr()
        self._require_int(inner, "±")
        r = inner.reg
        self._emit(f"    # ± : {r} := 0 - {r}")
        self._emit(f"    sub  {r}, $zero, {r}")
        ctx.reg = r
        ctx.kind = "int"

    # ─── expr: binarios multiplicativos (× ÷ ⊞) ────────────────────────────

    def exitMulDiv(self, ctx: RaraLangParser.MulDivContext):
        left, right = ctx.expr(0), ctx.expr(1)
        op = ctx.op.text
        self._require_int(left, op)
        self._require_int(right, op)
        rl, rr = left.reg, right.reg
        if op == _MUL:
            self._emit(f"    # × : {rl} := {rl} × {rr}")
            self._emit(f"    mult {rl}, {rr}")
            self._emit(f"    mflo {rl}")
        elif op == _DIV:
            self._emit(f"    # ÷ : {rl} := {rl} ÷ {rr}   (mflo = cociente)")
            self._emit(f"    div  {rl}, {rr}")
            self._emit(f"    mflo {rl}")
        elif op == _MOD:
            self._emit(f"    # ⊞ : {rl} := {rl} mod {rr}  (mfhi = residuo)")
            self._emit(f"    div  {rl}, {rr}")
            self._emit(f"    mfhi {rl}")
        else:
            raise AssertionError(f"op inesperado en mulDiv: {op!r}")
        self._regs.release(rr)
        ctx.reg = rl
        ctx.kind = "int"

    # ─── expr: binarios custom (⊠ ≈) ───────────────────────────────────────

    def exitCustomBin(self, ctx: RaraLangParser.CustomBinContext):
        left, right = ctx.expr(0), ctx.expr(1)
        op = ctx.op.text
        self._require_int(left, op)
        self._require_int(right, op)
        rl, rr = left.reg, right.reg
        if op == _DPLS:
            # ⊠ : 2a + b  →  sll dobla a (×2 sin pasar por mult/mflo),
            # luego add suma b. Una instrucción menos que la versión naive.
            self._emit(f"    # ⊠ : {rl} := 2*{rl} + {rr}  (sll=×2, add)")
            self._emit(f"    sll  {rl}, {rl}, 1")
            self._emit(f"    add  {rl}, {rl}, {rr}")
        elif op == _AVG:
            # ≈ : floor((a + b) / 2)  →  add suma, sra (arith. shift right)
            # divide por 2 *con redondeo hacia -infinito*. Esto es el
            # comportamiento correcto para negativos según la spec.
            # Limitación conocida: si (a+b) desborda 32 bits, el resultado
            # del sra es incorrecto. Trade-off a favor de simplicidad.
            self._emit(f"    # ≈ : {rl} := piso(({rl} + {rr}) / 2)   (add + sra)")
            self._emit(f"    add  {rl}, {rl}, {rr}")
            self._emit(f"    sra  {rl}, {rl}, 1")
        else:
            raise AssertionError(f"op inesperado en customBin: {op!r}")
        self._regs.release(rr)
        ctx.reg = rl
        ctx.kind = "int"

    # ─── expr: binarios aditivos (+ -) ─────────────────────────────────────

    def exitAddSub(self, ctx: RaraLangParser.AddSubContext):
        left, right = ctx.expr(0), ctx.expr(1)
        op = ctx.op.text
        self._require_int(left, op)
        self._require_int(right, op)
        rl, rr = left.reg, right.reg
        mnemonic = "add " if op == "+" else "sub "
        self._emit(f"    # {op} : {rl} := {rl} {op} {rr}")
        self._emit(f"    {mnemonic} {rl}, {rl}, {rr}")
        self._regs.release(rr)
        ctx.reg = rl
        ctx.kind = "int"

    # ─── Sentencias ────────────────────────────────────────────────────────

    def exitPrintStmt(self, ctx: RaraLangParser.PrintStmtContext):
        expr = ctx.expr()
        reg = expr.reg
        if expr.kind == "int":
            self._emit(f"    # print int (consume {reg})")
            self._emit(f"    move $a0, {reg}")
            self._emit("    li   $v0, 1")
            self._emit("    syscall")
        elif expr.kind == "string":
            self._emit(f"    # print string (consume {reg})")
            self._emit(f"    move $a0, {reg}")
            self._emit("    li   $v0, 4")
            self._emit("    syscall")
        else:
            raise ValueError(f"Tipo desconocido en print: {expr.kind!r}")
        self._regs.release(reg)
        self._emit_newline()

    def exitAssignStmt(self, ctx: RaraLangParser.AssignStmtContext):
        name = ctx.ID().getText()
        expr = ctx.expr()
        if expr.kind != "int":
            line = ctx.start.line
            raise TypeError(
                f"Línea {line}: no se puede asignar un valor de tipo "
                f"{expr.kind!r} a la variable '{name}'. Variables son enteras."
            )
        label = self._intern_var(name)
        reg = expr.reg
        self._emit(f"    # {name} <-- (consume {reg})")
        self._emit(f"    sw   {reg}, {label}")
        self._regs.release(reg)

    # ─── Render final del .asm ─────────────────────────────────────────────

    def output(self) -> str:
        lines: list[str] = []
        lines.append("    .data")
        lines.extend(self._data)
        lines.append("")
        lines.append("    .text")
        lines.append("    .globl main")
        lines.append("main:")
        lines.extend(self._text)
        lines.append("")
        lines.append("    # exit")
        lines.append("    li   $v0, 10")
        lines.append("    syscall")
        return "\n".join(lines) + "\n"
