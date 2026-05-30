grammar RaraLang;

// RaraLang — Iteración 4: operadores enteros Unicode
//   ⊞ módulo          (a ⊞ b = residuo de a÷b)
//   ⊠ doble más       (a ⊠ b = 2a + b)
//   ≈ promedio entero (a ≈ b = floor((a+b)/2))
//   ± negación unaria (±x = -x)
//
// PRECEDENCIA (decidida por el ORDEN de las alternativas; mayor → primero):
//   1. ±  (unario, máxima precedencia)
//   2. × ÷ ⊞   (multiplicativos: comparten ALU mult/div)
//   3. ⊠ ≈     (operadores custom, nivel intermedio entre × y +)
//   4. + -     (aditivos, mínima precedencia entre binarios)
//   5. ( )     atom / agrupación
//
// Asociatividad: izquierda (default ANTLR4) — correcta para todos.

prog : stmt* EOF ;

stmt
    : PRINT expr        #printStmt
    | ID ASSIGN expr    #assignStmt
    ;

expr
    : NEG expr                              #neg
    | expr op=(MUL|DIV|MOD) expr            #mulDiv
    | expr op=(DOUBLEPLUS|AVG) expr         #customBin
    | expr op=(ADD|SUB) expr                #addSub
    | LPAREN expr RPAREN                    #parens
    | INT                                   #int
    | BASED_NUMBER                          #based
    | STRING                                #string
    | ID                                    #var
    ;

// ─── Keywords ─────────────────────────────────────────────────────────────────

PRINT  : 'print' ;

// ─── Operadores ───────────────────────────────────────────────────────────────

ASSIGN     : '<--' ;
ADD        : '+' ;
SUB        : '-' ;
MUL        : '\u00D7' ;     // ×  (U+00D7 MULTIPLICATION SIGN)
DIV        : '\u00F7' ;     // ÷  (U+00F7 DIVISION SIGN)
MOD        : '\u229E' ;     // ⊞  (U+229E SQUARED PLUS)        → módulo
DOUBLEPLUS : '\u22A0' ;     // ⊠  (U+22A0 SQUARED TIMES)       → 2a+b
AVG        : '\u2248' ;     // ≈  (U+2248 ALMOST EQUAL TO)     → floor((a+b)/2)
NEG        : '\u00B1' ;     // ±  (U+00B1 PLUS-MINUS SIGN)     → negación
LPAREN     : '(' ;
RPAREN     : ')' ;

// ─── Literales ────────────────────────────────────────────────────────────────

INT          : [0-9]+ ;
BASED_NUMBER : '[' [0-9a-fA-F]+ ':' [0-9]+ ']' ;
STRING       : '"' (~["\r\n])* '"' ;

// ID DEBE ir después de PRINT para evitar que se tokenice como identificador.
ID           : [a-zA-Z] [a-zA-Z0-9_]* ;

// ─── Infraestructura ──────────────────────────────────────────────────────────

NEWLINE : [\r\n]+ -> skip ;
COMMENT : '#' ~[\r\n]* -> skip ;
WS      : [ \t]+  -> skip ;
