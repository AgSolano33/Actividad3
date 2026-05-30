    .data
v_x: .word 0

    .text
    .globl main
main:
    # INT 7 → $t0
    li   $t0, 7
    # x <-- (consume $t0)
    sw   $t0, v_x
    # ===== if #1 (linea 14) =====
    # ----- cond -----
    # VAR x (v_x) → $t0
    lw   $t0, v_x
    # INT 5 → $t1
    li   $t1, 5
    # >  : $t0 := ($t0 > $t1) ? 1 : 0   (slt operandos invertidos)
    slt  $t0, $t1, $t0
    beq  $t0, $zero, if_end_1    # cond falsa → fin
    # ----- then -----
    # INT 100 → $t1
    li   $t1, 100
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
    # ===== if #2 (linea 15) =====
    # ----- cond -----
    # VAR x (v_x) → $t0
    lw   $t0, v_x
    # INT 0 → $t1
    li   $t1, 0
    # <  : $t0 := ($t0 < $t1) ? 1 : 0
    slt  $t0, $t0, $t1
    beq  $t0, $zero, if_end_2    # cond falsa → fin
    # ----- then -----
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
if_end_2:
    # ===== fin if #2 =====
    # ===== if #3 (linea 16) =====
    # ----- cond -----
    # VAR x (v_x) → $t0
    lw   $t0, v_x
    # INT 7 → $t1
    li   $t1, 7
    # == : $t0 := ($t0 == $t1) ? 1 : 0
    seq  $t0, $t0, $t1
    beq  $t0, $zero, if_else_3   # cond falsa → else
    # ----- then -----
    # INT 200 → $t1
    li   $t1, 200
    # print int (consume $t1)
    move $a0, $t1
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    j    if_end_3                       # then ejecutado → fin
if_else_3:
    # ----- else -----
    # INT 300 → $t1
    li   $t1, 300
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
    # ===== if #4 (linea 17) =====
    # ----- cond -----
    # VAR x (v_x) → $t0
    lw   $t0, v_x
    # INT 0 → $t1
    li   $t1, 0
    # == : $t0 := ($t0 == $t1) ? 1 : 0
    seq  $t0, $t0, $t1
    beq  $t0, $zero, if_else_4   # cond falsa → else
    # ----- then -----
    # INT 400 → $t1
    li   $t1, 400
    # print int (consume $t1)
    move $a0, $t1
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    j    if_end_4                       # then ejecutado → fin
if_else_4:
    # ----- else -----
    # INT 500 → $t1
    li   $t1, 500
    # print int (consume $t1)
    move $a0, $t1
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
if_end_4:
    # ===== fin if #4 =====
    # INT 42 → $t0
    li   $t0, 42
    # x <-- (consume $t0)
    sw   $t0, v_x
    # ===== if #5 (linea 19) =====
    # ----- cond -----
    # VAR x (v_x) → $t0
    lw   $t0, v_x
    # INT 42 → $t1
    li   $t1, 42
    # == : $t0 := ($t0 == $t1) ? 1 : 0
    seq  $t0, $t0, $t1
    beq  $t0, $zero, if_end_5    # cond falsa → fin
    # ----- then -----
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
if_end_5:
    # ===== fin if #5 =====

    # exit
    li   $v0, 10
    syscall


# → tests/iteracion5/02_if_then_else.asm
