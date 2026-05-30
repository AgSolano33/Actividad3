    .data

    .text
    .globl main
main:
    # INT 10 → $t0
    li   $t0, 10
    # INT 3 → $t1
    li   $t1, 3
    # ⊞ : $t0 := $t0 mod $t1  (mfhi = residuo)
    div  $t0, $t1
    mfhi $t0
    # print int (consume $t0)
    move $a0, $t0
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # INT 4 → $t0
    li   $t0, 4
    # INT 5 → $t1
    li   $t1, 5
    # ⊠ : $t0 := 2*$t0 + $t1  (sll=×2, add)
    sll  $t0, $t0, 1
    add  $t0, $t0, $t1
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
    # INT 3 → $t1
    li   $t1, 3
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
    # INT 8 → $t0
    li   $t0, 8
    # ± : $t0 := 0 - $t0
    sub  $t0, $zero, $t0
    # print int (consume $t0)
    move $a0, $t0
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # INT 16 → $t0
    li   $t0, 16
    # ± : $t0 := 0 - $t0
    sub  $t0, $zero, $t0
    # ± : $t0 := 0 - $t0
    sub  $t0, $zero, $t0
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
