    .data
v_x: .word 0
str_0: .asciiz "--- if con then vacío ---"
str_1: .asciiz "else ejecuta"

    .text
    .globl main
main:
    # INT 10 → $t0
    li   $t0, 10
    # x <-- (consume $t0)  → v_x
    sw   $t0, v_x
    # VAR x (v_x) → $t0
    lw   $t0, v_x
    # print int (consume $t0)
    move $a0, $t0
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # VAR x (v_x) → $t0
    lw   $t0, v_x
    # INT 1 → $t1
    li   $t1, 1
    # + : $t0 := $t0 + $t1
    add  $t0, $t0, $t1
    # print int (consume $t0)
    move $a0, $t0
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # VAR x (v_x) → $t0
    lw   $t0, v_x
    # INT 2 → $t1
    li   $t1, 2
    # × : $t0 := $t0 × $t1
    mult $t0, $t1
    mflo $t0
    # print int (consume $t0)
    move $a0, $t0
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # ===== while #1 (linea 22) =====
loop_start_1:
    # ----- cond -----
    # VAR x (v_x) → $t0
    lw   $t0, v_x
    # INT 1000 → $t1
    li   $t1, 1000
    # >  : $t0 := ($t0 > $t1) ? 1 : 0   (slt operandos invertidos)
    slt  $t0, $t1, $t0
    beq  $t0, $zero, loop_end_1    # cond falsa → salir
    # ----- body -----
    j    loop_start_1                     # volver a evaluar cond
loop_end_1:
    # ===== fin while #1 =====
    # STRING "--- if con then vacío ---" → $t0
    la   $t0, str_0
    # print string (consume $t0)
    move $a0, $t0
    li   $v0, 4
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # ===== if #1 (linea 24) =====
    # ----- cond -----
    # VAR x (v_x) → $t0
    lw   $t0, v_x
    # INT 0 → $t1
    li   $t1, 0
    # == : $t0 := ($t0 == $t1) ? 1 : 0
    seq  $t0, $t0, $t1
    beq  $t0, $zero, if_else_1   # cond falsa → else
    # ----- then -----
    j    if_end_1                       # then ejecutado → fin
if_else_1:
    # ----- else -----
    # STRING "else ejecuta" → $t1
    la   $t1, str_1
    # print string (consume $t1)
    move $a0, $t1
    li   $v0, 4
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
if_end_1:
    # ===== fin if #1 =====

    # exit (main) — frontera con código de funciones
    li   $v0, 10
    syscall


# → tests/iteracion6/02_bloques_y_vacios.asm
