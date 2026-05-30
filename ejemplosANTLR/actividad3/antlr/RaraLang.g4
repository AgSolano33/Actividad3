grammar RaraLang;

// RaraLang — Iteración 3: aritmética binaria (+ - × ÷) con paréntesis.
//
// Estrategia de precedencia en ANTLR4: usamos UNA sola regla `expr` con
// recursión izquierda. ANTLR4 reescribe esto a un parser correcto y la
// PRECEDENCIA se establece por el ORDEN de las alternativas — la que
// aparece antes tiene mayor prioridad. Por eso `mulDiv` va antes que
// `addSub`. Asociatividad por defecto: izquierda (correcto para -, ÷).

prog : stmt* EOF ;

stmt
    : PRINT expr        #printStmt
    | ID ASSIGN expr    #assignStmt
    ;

expr
    : expr op=(MUL|DIV) expr   #mulDiv
    | expr op=(ADD|SUB) expr   #addSub
    | LPAREN expr RPAREN       #parens
    | INT                      #int
    | BASED_NUMBER             #based
    | STRING                   #string
    | ID                       #var
    ;

// ─── Keywords ─────────────────────────────────────────────────────────────────

PRINT  : 'print' ;

// ─── Operadores ───────────────────────────────────────────────────────────────

ASSIGN : '<--' ;
ADD    : '+' ;
SUB    : '-' ;
MUL    : '\u00D7' ;     // ×  (U+00D7 MULTIPLICATION SIGN)
DIV    : '\u00F7' ;     // ÷  (U+00F7 DIVISION SIGN)
LPAREN : '(' ;
RPAREN : ')' ;

// ─── Literales ────────────────────────────────────────────────────────────────

INT          : [0-9]+ ;
BASED_NUMBER : '[' [0-9a-fA-F]+ ':' [0-9]+ ']' ;
STRING       : '"' (~["\r\n])* '"' ;

// ID DEBE ir después de PRINT (y de cualquier keyword futura) para que
// 'print' se tokenice como PRINT y no como ID.
ID           : [a-zA-Z] [a-zA-Z0-9_]* ;

// ─── Infraestructura ──────────────────────────────────────────────────────────

NEWLINE : [\r\n]+ -> skip ;
COMMENT : '#' ~[\r\n]* -> skip ;
WS      : [ \t]+  -> skip ;
