    .data
str_0: .asciiz "--- Tabla de equivalencias ---"
str_1: .asciiz "Decimal:"
str_2: .asciiz "Hex:"
str_3: .asciiz "Bin:"
str_4: .asciiz "FIN"

    .text
    .globl main
main:
    # print "--- Tabla de equivalencias ---"
    li   $v0, 4
    la   $a0, str_0
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # print "Decimal:"
    li   $v0, 4
    la   $a0, str_1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # print 255  (= 255)
    li   $v0, 1
    li   $a0, 255
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # print "Hex:"
    li   $v0, 4
    la   $a0, str_2
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
    # print "Bin:"
    li   $v0, 4
    la   $a0, str_3
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
    # print "FIN"
    li   $v0, 4
    la   $a0, str_4
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall

    # exit
    li   $v0, 10
    syscall
