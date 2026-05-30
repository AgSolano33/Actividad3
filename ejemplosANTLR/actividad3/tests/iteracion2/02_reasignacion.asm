    .data
v_contador: .word 0
v_copia: .word 0

    .text
    .globl main
main:
    # INT 1 → $t0
    li   $t0, 1
    # contador <-- (consume $t0)  → v_contador
    sw   $t0, v_contador
    # VAR contador (v_contador) → $t0
    lw   $t0, v_contador
    # print int (consume $t0)
    move $a0, $t0
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # INT 2 → $t0
    li   $t0, 2
    # contador <-- (consume $t0)  → v_contador
    sw   $t0, v_contador
    # VAR contador (v_contador) → $t0
    lw   $t0, v_contador
    # print int (consume $t0)
    move $a0, $t0
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # VAR contador (v_contador) → $t0
    lw   $t0, v_contador
    # copia <-- (consume $t0)  → v_copia
    sw   $t0, v_copia
    # INT 99 → $t0
    li   $t0, 99
    # contador <-- (consume $t0)  → v_contador
    sw   $t0, v_contador
    # VAR copia (v_copia) → $t0
    lw   $t0, v_copia
    # print int (consume $t0)
    move $a0, $t0
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall

    # exit (main) — frontera con código de funciones
    li   $v0, 10
    syscall


# → tests/iteracion2/02_reasignacion.asm
