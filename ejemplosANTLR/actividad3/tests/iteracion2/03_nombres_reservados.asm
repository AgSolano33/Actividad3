    .data
v_add: .word 0
v_sub: .word 0
v_div: .word 0

    .text
    .globl main
main:
    # INT 7 → $t0
    li   $t0, 7
    # add <-- (consume $t0)
    sw   $t0, v_add
    # INT 42 → $t0
    li   $t0, 42
    # sub <-- (consume $t0)
    sw   $t0, v_sub
    # INT 100 → $t0
    li   $t0, 100
    # div <-- (consume $t0)
    sw   $t0, v_div
    # VAR add (v_add) → $t0
    lw   $t0, v_add
    # print int (consume $t0)
    move $a0, $t0
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # VAR sub (v_sub) → $t0
    lw   $t0, v_sub
    # print int (consume $t0)
    move $a0, $t0
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # VAR div (v_div) → $t0
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
