    .data

    .text
    .globl main
main:
    # INT 2 → $t0
    li   $t0, 2
    # INT 3 → $t1
    li   $t1, 3
    # INT 4 → $t2
    li   $t2, 4
    # × : $t1 := $t1 × $t2
    mult $t1, $t2
    mflo $t1
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
    # + : $t0 := $t0 + $t1
    add  $t0, $t0, $t1
    # INT 4 → $t1
    li   $t1, 4
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
    # INT 10 → $t0
    li   $t0, 10
    # INT 3 → $t1
    li   $t1, 3
    # - : $t0 := $t0 - $t1
    sub  $t0, $t0, $t1
    # INT 2 → $t1
    li   $t1, 2
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
    # INT 17 → $t0
    li   $t0, 17
    # INT 5 → $t1
    li   $t1, 5
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

    # exit (main) — frontera con código de funciones
    li   $v0, 10
    syscall


# → tests/iteracion3/02_precedencia.asm
