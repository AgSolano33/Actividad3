    .data
str_0: .asciiz "--- Tabla de equivalencias ---"
str_1: .asciiz "Decimal:"
str_2: .asciiz "Hex:"
str_3: .asciiz "Bin:"
str_4: .asciiz "FIN"

    .text
    .globl main
main:
    # STRING "--- Tabla de equivalencias ---" → $t0
    la   $t0, str_0
    # print string (consume $t0)
    move $a0, $t0
    li   $v0, 4
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # STRING "Decimal:" → $t0
    la   $t0, str_1
    # print string (consume $t0)
    move $a0, $t0
    li   $v0, 4
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # INT 255 → $t0
    li   $t0, 255
    # print int (consume $t0)
    move $a0, $t0
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # STRING "Hex:" → $t0
    la   $t0, str_2
    # print string (consume $t0)
    move $a0, $t0
    li   $v0, 4
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # BASED [FF:16] (= 255) → $t0
    li   $t0, 255
    # print int (consume $t0)
    move $a0, $t0
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # STRING "Bin:" → $t0
    la   $t0, str_3
    # print string (consume $t0)
    move $a0, $t0
    li   $v0, 4
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # BASED [11111111:2] (= 255) → $t0
    li   $t0, 255
    # print int (consume $t0)
    move $a0, $t0
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # STRING "FIN" → $t0
    la   $t0, str_4
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


# → tests/iteracion1/04_mixto.asm
