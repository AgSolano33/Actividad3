    .data
v_x: .word 0

    .text
    .globl main
main:
    # INT 5 → $t0
    li   $t0, 5
    # x <-- (consume $t0)
    sw   $t0, v_x
    # VAR x (v_x) → $t0
    lw   $t0, v_x
    # INT 0 → $t1
    li   $t1, 0
    # >  : $t0 := ($t0 > $t1) ? 1 : 0   (= slt con operandos invertidos)
    slt  $t0, $t1, $t0
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
    # INT 0 → $t1
    li   $t1, 0
    # INT 1 → $t2
    li   $t2, 1
    # + : $t1 := $t1 + $t2
    add  $t1, $t1, $t2
    # >  : $t0 := ($t0 > $t1) ? 1 : 0   (= slt con operandos invertidos)
    slt  $t0, $t1, $t0
    # print int (consume $t0)
    move $a0, $t0
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # INT 0 → $t0
    li   $t0, 0
    # x <-- (consume $t0)
    sw   $t0, v_x
    # VAR x (v_x) → $t0
    lw   $t0, v_x
    # INT 0 → $t1
    li   $t1, 0
    # >  : $t0 := ($t0 > $t1) ? 1 : 0   (= slt con operandos invertidos)
    slt  $t0, $t1, $t0
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
    # INT 0 → $t1
    li   $t1, 0
    # INT 1 → $t2
    li   $t2, 1
    # + : $t1 := $t1 + $t2
    add  $t1, $t1, $t2
    # >  : $t0 := ($t0 > $t1) ? 1 : 0   (= slt con operandos invertidos)
    slt  $t0, $t1, $t0
    # print int (consume $t0)
    move $a0, $t0
    li   $v0, 1
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
    # VAR x (v_x) → $t0
    lw   $t0, v_x
    # INT 0 → $t1
    li   $t1, 0
    # >  : $t0 := ($t0 > $t1) ? 1 : 0   (= slt con operandos invertidos)
    slt  $t0, $t1, $t0
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
    # INT 0 → $t1
    li   $t1, 0
    # INT 1 → $t2
    li   $t2, 1
    # + : $t1 := $t1 + $t2
    add  $t1, $t1, $t2
    # >  : $t0 := ($t0 > $t1) ? 1 : 0   (= slt con operandos invertidos)
    slt  $t0, $t1, $t0
    # print int (consume $t0)
    move $a0, $t0
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall

    # exit
    li   $v0, 10
    syscall
