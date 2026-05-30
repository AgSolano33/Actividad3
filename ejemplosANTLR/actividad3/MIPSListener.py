"""
MIPSListener — Compilador RaraLang → MIPS (QtSPIM)

Iteración 5: comparadores (==, !=, <, >) e if/then/else sobre la base de
las cuatro iteraciones anteriores.

Arquitectura (no cambia):
  - Sólo patrón Listener. Sin Visitor, sin intérprete.
  - Pool LIFO de registros temporales $t0..$t9.
  - Convención: cada `expr` deja resultado en `ctx.reg`, tipo en `ctx.kind`.
  - Precedencia: decidida íntegramente por el orden de alternativas en
    la gramática. El listener no implementa lógica de precedencia.

Lo NUEVO en iter 5: control de flujo con if/then/else
─────────────────────────────────────────────────────
Problema: cuando el walker termina de procesar un IfStmtContext, ya emitió
el código de cond, then y else en orden de aparición. Pero MIPS necesita
INTERCALAR ese código con saltos y etiquetas:

    [cond]
    beq cond_reg, $zero, else_label     ← inyectado entre cond y then
    [then]
    j end_label                          ← inyectado entre then y else
    else_label:
    [else]
    end_label:

Solución: PILA DE BUFFERS. `self._buffers` es un stack; `_emit()` siempre
escribe al tope. Para cada `if`:
  1. enterIfStmt empuja `frame.cond` (lista vacía) al stack → el código
     de la condición se va acumulando ahí.
  2. enterEveryRule detecta cuándo entramos al primer stmt hijo del if
     (= terminó la cond, empieza then) y cambia el buffer del tope a
     `frame.then`. La segunda vez detecta `else`.
  3. exitIfStmt saca el buffer del tope (`then` o `else_`), ensambla
     `[cond] + beq + [then] + j_end + label_else + [else_] + label_end`
     y emite todo eso al buffer que quedó como tope (que es el padre).

¿Por qué `enterIfStmt`/`exitIfStmt` NO bastan? Porque cuando exitIfStmt
ejecuta, las tres sub-secciones ya están emitidas en un mismo buffer y
ya no se pueden separar. Necesitamos un evento INTERMEDIO que detecte
la transición cond→then→else, y ese evento es enterEveryRule observando
el árbol durante el descenso.

cond_reg: durante todo el then/else, el registro que contiene el valor
booleano de la condición queda "ocupado" en el pool. Sólo se libera en
exitIfStmt después del beq.

Labels únicas: contador global `_if_counter`. Cada if estampa
`if_else_N` / `if_end_N`. Imprescindible para anidamientos: si dos ifs
compartieran etiquetas, los saltos colisionarían y el segundo if saltaría
al final del primero.
"""

from antlr.generated.RaraLangListener import RaraLangListener
from antlr.generated.RaraLangParser import RaraLangParser


# Operadores Unicode (para comparar contra ctx.op.text):
_MUL  = "\u00D7"   # ×
_DIV  = "\u00F7"   # ÷
_MOD  = "\u229E"   # ⊞
_DPLS = "\u22A0"   # ⊠
_AVG  = "\u2248"   # ≈


class _RegisterPool:
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


class _CtrlFrame:
    """Estado de un `if` activo durante el walk."""

    def __init__(self, id_: int, if_ctx: "RaraLangParser.IfStmtContext") -> None:
        self.id: int = id_
        self.if_ctx = if_ctx                # para identificar nuestros hijos directos
        self.cond: list[str] = []           # buffer para el código de la condición
        self.then: list[str] = []           # buffer para el código del then
        self.else_: list[str] = []          # buffer para el código del else
        self.then_entered: bool = False     # ya cambiamos cond→then?
        self.else_entered: bool = False     # ya cambiamos then→else?


class MIPSListener(RaraLangListener):
    def __init__(self) -> None:
        super().__init__()
        self._data: list[str] = []
        self._text: list[str] = []
        self._buffers: list[list[str]] = [self._text]   # pila; tope = destino actual de _emit
        self._frames: list[_CtrlFrame] = []
        self._if_counter: int = 0
        self._str_counter: int = 0
        self._symbols: dict[str, str] = {}
        self._regs = _RegisterPool()

    # ─── Emisión ───────────────────────────────────────────────────────────

    def _emit(self, line: str) -> None:
        self._buffers[-1].append(line)

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

    # ─── Detección de transiciones para if/then/else ──────────────────────

    def enterEveryRule(self, ctx):
        """Detecta cuándo entramos al stmt-hijo de un if y cambia el buffer
        activo. Sirve sólo si hay un frame de if en curso y el ctx es un
        StmtContext (o subclase: PrintStmt/AssignStmt/IfStmt) cuyo padre
        directo es el IfStmtContext del frame top.
        """
        if not self._frames:
            return
        if not isinstance(ctx, RaraLangParser.StmtContext):
            return
        frame = self._frames[-1]
        if ctx.parentCtx is not frame.if_ctx:
            return  # no es nuestro hijo directo (ej. stmt anidado más adentro)
        if not frame.then_entered:
            frame.then_entered = True
            self._buffers.pop()             # cerrar cond
            self._buffers.append(frame.then)
        elif not frame.else_entered:
            frame.else_entered = True
            self._buffers.pop()             # cerrar then
            self._buffers.append(frame.else_)

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
            self._emit(f"    # ⊠ : {rl} := 2*{rl} + {rr}  (sll=×2, add)")
            self._emit(f"    sll  {rl}, {rl}, 1")
            self._emit(f"    add  {rl}, {rl}, {rr}")
        elif op == _AVG:
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

    # ─── expr: comparadores (== != < >) ────────────────────────────────────

    def exitCompare(self, ctx: RaraLangParser.CompareContext):
        left, right = ctx.expr(0), ctx.expr(1)
        op = ctx.op.text
        self._require_int(left, op)
        self._require_int(right, op)
        rl, rr = left.reg, right.reg
        if op == "==":
            self._emit(f"    # == : {rl} := ({rl} == {rr}) ? 1 : 0")
            self._emit(f"    seq  {rl}, {rl}, {rr}")
        elif op == "!=":
            self._emit(f"    # != : {rl} := ({rl} != {rr}) ? 1 : 0")
            self._emit(f"    sne  {rl}, {rl}, {rr}")
        elif op == "<":
            self._emit(f"    # <  : {rl} := ({rl} < {rr}) ? 1 : 0")
            self._emit(f"    slt  {rl}, {rl}, {rr}")
        elif op == ">":
            # a > b   ≡   b < a   →   slt con operandos invertidos
            self._emit(f"    # >  : {rl} := ({rl} > {rr}) ? 1 : 0   (= slt con operandos invertidos)")
            self._emit(f"    slt  {rl}, {rr}, {rl}")
        else:
            raise AssertionError(f"op inesperado en compare: {op!r}")
        self._regs.release(rr)
        ctx.reg = rl
        ctx.kind = "int"

    # ─── Sentencias simples (heredadas de iter 1-4) ────────────────────────

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

    # ─── Sentencia if/then/else ────────────────────────────────────────────

    def enterIfStmt(self, ctx: RaraLangParser.IfStmtContext):
        self._if_counter += 1
        frame = _CtrlFrame(self._if_counter, ctx)
        self._frames.append(frame)
        # A partir de aquí, los emits durante la condición van al buffer cond.
        # enterEveryRule cambiará al buffer then cuando entremos al stmt hijo.
        self._buffers.append(frame.cond)

    def exitIfStmt(self, ctx: RaraLangParser.IfStmtContext):
        frame = self._frames.pop()
        # En el tope hay frame.then (si no había else) o frame.else_; lo sacamos.
        self._buffers.pop()

        cond_reg = ctx.expr().reg
        self._require_int(ctx.expr(), "if")
        has_else = bool(frame.else_)
        end_lbl = f"if_end_{frame.id}"
        else_lbl = f"if_else_{frame.id}"

        out = self._buffers[-1]   # buffer del padre — aquí se ensambla todo

        out.append(f"    # ===== if #{frame.id} (linea {ctx.start.line}) =====")
        out.append(f"    # ----- cond -----")
        out.extend(frame.cond)

        if has_else:
            out.append(f"    beq  {cond_reg}, $zero, {else_lbl}   # cond falsa → salta al else")
            out.append(f"    # ----- then -----")
            out.extend(frame.then)
            out.append(f"    j    {end_lbl}                       # then ejecutado → salta al fin")
            out.append(f"{else_lbl}:")
            out.append(f"    # ----- else -----")
            out.extend(frame.else_)
        else:
            out.append(f"    beq  {cond_reg}, $zero, {end_lbl}    # cond falsa → salta al fin (no hay else)")
            out.append(f"    # ----- then -----")
            out.extend(frame.then)

        out.append(f"{end_lbl}:")
        out.append(f"    # ===== fin if #{frame.id} =====")

        # El cond_reg estuvo "ocupado" durante todo then/else; ahora se libera.
        self._regs.release(cond_reg)

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
