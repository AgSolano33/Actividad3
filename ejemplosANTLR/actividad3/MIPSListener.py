"""
MIPSListener — Compilador RaraLang → MIPS (QtSPIM)

Iteración 1: literales enteros, números en bases no convencionales,
strings y la sentencia `print`.

Decisiones de diseño:
  - SOLO se usa el patrón Listener de ANTLR (ParseTreeWalker recorre el árbol
    en DFS y dispara `enterX` / `exitX`). No hay Visitor.
  - El compilador NO evalúa expresiones en tiempo de ejecución. La única
    "evaluación" es la conversión textual de un literal base→decimal en
    tiempo de compilación (constant folding sobre un literal, no sobre
    una expresión).
  - Se acumulan dos buffers:
        self._data → líneas del segmento `.data`
        self._text → instrucciones del cuerpo de `main`
    y `output()` los concatena con el preámbulo/postámbulo MIPS.
  - El newline al final de cada `print` se emite con syscall 11
    (print_character) cargando 10 (LF) en $a0. Es lo que sugiere la guía
    de la iteración y evita reservar un literal en `.data`.
"""

from antlr.generated.RaraLangListener import RaraLangListener
from antlr.generated.RaraLangParser import RaraLangParser


class MIPSListener(RaraLangListener):
    def __init__(self) -> None:
        super().__init__()
        self._data: list[str] = []
        self._text: list[str] = []
        self._str_counter: int = 0

    # ─── Helpers de emisión ────────────────────────────────────────────────

    def _emit(self, line: str) -> None:
        self._text.append(line)

    def _new_str_label(self) -> str:
        label = f"str_{self._str_counter}"
        self._str_counter += 1
        return label

    def _emit_print_int(self, value: int, source: str) -> None:
        self._emit(f"    # print {source}  (= {value})")
        self._emit("    li   $v0, 1")
        self._emit(f"    li   $a0, {value}")
        self._emit("    syscall")
        self._emit_newline()

    def _emit_print_string(self, label: str, raw: str) -> None:
        self._emit(f"    # print {raw}")
        self._emit("    li   $v0, 4")
        self._emit(f"    la   $a0, {label}")
        self._emit("    syscall")
        self._emit_newline()

    def _emit_newline(self) -> None:
        self._emit("    # newline (LF)")
        self._emit("    li   $v0, 11")
        self._emit("    li   $a0, 10")
        self._emit("    syscall")

    # ─── Listener callbacks ────────────────────────────────────────────────

    def exitInt(self, ctx: RaraLangParser.IntContext):
        text = ctx.INT().getText()
        value = int(text)
        self._emit_print_int(value, text)

    def exitBased(self, ctx: RaraLangParser.BasedContext):
        token = ctx.BASED_NUMBER().getText()       # ej. '[FF:16]'
        body = token[1:-1]                          # 'FF:16'
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
        self._emit_print_int(value, token)

    def exitString(self, ctx: RaraLangParser.StringContext):
        raw = ctx.STRING().getText()   # incluye las comillas
        text = raw[1:-1]
        label = self._new_str_label()
        self._data.append(f'{label}: .asciiz "{text}"')
        self._emit_print_string(label, raw)

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
