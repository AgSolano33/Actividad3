    .data
str_0: .asciiz "--- aritmética con bases ---"
str_1: .asciiz "fin"

    .text
    .globl main
main:
    # STRING "--- aritmética con bases ---" → $t0
    la   $t0, str_0
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
    # BASED [1:16] (= 1) → $t1
    li   $t1, 1
    # + : $t0 := $t0 + $t1
    add  $t0, $t0, $t1
    # print int (consume $t0)
    move $a0, $t0
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # BASED [1010:2] (= 10) → $t0
    li   $t0, 10
    # INT 2 → $t1
    li   $t1, 2
    # × : $t0 := $t0 × $t1
    mult $t0, $t1
    mflo $t0
    # print int (consume $t0)
    move $a0, $t0
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # BASED [10:8] (= 8) → $t0
    li   $t0, 8
    # INT 1 → $t1
    li   $t1, 1
    # + : $t0 := $t0 + $t1
    add  $t0, $t0, $t1
    # INT 3 → $t1
    li   $t1, 3
    # × : $t0 := $t0 × $t1
    mult $t0, $t1
    mflo $t0
    # print int (consume $t0)
    move $a0, $t0
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # STRING "fin" → $t0
    la   $t0, str_1
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


# → tests/iteracion3/04_mixto_bases_strings.asm
