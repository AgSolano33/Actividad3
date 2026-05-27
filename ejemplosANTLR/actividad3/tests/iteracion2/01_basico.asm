    .data
v_x: .word 0
v_y: .word 0

    .text
    .globl main
main:
    # expr INT 10
    li   $t0, 10
    # assign x <-- (consume $t0)
    sw   $t0, v_x
    # expr INT 3
    li   $t0, 3
    # assign y <-- (consume $t0)
    sw   $t0, v_y
    # expr VAR x  (label v_x)
    lw   $t0, v_x
    # print int (consume $t0)
    move $a0, $t0
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # expr VAR y  (label v_y)
    lw   $t0, v_y
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
