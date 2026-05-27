    .data

    .text
    .globl main
main:
    # print 5  (= 5)
    li   $v0, 1
    li   $a0, 5
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # print 0  (= 0)
    li   $v0, 1
    li   $a0, 0
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # print 1000  (= 1000)
    li   $v0, 1
    li   $a0, 1000
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # print 42  (= 42)
    li   $v0, 1
    li   $a0, 42
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall

    # exit
    li   $v0, 10
    syscall
