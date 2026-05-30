    .data

    .text
    .globl main
main:
    # INT 5 → $t0
    li   $t0, 5
    # INT 5 → $t1
    li   $t1, 5
    # == : $t0 := ($t0 == $t1) ? 1 : 0
    seq  $t0, $t0, $t1
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
    # INT 3 → $t1
    li   $t1, 3
    # == : $t0 := ($t0 == $t1) ? 1 : 0
    seq  $t0, $t0, $t1
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
    # INT 3 → $t1
    li   $t1, 3
    # != : $t0 := ($t0 != $t1) ? 1 : 0
    sne  $t0, $t0, $t1
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
    # INT 5 → $t1
    li   $t1, 5
    # != : $t0 := ($t0 != $t1) ? 1 : 0
    sne  $t0, $t0, $t1
    # print int (consume $t0)
    move $a0, $t0
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # INT 3 → $t0
    li   $t0, 3
    # INT 5 → $t1
    li   $t1, 5
    # <  : $t0 := ($t0 < $t1) ? 1 : 0
    slt  $t0, $t0, $t1
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
    # INT 3 → $t1
    li   $t1, 3
    # <  : $t0 := ($t0 < $t1) ? 1 : 0
    slt  $t0, $t0, $t1
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
    # INT 3 → $t1
    li   $t1, 3
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
    # INT 3 → $t0
    li   $t0, 3
    # INT 5 → $t1
    li   $t1, 5
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
