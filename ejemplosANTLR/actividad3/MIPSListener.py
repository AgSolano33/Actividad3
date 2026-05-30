"""
MIPSListener — Compilador RaraLang → MIPS (QtSPIM)

Iteración 3: aritmética binaria (+, -, ×, ÷) con paréntesis, sobre la
base de iteración 1 (literales/print/strings/bases) e iteración 2
(variables enteras + asignación).

Arquitectura (sigue siendo estricta):
  - SOLO patrón Listener. No hay Visitor. No hay intérprete. No se
    evalúan expresiones del programa en Python (la única excepción es
    el folding compile-time de `BASED_NUMBER` — convertir el texto del
    literal a un entero — que NO es interpretar al programa).
  - Generación de código en post-order: el walker visita hijos antes
    que padres, así cuando una alternativa de operador binario corre su
    `exit*`, las dos sub-expresiones YA dejaron su resultado en sendos
    registros temporales.

Modelo de evaluación de expresiones:
  Cada alternativa de `expr` deja:
      ctx.reg  → nombre de un registro $tN que contiene su valor (o,
                 para STRING, la dirección del .asciiz)
      ctx.kind → "int" | "string"
  Los operadores binarios (mulDiv, addSub) toman ctx.expr(0).reg y
  ctx.expr(1).reg, emiten la operación MIPS, LIBERAN el registro
  derecho y reusan el izquierdo como destino. Esto da una "pila de
  registros" estática (la del compilador), no una pila en memoria de
  ejecución — más rápido y más legible en el .asm.

Precedencia:
  Se resuelve por la GRAMÁTICA, no por el listener. ANTLR4 con
  recursión izquierda en una sola regla usa el orden textual de las
  alternativas para dar prioridad: `mulDiv` está antes que `addSub`,
  por lo tanto `×` y `÷` ligan más fuerte que `+` y `-`. El árbol
  sintáctico que llega al listener YA tiene `2 + 3 × 4` agrupado como
  `2 + (3 × 4)`. El listener no necesita lógica de precedencia.

Decisiones documentadas (para auditar):
  1. División por cero NO se detecta en compile-time. SPIM la marca
     en runtime con un trap. Defendible: detectarlo solo cubriría el
     literal `÷ 0`; el caso `x ÷ y` con y=0 requiere análisis de flujo
     que no toca a iter 3.
  2. El RESIDUO de `÷` se pierde — usamos `mflo` (cociente) y nunca
     leemos HI. RaraLang no tiene operador de módulo en iter 3.
  3. OVERFLOW en `×` es silencioso — `mflo` toma solo los 32 bits
     bajos. La parte alta (`mfhi`) se ignora.
  4. Profundidad máxima de expresión: 10 registros temporales
     ($t0..$t9). Una expresión derecha-asociativa muy anidada agotaría
     el pool. Se reporta como error de compilación claro.
  5. La aritmética sobre strings es ERROR de tipo en compile-time
     (no concatenación). Misma postura que iter 2.
"""

from antlr.generated.RaraLangListener import RaraLangListener
from antlr.generated.RaraLangParser import RaraLangParser


class _RegisterPool:
    """Pool LIFO de registros temporales $t0..$t9.

    `allocate()` saca el de menor número libre; `release()` lo devuelve
    al frente, por lo que la siguiente `allocate()` lo reusa de inmediato.
    Esto es la "pila de registros" mencionada en la guía de iter 3.
    """

    def __init__(self) -> None:
        self._free: list[str] = [f"$t{i}" for i in range(10)]

    def allocate(self) -> str:
        if not self._free:
            raise RuntimeError(
                "Sin registros temporales: la expresión es demasiado "
                "profunda (>10 valores vivos simultáneamente). "
                "Considera asignar subexpresiones a variables."
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

    # ─── Helpers de emisión y tabla de símbolos ────────────────────────────

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
                f"Línea {line}: operación aritmética '{where}' requiere "
                f"enteros, no {ctx.kind!r}."
            )

    # ─── expr: hojas — cada una deja su resultado en un registro nuevo ─────

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

    # ─── expr: paréntesis — solo propagación ───────────────────────────────

    def exitParens(self, ctx: RaraLangParser.ParensContext):
        inner = ctx.expr()
        ctx.reg = inner.reg
        ctx.kind = inner.kind

    # ─── expr: operadores binarios ─────────────────────────────────────────

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

    def exitMulDiv(self, ctx: RaraLangParser.MulDivContext):
        left, right = ctx.expr(0), ctx.expr(1)
        op = ctx.op.text
        self._require_int(left, op)
        self._require_int(right, op)
        rl, rr = left.reg, right.reg
        if op == "\u00D7":   # ×
            self._emit(f"    # × : {rl} := {rl} × {rr}  (mult, residuo n/a)")
            self._emit(f"    mult {rl}, {rr}")
            self._emit(f"    mflo {rl}")
        else:                 # ÷
            self._emit(f"    # ÷ : {rl} := {rl} ÷ {rr}  (mflo = cociente; HI = residuo, descartado)")
            self._emit(f"    div  {rl}, {rr}")
            self._emit(f"    mflo {rl}")
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
