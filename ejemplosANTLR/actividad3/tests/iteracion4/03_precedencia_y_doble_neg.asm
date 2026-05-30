    .data

    .text
    .globl main
main:
    # INT 5 → $t0
    li   $t0, 5
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
    # INT 7 → $t0
    li   $t0, 7
    # ± : $t0 := 0 - $t0
    sub  $t0, $zero, $t0
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
    # INT 2 → $t0
    li   $t0, 2
    # ± : $t0 := 0 - $t0
    sub  $t0, $zero, $t0
    # INT 3 → $t1
    li   $t1, 3
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
    # INT 1 → $t0
    li   $t0, 1
    # INT 2 → $t1
    li   $t1, 2
    # INT 3 → $t2
    li   $t2, 3
    # ⊠ : $t1 := 2*$t1 + $t2  (sll=×2, add)
    sll  $t1, $t1, 1
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
    # INT 2 → $t0
    li   $t0, 2
    # INT 3 → $t1
    li   $t1, 3
    # × : $t0 := $t0 × $t1
    mult $t0, $t1
    mflo $t0
    # INT 4 → $t1
    li   $t1, 4
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
    # INT 10 → $t0
    li   $t0, 10
    # INT 3 → $t1
    li   $t1, 3
    # ⊞ : $t0 := $t0 mod $t1  (mfhi = residuo)
    div  $t0, $t1
    mfhi $t0
    # INT 5 → $t1
    li   $t1, 5
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
    # INT 2 → $t0
    li   $t0, 2
    # ± : $t0 := 0 - $t0
    sub  $t0, $zero, $t0
    # INT 3 → $t1
    li   $t1, 3
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
    # INT 8 → $t0
    li   $t0, 8
    # INT 4 → $t1
    li   $t1, 4
    # ≈ : $t0 := piso(($t0 + $t1) / 2)   (add + sra)
    add  $t0, $t0, $t1
    sra  $t0, $t0, 1
    # INT 2 → $t1
    li   $t1, 2
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
