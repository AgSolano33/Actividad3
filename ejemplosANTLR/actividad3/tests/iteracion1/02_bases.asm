    .data

    .text
    .globl main
main:
    # print 255  (= 255)
    li   $v0, 1
    li   $a0, 255
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # print [FF:16]  (= 255)
    li   $v0, 1
    li   $a0, 255
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # print [377:8]  (= 255)
    li   $v0, 1
    li   $a0, 255
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # print [11111111:2]  (= 255)
    li   $v0, 1
    li   $a0, 255
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # print [1010:2]  (= 10)
    li   $v0, 1
    li   $a0, 10
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # print [10:16]  (= 16)
    li   $v0, 1
    li   $a0, 16
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall

    # exit
    li   $v0, 10
    syscall
