    .data
v_add: .word 0
v_sub: .word 0
v_div: .word 0

    .text
    .globl main
main:
    # expr INT 7
    li   $t0, 7
    # assign add <-- (consume $t0)
    sw   $t0, v_add
    # expr INT 42
    li   $t0, 42
    # assign sub <-- (consume $t0)
    sw   $t0, v_sub
    # expr INT 100
    li   $t0, 100
    # assign div <-- (consume $t0)
    sw   $t0, v_div
    # expr VAR add  (label v_add)
    lw   $t0, v_add
    # print int (consume $t0)
    move $a0, $t0
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # expr VAR sub  (label v_sub)
    lw   $t0, v_sub
    # print int (consume $t0)
    move $a0, $t0
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # expr VAR div  (label v_div)
    lw   $t0, v_div
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
