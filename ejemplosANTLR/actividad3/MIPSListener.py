"""
MIPSListener — Compilador RaraLang → MIPS (QtSPIM)

Iteración 7: funciones (declaración, llamada, return). Conserva todo lo
de iter 1-6.

Arquitectura (sin cambios):
  - Solo patrón Listener. Sin Visitor, sin intérprete.
  - Convención: cada `expr` deja resultado en `ctx.reg`, tipo en `ctx.kind`.
  - Precedencia decidida por orden de alternativas en gramática.

Lo NUEVO en iter 7
─────────────────────────────────────────────────────────────────────
1) **Convención MIPS estándar**: args en `$a0..$a3`, retorno en `$v0`,
   llamada con `jal`, retorno con `jr $ra`.

2) **Scoping por función**: dentro de `func F(...)`, toda variable (param
   o local) se almacena en `vf_F_<nombre>: .word 0`. Esto:
     - aísla las variables globales (`v_x`) de las locales (`vf_F_x`),
     - usa el MISMO mecanismo de almacenamiento para params y locales
       (los params son sólo locales pre-inicializados desde `$aN` al
       entrar a la función).

3) **Buffer por función**: el listener mantiene una lista de buffers de
   función. Al entrar a `func F`, se PUSH un buffer fresco al stack
   `_buffers`, así todos los `_emit` del cuerpo van a él. Al salir, se
   pop el buffer pero se conserva en `self._func_text` para emitirlo al
   final del .asm — después de main, separado por la `exit syscall`.
   Esto garantiza que **main nunca cae** en código de funciones.

4) **Spilling de t-regs vivos antes de un `jal`**: en MIPS los `$t*` son
   caller-saved. Si el caller tiene valores vivos en `$tN` que necesita
   DESPUÉS del jal, debe salvarlos al stack antes y restaurarlos después.
   `exitCall` consulta el pool para saber qué `$tN` están "en uso"
   (= alocados como reg de alguna expr-padre todavía no consumida) y
   genera el push/pop correspondiente.

5) **Protección de $ra cuando un `jal` ocurre DENTRO de una función**:
   El `jal` sobreescribe `$ra`. Si la función llamadora aún no retornó,
   su `$ra` original se pierde y `jr $ra` saltaría a lugar incorrecto.
   Solución: alrededor de cada `jal` interno se hace:

       addiu $sp, $sp, -4
       sw   $ra, 0($sp)
       jal  func_xxx
       lw   $ra, 0($sp)
       addiu $sp, $sp, 4

   Esto NO se hace si el `jal` está en main (main no retorna; su `$ra`
   es irrelevante).

LIMITACIONES (intencionales, documentadas):
  - Máximo 4 parámetros por función (solo `$a0..$a3`, sin uso del stack
    para argumentos extras).
  - Sin recursión. Los params/locales viven en `.data`, así que una
    segunda invocación clobbearía los valores de la primera.
  - Sin acceso a globales desde funciones: dentro de una función, todo
    nombre se resuelve a la storage `vf_F_*`. Es una decisión de
    aislamiento total (la spec lo pide explícitamente: evitar colisiones).
  - Llamadas requieren que la función esté declarada ANTES (declare-
    before-use). Combinado con "sin recursión", esto excluye también
    mutual recursion.
"""

from antlr.generated.RaraLangListener import RaraLangListener
from antlr.generated.RaraLangParser import RaraLangParser


_MUL  = "\u00D7"
_DIV  = "\u00F7"
_MOD  = "\u229E"
_DPLS = "\u22A0"
_AVG  = "\u2248"

_MAX_PARAMS = 4
_ARG_REGS = [f"$a{i}" for i in range(_MAX_PARAMS)]


class _RegisterPool:
    def __init__(self) -> None:
        self._all = [f"$t{i}" for i in range(10)]
        self._free: list[str] = list(self._all)

    def allocate(self) -> str:
        if not self._free:
            raise RuntimeError(
                "Sin registros temporales: la expresión es demasiado "
                "profunda (>10 valores vivos simultáneamente)."
            )
        return self._free.pop(0)

    def release(self, reg: str) -> None:
        self._free.insert(0, reg)

    def in_use(self) -> list[str]:
        """Lista de $tN actualmente alocados (en orden estable $t0..$t9)."""
        return [r for r in self._all if r not in self._free]


class _CtrlFrame:
    """Frame unificado para if/while activos durante el walk."""
    def __init__(self, kind: str, id_: int, ctx, n_buffers: int) -> None:
        self.kind = kind
        self.id = id_
        self.ctx = ctx
        self.buffers: list[list[str]] = [[] for _ in range(n_buffers)]
        self.phase_idx: int = 0


class _FuncInfo:
    """Metadata de una función declarada."""
    def __init__(self, name: str, params: list[str]) -> None:
        self.name = name
        self.params = params
        self.label = f"func_{name}"  # etiqueta de entrada en el .asm

    @property
    def arity(self) -> int:
        return len(self.params)


class MIPSListener(RaraLangListener):
    def __init__(self) -> None:
        super().__init__()
        self._data: list[str] = []
        self._text: list[str] = []                 # cuerpo de main
        self._func_text: list[list[str]] = []      # cuerpos de funciones, en orden de declaración
        self._buffers: list[list[str]] = [self._text]
        self._frames: list[_CtrlFrame] = []
        self._if_counter: int = 0
        self._while_counter: int = 0
        self._str_counter: int = 0
        # Tabla de símbolos: keys son tuplas para discriminar global/función:
        #   ("global", name)          → label v_<name>
        #   ("func", funcName, name)  → label vf_<funcName>_<name>
        self._symbols: dict = {}
        self._regs = _RegisterPool()
        # Tabla de funciones: nombre → _FuncInfo (necesaria para validar calls).
        self._funcs: dict[str, _FuncInfo] = {}
        # "Dentro de qué función estamos ahora mismo": None = main.
        self._current_func: str | None = None

    # ─── Emisión ───────────────────────────────────────────────────────────

    def _emit(self, line: str) -> None:
        self._buffers[-1].append(line)

    def _new_str_label(self) -> str:
        label = f"str_{self._str_counter}"
        self._str_counter += 1
        return label

    def _intern_var(self, name: str) -> str:
        """Resuelve el nombre a su label MIPS según el scope actual.
        Inside `func F`: vf_F_<name>. En main: v_<name>.
        """
        if self._current_func is not None:
            key = ("func", self._current_func, name)
            if key not in self._symbols:
                label = f"vf_{self._current_func}_{name}"
                self._symbols[key] = label
                self._data.append(f"{label}: .word 0")
            return self._symbols[key]
        key = ("global", name)
        if key not in self._symbols:
            label = f"v_{name}"
            self._symbols[key] = label
            self._data.append(f"{label}: .word 0")
        return self._symbols[key]

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

    # ─── Detección de transiciones para if/while ──────────────────────────

    def enterEveryRule(self, ctx):
        if not self._frames:
            return
        if not isinstance(ctx, RaraLangParser.StmtContext):
            return
        frame = self._frames[-1]
        if ctx.parentCtx is not frame.ctx:
            return
        next_idx = frame.phase_idx + 1
        if next_idx < len(frame.buffers):
            frame.phase_idx = next_idx
            self._buffers.pop()
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
            line, col = ctx.start.line, ctx.start.column
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
            self._emit(f"    mult {rl}, {rr}"); self._emit(f"    mflo {rl}")
        elif op == _DIV:
            self._emit(f"    # ÷ : {rl} := {rl} ÷ {rr}   (mflo = cociente)")
            self._emit(f"    div  {rl}, {rr}"); self._emit(f"    mflo {rl}")
        elif op == _MOD:
            self._emit(f"    # ⊞ : {rl} := {rl} mod {rr}  (mfhi = residuo)")
            self._emit(f"    div  {rl}, {rr}"); self._emit(f"    mfhi {rl}")
        else:
            raise AssertionError(f"op inesperado en mulDiv: {op!r}")
        self._regs.release(rr)
        ctx.reg = rl; ctx.kind = "int"

    # ─── expr: binarios custom (⊠ ≈) ───────────────────────────────────────

    def exitCustomBin(self, ctx: RaraLangParser.CustomBinContext):
        left, right = ctx.expr(0), ctx.expr(1)
        op = ctx.op.text
        self._require_int(left, op); self._require_int(right, op)
        rl, rr = left.reg, right.reg
        if op == _DPLS:
            self._emit(f"    # ⊠ : {rl} := 2*{rl} + {rr}  (sll=×2, add)")
            self._emit(f"    sll  {rl}, {rl}, 1"); self._emit(f"    add  {rl}, {rl}, {rr}")
        elif op == _AVG:
            self._emit(f"    # ≈ : {rl} := piso(({rl} + {rr}) / 2)   (add + sra)")
            self._emit(f"    add  {rl}, {rl}, {rr}"); self._emit(f"    sra  {rl}, {rl}, 1")
        else:
            raise AssertionError(f"op inesperado en customBin: {op!r}")
        self._regs.release(rr)
        ctx.reg = rl; ctx.kind = "int"

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
        ctx.reg = rl; ctx.kind = "int"

    # ─── expr: comparadores (== != < >) ────────────────────────────────────

    def exitCompare(self, ctx: RaraLangParser.CompareContext):
        left, right = ctx.expr(0), ctx.expr(1)
        op = ctx.op.text
        self._require_int(left, op); self._require_int(right, op)
        rl, rr = left.reg, right.reg
        if op == "==":
            self._emit(f"    # == : {rl} := ({rl} == {rr}) ? 1 : 0"); self._emit(f"    seq  {rl}, {rl}, {rr}")
        elif op == "!=":
            self._emit(f"    # != : {rl} := ({rl} != {rr}) ? 1 : 0"); self._emit(f"    sne  {rl}, {rl}, {rr}")
        elif op == "<":
            self._emit(f"    # <  : {rl} := ({rl} < {rr}) ? 1 : 0");  self._emit(f"    slt  {rl}, {rl}, {rr}")
        elif op == ">":
            self._emit(f"    # >  : {rl} := ({rl} > {rr}) ? 1 : 0   (slt operandos invertidos)")
            self._emit(f"    slt  {rl}, {rr}, {rl}")
        else:
            raise AssertionError(f"op inesperado en compare: {op!r}")
        self._regs.release(rr)
        ctx.reg = rl; ctx.kind = "int"

    # ─── expr: call ────────────────────────────────────────────────────────

    def exitCall(self, ctx: RaraLangParser.CallContext):
        name = ctx.ID().getText()
        args = ctx.argList().expr() if ctx.argList() is not None else []
        line = ctx.start.line

        # 1) Validación: existencia + aridad + tipos.
        if name not in self._funcs:
            raise NameError(f"Línea {line}: función '{name}' no declarada (declare-before-use).")
        info = self._funcs[name]
        if len(args) != info.arity:
            raise TypeError(
                f"Línea {line}: '{name}' espera {info.arity} argumento(s) "
                f"({', '.join(info.params) or '∅'}), se pasaron {len(args)}."
            )
        for i, a in enumerate(args):
            self._require_int(a, f"arg {i+1} de {name}")

        arg_regs = [a.reg for a in args]
        # 2) Snapshot de t-regs vivos que NO son arg regs (= valores que deben
        #    sobrevivir el jal). Los arg regs van a ser consumidos por la llamada.
        live = self._regs.in_use()
        to_save = [r for r in live if r not in arg_regs]

        self._emit(f"    # ─── llamada a {name}({', '.join(info.params) or '∅'}) ───")

        # 3) Spill de t-regs vivos (caller-saved) al stack.
        if to_save:
            size = 4 * len(to_save)
            self._emit(f"    # preservar {len(to_save)} t-reg(s) vivos: {', '.join(to_save)}")
            self._emit(f"    addiu $sp, $sp, -{size}")
            for i, r in enumerate(to_save):
                self._emit(f"    sw   {r}, {i*4}($sp)")

        # 4) Cargar args en $a0..$a3 y liberar sus t-regs (consumidos).
        for i, r in enumerate(arg_regs):
            self._emit(f"    move $a{i}, {r}    # arg {i+1} ({info.params[i]})")
        for r in arg_regs:
            self._regs.release(r)

        # 5) Proteger $ra SI el jal está dentro de una función. main no retorna.
        inside_func = self._current_func is not None
        if inside_func:
            self._emit("    # guardar $ra (estamos dentro de una función)")
            self._emit("    addiu $sp, $sp, -4")
            self._emit("    sw   $ra, 0($sp)")

        # 6) jal.
        self._emit(f"    jal  {info.label}")

        # 7) Restaurar $ra si aplica.
        if inside_func:
            self._emit("    lw   $ra, 0($sp)")
            self._emit("    addiu $sp, $sp, 4")

        # 8) Restaurar t-regs caller-saved.
        if to_save:
            for i, r in enumerate(to_save):
                self._emit(f"    lw   {r}, {i*4}($sp)")
            self._emit(f"    addiu $sp, $sp, {4*len(to_save)}")

        # 9) Recoger valor de retorno desde $v0.
        result = self._regs.allocate()
        self._emit(f"    # resultado de {name}: $v0 → {result}")
        self._emit(f"    move {result}, $v0")
        ctx.reg = result
        ctx.kind = "int"

    # ─── Sentencias simples ────────────────────────────────────────────────

    def exitPrintStmt(self, ctx: RaraLangParser.PrintStmtContext):
        expr = ctx.expr()
        reg = expr.reg
        if expr.kind == "int":
            self._emit(f"    # print int (consume {reg})")
            self._emit(f"    move $a0, {reg}"); self._emit("    li   $v0, 1"); self._emit("    syscall")
        elif expr.kind == "string":
            self._emit(f"    # print string (consume {reg})")
            self._emit(f"    move $a0, {reg}"); self._emit("    li   $v0, 4"); self._emit("    syscall")
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
        self._emit(f"    # {name} <-- (consume {reg})  → {label}")
        self._emit(f"    sw   {reg}, {label}")
        self._regs.release(reg)

    # ─── return ────────────────────────────────────────────────────────────

    def exitReturnStmt(self, ctx: RaraLangParser.ReturnStmtContext):
        if self._current_func is None:
            line = ctx.start.line
            raise SyntaxError(f"Línea {line}: 'return' solo es válido dentro de una función.")
        expr = ctx.expr()
        self._require_int(expr, "return")
        reg = expr.reg
        self._emit(f"    # return: {reg} → $v0 y regresar a quien llamó")
        self._emit(f"    move $v0, {reg}")
        self._regs.release(reg)
        self._emit("    jr   $ra")

    # ─── Bloque {} — no emite código propio ────────────────────────────────

    def exitBlockStmt(self, ctx: RaraLangParser.BlockStmtContext):
        # Por simetría declaramos también este método pero el block no emite
        # nada: sus stmts ya emitieron al buffer activo en orden.
        pass

    # ─── if / then / else ──────────────────────────────────────────────────

    def enterIfStmt(self, ctx: RaraLangParser.IfStmtContext):
        self._if_counter += 1
        frame = _CtrlFrame("if", self._if_counter, ctx, n_buffers=3)
        self._frames.append(frame)
        self._buffers.append(frame.buffers[0])

    def exitIfStmt(self, ctx: RaraLangParser.IfStmtContext):
        frame = self._frames.pop()
        self._buffers.pop()
        cond_reg = ctx.expr().reg
        self._require_int(ctx.expr(), "if")
        has_else = len(ctx.stmt()) >= 2
        end_lbl  = f"if_end_{frame.id}"
        else_lbl = f"if_else_{frame.id}"
        out = self._buffers[-1]
        out.append(f"    # ===== if #{frame.id} (linea {ctx.start.line}) =====")
        out.append(f"    # ----- cond -----")
        out.extend(frame.buffers[0])
        if has_else:
            out.append(f"    beq  {cond_reg}, $zero, {else_lbl}   # cond falsa → else")
            out.append(f"    # ----- then -----"); out.extend(frame.buffers[1])
            out.append(f"    j    {end_lbl}                       # then ejecutado → fin")
            out.append(f"{else_lbl}:")
            out.append(f"    # ----- else -----"); out.extend(frame.buffers[2])
        else:
            out.append(f"    beq  {cond_reg}, $zero, {end_lbl}    # cond falsa → fin")
            out.append(f"    # ----- then -----"); out.extend(frame.buffers[1])
        out.append(f"{end_lbl}:")
        out.append(f"    # ===== fin if #{frame.id} =====")
        self._regs.release(cond_reg)

    # ─── while / do ────────────────────────────────────────────────────────

    def enterWhileStmt(self, ctx: RaraLangParser.WhileStmtContext):
        self._while_counter += 1
        frame = _CtrlFrame("while", self._while_counter, ctx, n_buffers=2)
        self._frames.append(frame)
        self._buffers.append(frame.buffers[0])

    def exitWhileStmt(self, ctx: RaraLangParser.WhileStmtContext):
        frame = self._frames.pop()
        self._buffers.pop()
        cond_reg = ctx.expr().reg
        self._require_int(ctx.expr(), "while")
        start_lbl = f"loop_start_{frame.id}"
        end_lbl   = f"loop_end_{frame.id}"
        out = self._buffers[-1]
        out.append(f"    # ===== while #{frame.id} (linea {ctx.start.line}) =====")
        out.append(f"{start_lbl}:")
        out.append(f"    # ----- cond -----"); out.extend(frame.buffers[0])
        out.append(f"    beq  {cond_reg}, $zero, {end_lbl}    # cond falsa → salir")
        out.append(f"    # ----- body -----"); out.extend(frame.buffers[1])
        out.append(f"    j    {start_lbl}                     # volver a evaluar cond")
        out.append(f"{end_lbl}:")
        out.append(f"    # ===== fin while #{frame.id} =====")
        self._regs.release(cond_reg)

    # ─── func / return ─────────────────────────────────────────────────────

    def enterFuncDecl(self, ctx: RaraLangParser.FuncDeclContext):
        # Nombre: el primer ID hijo (el de la función).
        # ParamList: opcional; sus IDs son los parámetros.
        name = ctx.ID().getText()
        if ctx.paramList() is not None:
            param_names = [t.getText() for t in ctx.paramList().ID()]
        else:
            param_names = []

        line = ctx.start.line
        if name in self._funcs:
            raise NameError(f"Línea {line}: función '{name}' redeclarada.")
        if len(param_names) > _MAX_PARAMS:
            raise TypeError(
                f"Línea {line}: la función '{name}' tiene {len(param_names)} "
                f"parámetros (máximo {_MAX_PARAMS}: $a0..$a{_MAX_PARAMS-1})."
            )
        if len(set(param_names)) != len(param_names):
            raise NameError(f"Línea {line}: parámetros duplicados en función '{name}'.")
        if self._current_func is not None:
            raise SyntaxError(
                f"Línea {line}: funciones anidadas no permitidas "
                f"('{name}' dentro de '{self._current_func}')."
            )

        info = _FuncInfo(name, param_names)
        self._funcs[name] = info
        self._current_func = name

        # Pre-registrar los params en la tabla de símbolos y emitir su .data.
        for p in param_names:
            param_label = f"vf_{name}_{p}"
            self._symbols[("func", name, p)] = param_label
            self._data.append(f"{param_label}: .word 0    # param de {name}")

        # Crear y activar el buffer de la función. Se quedará en _func_text
        # incluso después de pop (lo necesitamos para emitir al final).
        func_buf: list[str] = []
        self._func_text.append(func_buf)
        self._buffers.append(func_buf)

        # Header de la función + copiar args $aN → vf_F_<paramN>.
        self._emit("")
        params_str = ", ".join(param_names) if param_names else "∅"
        self._emit(f"# ===== func {name}({params_str}) — línea {line} =====")
        self._emit(f"{info.label}:")
        for i, p in enumerate(param_names):
            self._emit(f"    sw   $a{i}, vf_{name}_{p}    # copia del param {p}")

    def exitFuncDecl(self, ctx: RaraLangParser.FuncDeclContext):
        name = self._current_func
        # Fallback: si el cuerpo no terminó con un return explícito, igual
        # tenemos jr $ra para salir limpiamente (con $v0 indeterminado).
        self._emit("    # fallback: regresar si no hubo return explícito")
        self._emit("    jr   $ra")
        self._emit(f"# ===== fin func {name} =====")
        self._buffers.pop()
        self._current_func = None

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
        # Crítico: exit ANTES del código de funciones, para que main NO caiga
        # en ellas si se ejecutara linealmente sin saltos.
        lines.append("    # exit (main) — frontera con código de funciones")
        lines.append("    li   $v0, 10")
        lines.append("    syscall")
        # Funciones, en orden de declaración.
        for func_buf in self._func_text:
            lines.extend(func_buf)
        return "\n".join(lines) + "\n"
