    .data
v_x: .word 0
str_0: .asciiz "fin"

    .text
    .globl main
main:
    # INT 1 → $t0
    li   $t0, 1
    # x <-- (consume $t0)
    sw   $t0, v_x
    # ===== while #1 (linea 11) =====
loop_start_1:
    # ----- cond -----
    # VAR x (v_x) → $t0
    lw   $t0, v_x
    # INT 4 → $t1
    li   $t1, 4
    # <  : $t0 := ($t0 < $t1) ? 1 : 0
    slt  $t0, $t0, $t1
    beq  $t0, $zero, loop_end_1    # cond falsa → salir del ciclo
    # ----- body -----
    # VAR x (v_x) → $t1
    lw   $t1, v_x
    # print int (consume $t1)
    move $a0, $t1
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # VAR x (v_x) → $t1
    lw   $t1, v_x
    # INT 1 → $t2
    li   $t2, 1
    # + : $t1 := $t1 + $t2
    add  $t1, $t1, $t2
    # x <-- (consume $t1)
    sw   $t1, v_x
    j    loop_start_1                     # volver a evaluar cond
loop_end_1:
    # ===== fin while #1 =====
    # STRING "fin" → $t0
    la   $t0, str_0
    # print string (consume $t0)
    move $a0, $t0
    li   $v0, 4
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # ===== while #2 (linea 16) =====
loop_start_2:
    # ----- cond -----
    # VAR x (v_x) → $t0
    lw   $t0, v_x
    # INT 1000 → $t1
    li   $t1, 1000
    # >  : $t0 := ($t0 > $t1) ? 1 : 0   (slt operandos invertidos)
    slt  $t0, $t1, $t0
    beq  $t0, $zero, loop_end_2    # cond falsa → salir del ciclo
    # ----- body -----
    # INT 999 → $t1
    li   $t1, 999
    # print int (consume $t1)
    move $a0, $t1
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    j    loop_start_2                     # volver a evaluar cond
loop_end_2:
    # ===== fin while #2 =====

    # exit
    li   $v0, 10
    syscall


# → tests/iteracion6/01_while_basico.asm
