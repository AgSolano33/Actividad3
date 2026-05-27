    .data
v_contador: .word 0
v_copia: .word 0

    .text
    .globl main
main:
    # expr INT 1
    li   $t0, 1
    # assign contador <-- (consume $t0)
    sw   $t0, v_contador
    # expr VAR contador  (label v_contador)
    lw   $t0, v_contador
    # print int (consume $t0)
    move $a0, $t0
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # expr INT 2
    li   $t0, 2
    # assign contador <-- (consume $t0)
    sw   $t0, v_contador
    # expr VAR contador  (label v_contador)
    lw   $t0, v_contador
    # print int (consume $t0)
    move $a0, $t0
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # expr VAR contador  (label v_contador)
    lw   $t0, v_contador
    # assign copia <-- (consume $t0)
    sw   $t0, v_copia
    # expr INT 99
    li   $t0, 99
    # assign contador <-- (consume $t0)
    sw   $t0, v_contador
    # expr VAR copia  (label v_copia)
    lw   $t0, v_copia
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
