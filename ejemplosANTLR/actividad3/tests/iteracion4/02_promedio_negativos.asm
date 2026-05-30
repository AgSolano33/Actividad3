    .data

    .text
    .globl main
main:
    # INT 3 → $t0
    li   $t0, 3
    # ± : $t0 := 0 - $t0
    sub  $t0, $zero, $t0
    # INT 1 → $t1
    li   $t1, 1
    # ± : $t1 := 0 - $t1
    sub  $t1, $zero, $t1
    # ≈ : $t0 := piso(($t0 + $t1) / 2)   (add + sra)
    add  $t0, $t0, $t1
    sra  $t0, $t0, 1
    # print int (consume $t0)
    move $a0, $t0
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # INT 5 → $t0
    li   $t0, 5
    # ± : $t0 := 0 - $t0
    sub  $t0, $zero, $t0
    # INT 1 → $t1
    li   $t1, 1
    # ≈ : $t0 := piso(($t0 + $t1) / 2)   (add + sra)
    add  $t0, $t0, $t1
    sra  $t0, $t0, 1
    # print int (consume $t0)
    move $a0, $t0
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # INT 5 → $t0
    li   $t0, 5
    # INT 3 → $t1
    li   $t1, 3
    # ± : $t1 := 0 - $t1
    sub  $t1, $zero, $t1
    # ≈ : $t0 := piso(($t0 + $t1) / 2)   (add + sra)
    add  $t0, $t0, $t1
    sra  $t0, $t0, 1
    # print int (consume $t0)
    move $a0, $t0
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # INT 7 → $t0
    li   $t0, 7
    # ± : $t0 := 0 - $t0
    sub  $t0, $zero, $t0
    # INT 2 → $t1
    li   $t1, 2
    # ± : $t1 := 0 - $t1
    sub  $t1, $zero, $t1
    # ≈ : $t0 := piso(($t0 + $t1) / 2)   (add + sra)
    add  $t0, $t0, $t1
    sra  $t0, $t0, 1
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


# → tests/iteracion4/02_promedio_negativos.asm
