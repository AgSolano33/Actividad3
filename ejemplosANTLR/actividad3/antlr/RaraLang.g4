grammar RaraLang;

// RaraLang — Iteración 7: funciones (declaración, call, return).
//   - Funciones SOLO a nivel superior (no anidadas).
//   - El nivel superior intercala funcDecl y stmt; main solo recibe stmts.
//   - return solo es válido dentro de una función (chequeo semántico).

prog : topDecl* EOF ;

topDecl
    : funcDecl
    | stmt
    ;

funcDecl  : FUNC ID LPAREN paramList? RPAREN block ;
paramList : ID (COMMA ID)* ;

block : LBRACE stmt* RBRACE ;

stmt
    : PRINT expr                        #printStmt
    | ID ASSIGN expr                    #assignStmt
    | IF expr THEN stmt (ELSE stmt)?    #ifStmt
    | WHILE expr DO stmt                #whileStmt
    | RETURN expr                       #returnStmt
    | block                             #blockStmt
    ;

expr
    : NEG expr                              #neg
    | expr op=(MUL|DIV|MOD) expr            #mulDiv
    | expr op=(DOUBLEPLUS|AVG) expr         #customBin
    | expr op=(ADD|SUB) expr                #addSub
    | expr op=(EQ|NEQ|LT|GT) expr           #compare
    | LPAREN expr RPAREN                    #parens
    | ID LPAREN argList? RPAREN             #call   // antes de #var: lookahead `(`
    | INT                                   #int
    | BASED_NUMBER                          #based
    | STRING                                #string
    | ID                                    #var
    ;

argList : expr (COMMA expr)* ;

// ─── Keywords ─────────────────────────────────────────────────────────────────
// Todas las keywords antes que ID.

PRINT  : 'print' ;
IF     : 'if' ;
THEN   : 'then' ;
ELSE   : 'else' ;
WHILE  : 'while' ;
DO     : 'do' ;
FUNC   : 'func' ;
RETURN : 'return' ;

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
COMMA      : ',' ;

// ─── Literales ────────────────────────────────────────────────────────────────

INT          : [0-9]+ ;
BASED_NUMBER : '[' [0-9a-fA-F]+ ':' [0-9]+ ']' ;
STRING       : '"' (~["\r\n])* '"' ;

ID           : [a-zA-Z] [a-zA-Z0-9_]* ;

// ─── Infraestructura ──────────────────────────────────────────────────────────

NEWLINE : [\r\n]+ -> skip ;
COMMENT : '#' ~[\r\n]* -> skip ;
WS      : [ \t]+  -> skip ;
