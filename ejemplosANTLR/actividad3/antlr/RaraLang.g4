grammar RaraLang;

// RaraLang — Iteración 2: + variables (declaración implícita en la
// primera asignación o lectura) y la sentencia de asignación con `<--`.

prog : stmt* EOF ;

stmt
    : PRINT expr        #printStmt
    | ID ASSIGN expr    #assignStmt
    ;

expr
    : INT           #int
    | BASED_NUMBER  #based
    | STRING        #string
    | ID            #var
    ;

// ─── Keywords ─────────────────────────────────────────────────────────────────

PRINT : 'print' ;

// ─── Operadores ───────────────────────────────────────────────────────────────

ASSIGN : '<--' ;

// ─── Literales ────────────────────────────────────────────────────────────────

INT          : [0-9]+ ;
BASED_NUMBER : '[' [0-9a-fA-F]+ ':' [0-9]+ ']' ;
STRING       : '"' (~["\r\n])* '"' ;

// ID DEBE ir después de PRINT (y de cualquier otra keyword futura) para que
// 'print' se tokenice como PRINT y no como ID.
ID           : [a-zA-Z] [a-zA-Z0-9_]* ;

// ─── Infraestructura ──────────────────────────────────────────────────────────

NEWLINE : [\r\n]+ -> skip ;
COMMENT : '#' ~[\r\n]* -> skip ;
WS      : [ \t]+  -> skip ;
