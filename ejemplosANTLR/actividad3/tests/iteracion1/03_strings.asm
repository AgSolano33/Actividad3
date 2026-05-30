    .data
str_0: .asciiz "hola mundo"
str_1: .asciiz "RaraLang funciona!"
str_2: .asciiz ""
str_3: .asciiz "123 no es un entero aqui"

    .text
    .globl main
main:
    # STRING "hola mundo" → $t0
    la   $t0, str_0
    # print string (consume $t0)
    move $a0, $t0
    li   $v0, 4
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # STRING "RaraLang funciona!" → $t0
    la   $t0, str_1
    # print string (consume $t0)
    move $a0, $t0
    li   $v0, 4
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # STRING "" → $t0
    la   $t0, str_2
    # print string (consume $t0)
    move $a0, $t0
    li   $v0, 4
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # STRING "123 no es un entero aqui" → $t0
    la   $t0, str_3
    # print string (consume $t0)
    move $a0, $t0
    li   $v0, 4
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall

    # exit
    li   $v0, 10
    syscall


# → tests/iteracion1/03_strings.asm
