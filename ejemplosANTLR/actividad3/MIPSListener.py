"""
MIPSListener — Compilador RaraLang → MIPS (QtSPIM)

Iteración 6: bloques `{ ... }` y `while ... do ...` sobre la base de las
cinco iteraciones anteriores.

Arquitectura (no cambia):
  - Sólo patrón Listener. Sin Visitor, sin intérprete.
  - Pool LIFO de registros temporales $t0..$t9.
  - Convención: cada `expr` deja resultado en `ctx.reg`, tipo en `ctx.kind`.
  - Precedencia: decidida por el orden de alternativas en la gramática.

Lo nuevo en iter 6:
─────────────────────
1) **`blockStmt`** (`{ stmt* }`): NO genera código propio. `exitBlockStmt`
   es literalmente `pass`. Las sentencias internas ya emitieron al
   buffer activo durante el walk; el block solo agrupa sintácticamente
   y le da al if/while una sola "stmt" como body, aunque internamente
   sean varias.

2) **`whileStmt`** (`while cond do stmt`): mismo mecanismo de buffers
   que el if, simplificado. Frame con dos buffers (cond, body). Al
   salir se ensambla:

       loop_start_N:
           [cond]
           beq cond_reg, $zero, loop_end_N    ← forward jump (salida)
           [body]
           j loop_start_N                      ← backward jump (loop)
       loop_end_N:

3) **Frame unificado `_CtrlFrame`**: discrimina por `kind` (if/while)
   y guarda N buffers (3 para if: cond/then/else_; 2 para while:
   cond/body). `enterEveryRule` usa una sola lógica para ambos:
   cada vez que entra un stmt-hijo DIRECTO del frame, se avanza al
   siguiente buffer. Eso garantiza que los frames de if y while no
   se "mezclen": cada uno tiene su propio ctx y su propio array de
   buffers, y la detección por `ctx.parentCtx is frame.ctx` los
   mantiene aislados.
"""

from antlr.generated.RaraLangListener import RaraLangListener
from antlr.generated.RaraLangParser import RaraLangParser


_MUL  = "\u00D7"
_DIV  = "\u00F7"
_MOD  = "\u229E"
_DPLS = "\u22A0"
_AVG  = "\u2248"


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
    """Frame unificado para if y while activos durante el walk.

    Atributos:
      kind       : "if" o "while"
      id         : número único dentro de su clase (para labels)
      ctx        : el IfStmtContext o WhileStmtContext del frame
      buffers    : lista de listas; índice 0 = cond,
                                    índice 1 = then (if) o body (while),
                                    índice 2 = else_ (solo if)
      phase_idx  : qué buffer está activo actualmente (0 al inicio)
    """

    def __init__(self, kind: str, id_: int, ctx, n_buffers: int) -> None:
        self.kind = kind
        self.id = id_
        self.ctx = ctx
        self.buffers: list[list[str]] = [[] for _ in range(n_buffers)]
        self.phase_idx: int = 0


class MIPSListener(RaraLangListener):
    def __init__(self) -> None:
        super().__init__()
        self._data: list[str] = []
        self._text: list[str] = []
        self._buffers: list[list[str]] = [self._text]  # pila; tope = destino actual
        self._frames: list[_CtrlFrame] = []
        self._if_counter: int = 0
        self._while_counter: int = 0
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

    # ─── Detección de transiciones (cond → then/body → else) ──────────────

    def enterEveryRule(self, ctx):
        """Cuando estamos dentro de un if/while activo y entramos a un
        StmtContext que es hijo directo del frame top, avanzamos al
        siguiente buffer del frame. Funciona uniformemente para if y
        while porque ambos derivan la misma estructura "cond + N stmts".
        """
        if not self._frames:
            return
        if not isinstance(ctx, RaraLangParser.StmtContext):
            return
        frame = self._frames[-1]
        if ctx.parentCtx is not frame.ctx:
            return  # no es nuestro stmt-hijo directo (ej. anidado dentro de un block)
        next_idx = frame.phase_idx + 1
        if next_idx < len(frame.buffers):
            frame.phase_idx = next_idx
            self._buffers.pop()                       # cierra fase anterior
            self._buffers.append(frame.buffers[next_idx])

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
        self._require_int(left, op); self._require_int(right, op)
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
        self._require_int(left, op); self._require_int(right, op)
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

    # ─── expr: aditivos (+ -) ──────────────────────────────────────────────

    def exitAddSub(self, ctx: RaraLangParser.AddSubContext):
        left, right = ctx.expr(0), ctx.expr(1)
        op = ctx.op.text
        self._require_int(left, op); self._require_int(right, op)
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
        self._require_int(left, op); self._require_int(right, op)
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
            self._emit(f"    # >  : {rl} := ({rl} > {rr}) ? 1 : 0   (slt operandos invertidos)")
            self._emit(f"    slt  {rl}, {rr}, {rl}")
        else:
            raise AssertionError(f"op inesperado en compare: {op!r}")
        self._regs.release(rr)
        ctx.reg = rl
        ctx.kind = "int"

    # ─── Sentencias simples ────────────────────────────────────────────────

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

    # ─── Bloque {} — no emite código propio ────────────────────────────────

    def exitBlockStmt(self, ctx: RaraLangParser.BlockStmtContext):
        # Las sentencias internas ya emitieron al buffer activo durante el
        # walk; el block solo agrupa sintácticamente. exitBlockStmt podría
        # NO existir y el comportamiento sería idéntico (la implementación
        # default de RaraLangListener es `pass`). Lo declaramos explícito
        # para documentar la decisión.
        pass

    # ─── if / then / else ──────────────────────────────────────────────────

    def enterIfStmt(self, ctx: RaraLangParser.IfStmtContext):
        self._if_counter += 1
        frame = _CtrlFrame("if", self._if_counter, ctx, n_buffers=3)
        self._frames.append(frame)
        self._buffers.append(frame.buffers[0])  # cond

    def exitIfStmt(self, ctx: RaraLangParser.IfStmtContext):
        frame = self._frames.pop()
        self._buffers.pop()                     # cierra el último buffer (then o else_)
        cond_reg = ctx.expr().reg
        self._require_int(ctx.expr(), "if")
        has_else = len(ctx.stmt()) >= 2          # robusto: viene del AST, no del buffer
        end_lbl  = f"if_end_{frame.id}"
        else_lbl = f"if_else_{frame.id}"

        out = self._buffers[-1]
        out.append(f"    # ===== if #{frame.id} (linea {ctx.start.line}) =====")
        out.append(f"    # ----- cond -----")
        out.extend(frame.buffers[0])             # cond

        if has_else:
            out.append(f"    beq  {cond_reg}, $zero, {else_lbl}   # cond falsa → else")
            out.append(f"    # ----- then -----")
            out.extend(frame.buffers[1])
            out.append(f"    j    {end_lbl}                       # then ejecutado → fin")
            out.append(f"{else_lbl}:")
            out.append(f"    # ----- else -----")
            out.extend(frame.buffers[2])
        else:
            out.append(f"    beq  {cond_reg}, $zero, {end_lbl}    # cond falsa → fin")
            out.append(f"    # ----- then -----")
            out.extend(frame.buffers[1])

        out.append(f"{end_lbl}:")
        out.append(f"    # ===== fin if #{frame.id} =====")
        self._regs.release(cond_reg)

    # ─── while / do ────────────────────────────────────────────────────────

    def enterWhileStmt(self, ctx: RaraLangParser.WhileStmtContext):
        self._while_counter += 1
        frame = _CtrlFrame("while", self._while_counter, ctx, n_buffers=2)
        self._frames.append(frame)
        self._buffers.append(frame.buffers[0])  # cond

    def exitWhileStmt(self, ctx: RaraLangParser.WhileStmtContext):
        frame = self._frames.pop()
        self._buffers.pop()                     # cierra el body
        cond_reg = ctx.expr().reg
        self._require_int(ctx.expr(), "while")
        start_lbl = f"loop_start_{frame.id}"
        end_lbl   = f"loop_end_{frame.id}"

        out = self._buffers[-1]
        out.append(f"    # ===== while #{frame.id} (linea {ctx.start.line}) =====")
        out.append(f"{start_lbl}:")
        out.append(f"    # ----- cond -----")
        out.extend(frame.buffers[0])             # cond
        out.append(f"    beq  {cond_reg}, $zero, {end_lbl}    # cond falsa → salir del ciclo")
        out.append(f"    # ----- body -----")
        out.extend(frame.buffers[1])             # body
        out.append(f"    j    {start_lbl}                     # volver a evaluar cond")
        out.append(f"{end_lbl}:")
        out.append(f"    # ===== fin while #{frame.id} =====")
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
