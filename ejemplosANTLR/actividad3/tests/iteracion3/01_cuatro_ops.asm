    .data
v_x: .word 0
v_y: .word 0

    .text
    .globl main
main:
    # INT 10 → $t0
    li   $t0, 10
    # x <-- (consume $t0)
    sw   $t0, v_x
    # INT 3 → $t0
    li   $t0, 3
    # y <-- (consume $t0)
    sw   $t0, v_y
    # VAR x (v_x) → $t0
    lw   $t0, v_x
    # VAR y (v_y) → $t1
    lw   $t1, v_y
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
    # VAR x (v_x) → $t0
    lw   $t0, v_x
    # VAR y (v_y) → $t1
    lw   $t1, v_y
    # - : $t0 := $t0 - $t1
    sub  $t0, $t0, $t1
    # print int (consume $t0)
    move $a0, $t0
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # VAR x (v_x) → $t0
    lw   $t0, v_x
    # VAR y (v_y) → $t1
    lw   $t1, v_y
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
    # VAR x (v_x) → $t0
    lw   $t0, v_x
    # VAR y (v_y) → $t1
    lw   $t1, v_y
    # ÷ : $t0 := $t0 ÷ $t1   (mflo = cociente)
    div  $t0, $t1
    mflo $t0
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


# → tests/iteracion3/01_cuatro_ops.asm
