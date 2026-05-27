    .data
str_0: .asciiz "hola mundo"
str_1: .asciiz "RaraLang funciona!"
str_2: .asciiz ""
str_3: .asciiz "123 no es un entero aqui"

    .text
    .globl main
main:
    # print "hola mundo"
    li   $v0, 4
    la   $a0, str_0
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # print "RaraLang funciona!"
    li   $v0, 4
    la   $a0, str_1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # print ""
    li   $v0, 4
    la   $a0, str_2
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # print "123 no es un entero aqui"
    li   $v0, 4
    la   $a0, str_3
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall

    # exit
    li   $v0, 10
    syscall
