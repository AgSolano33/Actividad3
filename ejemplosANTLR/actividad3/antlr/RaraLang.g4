grammar RaraLang;

// RaraLang — Iteración 6: bloques { ... } y while.
// El block agrupa sentencias sin generar código propio.
// El while comparte la técnica de buffers del if, con saltos hacia atrás.

prog : stmt* EOF ;

stmt
    : PRINT expr                        #printStmt
    | ID ASSIGN expr                    #assignStmt
    | IF expr THEN stmt (ELSE stmt)?    #ifStmt
    | WHILE expr DO stmt                #whileStmt
    | LBRACE stmt* RBRACE               #blockStmt
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
// Importante: TODAS las keywords antes que ID.

PRINT : 'print' ;
IF    : 'if' ;
THEN  : 'then' ;
ELSE  : 'else' ;
WHILE : 'while' ;
DO    : 'do' ;

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
LBRACE     : '{' ;
RBRACE     : '}' ;

// ─── Literales ────────────────────────────────────────────────────────────────

INT          : [0-9]+ ;
BASED_NUMBER : '[' [0-9a-fA-F]+ ':' [0-9]+ ']' ;
STRING       : '"' (~["\r\n])* '"' ;

ID           : [a-zA-Z] [a-zA-Z0-9_]* ;

// ─── Infraestructura ──────────────────────────────────────────────────────────

NEWLINE : [\r\n]+ -> skip ;
COMMENT : '#' ~[\r\n]* -> skip ;
WS      : [ \t]+  -> skip ;
