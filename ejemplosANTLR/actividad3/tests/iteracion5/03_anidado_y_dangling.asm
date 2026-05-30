    .data
str_0: .asciiz "--- caso 1 ---"
v_x: .word 0
v_y: .word 0
str_1: .asciiz "--- caso 2 ---"
str_2: .asciiz "--- caso 3 ---"

    .text
    .globl main
main:
    # STRING "--- caso 1 ---" → $t0
    la   $t0, str_0
    # print string (consume $t0)
    move $a0, $t0
    li   $v0, 4
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # INT 7 → $t0
    li   $t0, 7
    # x <-- (consume $t0)
    sw   $t0, v_x
    # INT 3 → $t0
    li   $t0, 3
    # y <-- (consume $t0)
    sw   $t0, v_y
    # ===== if #1 (linea 21) =====
    # ----- cond -----
    # VAR x (v_x) → $t0
    lw   $t0, v_x
    # INT 0 → $t1
    li   $t1, 0
    # >  : $t0 := ($t0 > $t1) ? 1 : 0   (slt operandos invertidos)
    slt  $t0, $t1, $t0
    beq  $t0, $zero, if_else_1   # cond falsa → else
    # ----- then -----
    # ===== if #2 (linea 21) =====
    # ----- cond -----
    # VAR y (v_y) → $t1
    lw   $t1, v_y
    # INT 0 → $t2
    li   $t2, 0
    # >  : $t1 := ($t1 > $t2) ? 1 : 0   (slt operandos invertidos)
    slt  $t1, $t2, $t1
    beq  $t1, $zero, if_else_2   # cond falsa → else
    # ----- then -----
    # INT 1 → $t2
    li   $t2, 1
    # print int (consume $t2)
    move $a0, $t2
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    j    if_end_2                       # then ejecutado → fin
if_else_2:
    # ----- else -----
    # INT 2 → $t2
    li   $t2, 2
    # print int (consume $t2)
    move $a0, $t2
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
if_end_2:
    # ===== fin if #2 =====
    j    if_end_1                       # then ejecutado → fin
if_else_1:
    # ----- else -----
    # INT 3 → $t1
    li   $t1, 3
    # print int (consume $t1)
    move $a0, $t1
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
if_end_1:
    # ===== fin if #1 =====
    # STRING "--- caso 2 ---" → $t0
    la   $t0, str_1
    # print string (consume $t0)
    move $a0, $t0
    li   $v0, 4
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # INT 7 → $t0
    li   $t0, 7
    # x <-- (consume $t0)
    sw   $t0, v_x
    # INT 0 → $t0
    li   $t0, 0
    # y <-- (consume $t0)
    sw   $t0, v_y
    # ===== if #3 (linea 26) =====
    # ----- cond -----
    # VAR x (v_x) → $t0
    lw   $t0, v_x
    # INT 0 → $t1
    li   $t1, 0
    # >  : $t0 := ($t0 > $t1) ? 1 : 0   (slt operandos invertidos)
    slt  $t0, $t1, $t0
    beq  $t0, $zero, if_else_3   # cond falsa → else
    # ----- then -----
    # ===== if #4 (linea 26) =====
    # ----- cond -----
    # VAR y (v_y) → $t1
    lw   $t1, v_y
    # INT 0 → $t2
    li   $t2, 0
    # >  : $t1 := ($t1 > $t2) ? 1 : 0   (slt operandos invertidos)
    slt  $t1, $t2, $t1
    beq  $t1, $zero, if_else_4   # cond falsa → else
    # ----- then -----
    # INT 1 → $t2
    li   $t2, 1
    # print int (consume $t2)
    move $a0, $t2
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    j    if_end_4                       # then ejecutado → fin
if_else_4:
    # ----- else -----
    # INT 2 → $t2
    li   $t2, 2
    # print int (consume $t2)
    move $a0, $t2
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
if_end_4:
    # ===== fin if #4 =====
    j    if_end_3                       # then ejecutado → fin
if_else_3:
    # ----- else -----
    # INT 3 → $t1
    li   $t1, 3
    # print int (consume $t1)
    move $a0, $t1
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
if_end_3:
    # ===== fin if #3 =====
    # STRING "--- caso 3 ---" → $t0
    la   $t0, str_2
    # print string (consume $t0)
    move $a0, $t0
    li   $v0, 4
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # INT 5 → $t0
    li   $t0, 5
    # ± : $t0 := 0 - $t0
    sub  $t0, $zero, $t0
    # x <-- (consume $t0)
    sw   $t0, v_x
    # INT 3 → $t0
    li   $t0, 3
    # y <-- (consume $t0)
    sw   $t0, v_y
    # ===== if #5 (linea 31) =====
    # ----- cond -----
    # VAR x (v_x) → $t0
    lw   $t0, v_x
    # INT 0 → $t1
    li   $t1, 0
    # >  : $t0 := ($t0 > $t1) ? 1 : 0   (slt operandos invertidos)
    slt  $t0, $t1, $t0
    beq  $t0, $zero, if_else_5   # cond falsa → else
    # ----- then -----
    # ===== if #6 (linea 31) =====
    # ----- cond -----
    # VAR y (v_y) → $t1
    lw   $t1, v_y
    # INT 0 → $t2
    li   $t2, 0
    # >  : $t1 := ($t1 > $t2) ? 1 : 0   (slt operandos invertidos)
    slt  $t1, $t2, $t1
    beq  $t1, $zero, if_else_6   # cond falsa → else
    # ----- then -----
    # INT 1 → $t2
    li   $t2, 1
    # print int (consume $t2)
    move $a0, $t2
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    j    if_end_6                       # then ejecutado → fin
if_else_6:
    # ----- else -----
    # INT 2 → $t2
    li   $t2, 2
    # print int (consume $t2)
    move $a0, $t2
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
if_end_6:
    # ===== fin if #6 =====
    j    if_end_5                       # then ejecutado → fin
if_else_5:
    # ----- else -----
    # INT 3 → $t1
    li   $t1, 3
    # print int (consume $t1)
    move $a0, $t1
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
if_end_5:
    # ===== fin if #5 =====

    # exit
    li   $v0, 10
    syscall


# → tests/iteracion5/03_anidado_y_dangling.asm
