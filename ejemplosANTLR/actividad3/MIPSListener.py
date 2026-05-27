"""
MIPSListener — Compilador RaraLang → MIPS (QtSPIM)

Iteración 2: literales enteros, números en bases no convencionales,
strings, sentencia `print`, variables enteras y asignación con `<--`.

Arquitectura (estricta):
  - SOLO patrón Listener. No hay Visitor, no hay return values en métodos,
    no hay intérprete. El walker recorre el árbol y dispara `exitX` en
    post-order; las sentencias emiten MIPS al cerrar.
  - Convención de evaluación de expresiones:
        Cada alternativa de `expr` deja su valor en $t0.
        - INT, BASED, VAR   → $t0 contiene un int
        - STRING            → $t0 contiene la dirección de un .asciiz
    El kind (int|string) se anota en el ctx para que la sentencia padre
    (`print` o `<--`) decida qué hacer.
  - Tabla de símbolos: dict { nombre_rara → etiqueta_MIPS }.
    La etiqueta se prefija con `v_` para *evitar colisiones con nombres
    reservados del ensamblador* (`add`, `sub`, `div`, etc.). Eso resuelve
    de raíz la "trampa" del enunciado.
  - Las variables se reservan en `.data` con `.word 0` la PRIMERA vez que
    el compilador las ve (lectura o escritura). No hay declaración explícita.

Decisiones documentadas explícitamente para que puedas auditarlas:
  1. La asignación de un STRING a una variable se rechaza en tiempo de
     compilación con un error de tipo claro — las variables de iter 2
     son enteras por contrato.
  2. Leer una variable nunca asignada NO es un error: vale 0 porque
     `.word 0` la inicializa. (Trade-off discutible — ver §auditoría).
  3. Reasignar una variable solo emite un `sw`; no realloca memoria.
"""

from antlr.generated.RaraLangListener import RaraLangListener
from antlr.generated.RaraLangParser import RaraLangParser


class MIPSListener(RaraLangListener):
    def __init__(self) -> None:
        super().__init__()
        self._data: list[str] = []
        self._text: list[str] = []
        self._str_counter: int = 0
        self._symbols: dict[str, str] = {}

    # ─── Helpers de emisión ────────────────────────────────────────────────

    def _emit(self, line: str) -> None:
        self._text.append(line)

    def _new_str_label(self) -> str:
        label = f"str_{self._str_counter}"
        self._str_counter += 1
        return label

    def _intern_var(self, name: str) -> str:
        """Devuelve la etiqueta MIPS para `name`, reservando .word 0 si
        es la primera vez que se ve."""
        if name not in self._symbols:
            label = f"v_{name}"  # prefijo anti-colisión con instrucciones
            self._symbols[name] = label
            self._data.append(f"{label}: .word 0")
        return self._symbols[name]

    def _emit_newline(self) -> None:
        self._emit("    # newline (LF)")
        self._emit("    li   $v0, 11")
        self._emit("    li   $a0, 10")
        self._emit("    syscall")

    # ─── expr → deja el resultado en $t0 + anota ctx.kind ──────────────────

    def exitInt(self, ctx: RaraLangParser.IntContext):
        text = ctx.INT().getText()
        value = int(text)
        self._emit(f"    # expr INT {text}")
        self._emit(f"    li   $t0, {value}")
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
        self._emit(f"    # expr BASED {token}  (= {value})")
        self._emit(f"    li   $t0, {value}")
        ctx.kind = "int"

    def exitString(self, ctx: RaraLangParser.StringContext):
        raw = ctx.STRING().getText()
        text = raw[1:-1]
        label = self._new_str_label()
        self._data.append(f'{label}: .asciiz "{text}"')
        self._emit(f"    # expr STRING {raw}")
        self._emit(f"    la   $t0, {label}")
        ctx.kind = "string"

    def exitVar(self, ctx: RaraLangParser.VarContext):
        name = ctx.ID().getText()
        label = self._intern_var(name)
        self._emit(f"    # expr VAR {name}  (label {label})")
        self._emit(f"    lw   $t0, {label}")
        ctx.kind = "int"

    # ─── Sentencias ────────────────────────────────────────────────────────

    def exitPrintStmt(self, ctx: RaraLangParser.PrintStmtContext):
        kind = ctx.expr().kind
        if kind == "int":
            self._emit("    # print int (consume $t0)")
            self._emit("    move $a0, $t0")
            self._emit("    li   $v0, 1")
            self._emit("    syscall")
        elif kind == "string":
            self._emit("    # print string (consume $t0)")
            self._emit("    move $a0, $t0")
            self._emit("    li   $v0, 4")
            self._emit("    syscall")
        else:
            raise ValueError(f"Tipo desconocido en print: {kind!r}")
        self._emit_newline()

    def exitAssignStmt(self, ctx: RaraLangParser.AssignStmtContext):
        name = ctx.ID().getText()
        kind = ctx.expr().kind
        if kind != "int":
            line = ctx.start.line
            raise TypeError(
                f"Línea {line}: no se puede asignar un valor de tipo {kind!r} "
                f"a la variable '{name}'. Las variables de iter 2 son enteras."
            )
        label = self._intern_var(name)
        self._emit(f"    # assign {name} <-- (consume $t0)")
        self._emit(f"    sw   $t0, {label}")

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
