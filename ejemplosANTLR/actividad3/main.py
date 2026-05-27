"""
Uso:
    python main.py tests/07_if_then.rara        # un archivo
"""

import sys
import glob
from pathlib import Path
from antlr4 import CommonTokenStream, FileStream, ParseTreeWalker

from antlr.generated.RaraLangLexer import RaraLangLexer
from antlr.generated.RaraLangParser import RaraLangParser
from MIPSListener import MIPSListener


def compile_file(path: str) -> str:
    stream = FileStream(path, encoding="utf-8")
    lexer = RaraLangLexer(stream)
    tokens = CommonTokenStream(lexer)
    parser = RaraLangParser(tokens)
    tree = parser.prog()
    listener = MIPSListener()
    ParseTreeWalker().walk(listener, tree)
    return listener.output()


def run(path: str) -> None:
    mips = compile_file(path)
    out = Path(path).with_suffix(".asm")
    out.write_text(mips, encoding="utf-8")
    print(mips)
    print(f"\n# → {out}", flush=True)


if __name__ == "__main__":
    args = sys.argv[1:]

    source = args[0] if args else "tests/01_int_literal.rara"
    run(source)
