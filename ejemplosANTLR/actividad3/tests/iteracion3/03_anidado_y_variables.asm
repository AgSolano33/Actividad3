    .data
v_a: .word 0
v_b: .word 0
v_total: .word 0

    .text
    .globl main
main:
    # INT 5 → $t0
    li   $t0, 5
    # a <-- (consume $t0)
    sw   $t0, v_a
    # INT 4 → $t0
    li   $t0, 4
    # b <-- (consume $t0)
    sw   $t0, v_b
    # VAR a (v_a) → $t0
    lw   $t0, v_a
    # INT 2 → $t1
    li   $t1, 2
    # + : $t0 := $t0 + $t1
    add  $t0, $t0, $t1
    # VAR b (v_b) → $t1
    lw   $t1, v_b
    # INT 1 → $t2
    li   $t2, 1
    # - : $t1 := $t1 - $t2
    sub  $t1, $t1, $t2
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
    # VAR a (v_a) → $t0
    lw   $t0, v_a
    # VAR b (v_b) → $t1
    lw   $t1, v_b
    # VAR a (v_a) → $t2
    lw   $t2, v_a
    # VAR b (v_b) → $t3
    lw   $t3, v_b
    # × : $t2 := $t2 × $t3
    mult $t2, $t3
    mflo $t2
    # + : $t1 := $t1 + $t2
    add  $t1, $t1, $t2
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
    # VAR a (v_a) → $t0
    lw   $t0, v_a
    # INT 2 → $t1
    li   $t1, 2
    # + : $t0 := $t0 + $t1
    add  $t0, $t0, $t1
    # VAR b (v_b) → $t1
    lw   $t1, v_b
    # INT 1 → $t2
    li   $t2, 1
    # - : $t1 := $t1 - $t2
    sub  $t1, $t1, $t2
    # × : $t0 := $t0 × $t1
    mult $t0, $t1
    mflo $t0
    # total <-- (consume $t0)
    sw   $t0, v_total
    # VAR total (v_total) → $t0
    lw   $t0, v_total
    # INT 1 → $t1
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

    # exit
    li   $v0, 10
    syscall


# → tests/iteracion3/03_anidado_y_variables.asm
