grammar RaraLang;

// RaraLang — Iteración 5: comparadores (==, !=, <, >) e if/then/else.
//
// Las comparaciones son expresiones que producen 1 (verdadero) o 0 (falso),
// por lo que pueden encadenarse con aritmética (`(x > 0) + 1`). El if usa
// la convención clásica: "ejecutar then si la condición es != 0".
//
// PRECEDENCIA (mayor → menor):
//   1. ±                       (unario)
//   2. × ÷ ⊞                   (multiplicativos)
//   3. ⊠ ≈                     (custom binarios)
//   4. + -                     (aditivos)
//   5. == != < >               (comparadores: MENOR precedencia entre binarios)
//   6. ( )  atom
//
// La razón de poner comparadores al final: queremos `x > 0 + 1` parsee como
// `x > (0 + 1)`, igual que en C/Python/etc. Para forzar la otra agrupación
// se usan paréntesis: `(x > 0) + 1`.

prog : stmt* EOF ;

stmt
    : PRINT expr                        #printStmt
    | ID ASSIGN expr                    #assignStmt
    | IF expr THEN stmt (ELSE stmt)?    #ifStmt
    ;

expr
    : NEG expr                              #neg
    | expr op=(MUL|DIV|MOD) expr            #mulDiv
    | expr op=(DOUBLEPLUS|AVG) expr         #customBin
    | expr op=(ADD|SUB) expr                #addSub
    | expr op=(EQ|NEQ|LT|GT) expr           #compare
    | LPAREN expr RPAREN                    #parens
    | INT                                   #int
    | BASED_NUMBER                          #based
    | STRING                                #string
    | ID                                    #var
    ;

// ─── Keywords ─────────────────────────────────────────────────────────────────
// IMPORTANTE: todas las keywords antes que ID, para que se tokenicen como
// keywords y no como identificadores.

PRINT : 'print' ;
IF    : 'if' ;
THEN  : 'then' ;
ELSE  : 'else' ;

// ─── Operadores ───────────────────────────────────────────────────────────────

ASSIGN     : '<--' ;
ADD        : '+' ;
SUB        : '-' ;
MUL        : '\u00D7' ;     // ×
DIV        : '\u00F7' ;     // ÷
MOD        : '\u229E' ;     // ⊞
DOUBLEPLUS : '\u22A0' ;     // ⊠
AVG        : '\u2248' ;     // ≈
NEG        : '\u00B1' ;     // ±
EQ         : '==' ;
NEQ        : '!=' ;
LT         : '<' ;
GT         : '>' ;
LPAREN     : '(' ;
RPAREN     : ')' ;

// ─── Literales ────────────────────────────────────────────────────────────────

INT          : [0-9]+ ;
BASED_NUMBER : '[' [0-9a-fA-F]+ ':' [0-9]+ ']' ;
STRING       : '"' (~["\r\n])* '"' ;

ID           : [a-zA-Z] [a-zA-Z0-9_]* ;

// ─── Infraestructura ──────────────────────────────────────────────────────────

NEWLINE : [\r\n]+ -> skip ;
COMMENT : '#' ~[\r\n]* -> skip ;
WS      : [ \t]+  -> skip ;
