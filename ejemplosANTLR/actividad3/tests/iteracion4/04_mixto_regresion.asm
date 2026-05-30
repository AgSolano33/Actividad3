    .data
v_a: .word 0
v_b: .word 0
str_0: .asciiz "--- mezcla ---"
str_1: .asciiz "doble más:"
str_2: .asciiz "modulo:"
str_3: .asciiz "promedio negativo:"
str_4: .asciiz "negacion:"
str_5: .asciiz "modulo de hex:"
str_6: .asciiz "neg de binario + 3:"
str_7: .asciiz "FIN"

    .text
    .globl main
main:
    # INT 9 → $t0
    li   $t0, 9
    # a <-- (consume $t0)  → v_a
    sw   $t0, v_a
    # INT 5 → $t0
    li   $t0, 5
    # b <-- (consume $t0)  → v_b
    sw   $t0, v_b
    # STRING "--- mezcla ---" → $t0
    la   $t0, str_0
    # print string (consume $t0)
    move $a0, $t0
    li   $v0, 4
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # STRING "doble más:" → $t0
    la   $t0, str_1
    # print string (consume $t0)
    move $a0, $t0
    li   $v0, 4
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # VAR a (v_a) → $t0
    lw   $t0, v_a
    # VAR b (v_b) → $t1
    lw   $t1, v_b
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
    # STRING "modulo:" → $t0
    la   $t0, str_2
    # print string (consume $t0)
    move $a0, $t0
    li   $v0, 4
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # INT 17 → $t0
    li   $t0, 17
    # INT 5 → $t1
    li   $t1, 5
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
    # STRING "promedio negativo:" → $t0
    la   $t0, str_3
    # print string (consume $t0)
    move $a0, $t0
    li   $v0, 4
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # INT 7 → $t0
    li   $t0, 7
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
    # STRING "negacion:" → $t0
    la   $t0, str_4
    # print string (consume $t0)
    move $a0, $t0
    li   $v0, 4
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # VAR a (v_a) → $t0
    lw   $t0, v_a
    # INT 1 → $t1
    li   $t1, 1
    # + : $t0 := $t0 + $t1
    add  $t0, $t0, $t1
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
    # STRING "modulo de hex:" → $t0
    la   $t0, str_5
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
    # BASED [A:16] (= 10) → $t1
    li   $t1, 10
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
    # STRING "neg de binario + 3:" → $t0
    la   $t0, str_6
    # print string (consume $t0)
    move $a0, $t0
    li   $v0, 4
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # BASED [1010:2] (= 10) → $t0
    li   $t0, 10
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
    # STRING "FIN" → $t0
    la   $t0, str_7
    # print string (consume $t0)
    move $a0, $t0
    li   $v0, 4
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall

    # exit (main) — frontera con código de funciones
    li   $v0, 10
    syscall


# → tests/iteracion4/04_mixto_regresion.asm
