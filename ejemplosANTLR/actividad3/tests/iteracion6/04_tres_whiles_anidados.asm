    .data
v_i: .word 0
v_j: .word 0
v_k: .word 0
str_0: .asciiz "FIN"

    .text
    .globl main
main:
    # INT 1 → $t0
    li   $t0, 1
    # i <-- (consume $t0)  → v_i
    sw   $t0, v_i
    # ===== while #1 (linea 16) =====
loop_start_1:
    # ----- cond -----
    # VAR i (v_i) → $t0
    lw   $t0, v_i
    # INT 3 → $t1
    li   $t1, 3
    # <  : $t0 := ($t0 < $t1) ? 1 : 0
    slt  $t0, $t0, $t1
    beq  $t0, $zero, loop_end_1    # cond falsa → salir
    # ----- body -----
    # INT 1 → $t1
    li   $t1, 1
    # j <-- (consume $t1)  → v_j
    sw   $t1, v_j
    # ===== while #2 (linea 18) =====
loop_start_2:
    # ----- cond -----
    # VAR j (v_j) → $t1
    lw   $t1, v_j
    # INT 3 → $t2
    li   $t2, 3
    # <  : $t1 := ($t1 < $t2) ? 1 : 0
    slt  $t1, $t1, $t2
    beq  $t1, $zero, loop_end_2    # cond falsa → salir
    # ----- body -----
    # INT 1 → $t2
    li   $t2, 1
    # k <-- (consume $t2)  → v_k
    sw   $t2, v_k
    # ===== while #3 (linea 20) =====
loop_start_3:
    # ----- cond -----
    # VAR k (v_k) → $t2
    lw   $t2, v_k
    # INT 3 → $t3
    li   $t3, 3
    # <  : $t2 := ($t2 < $t3) ? 1 : 0
    slt  $t2, $t2, $t3
    beq  $t2, $zero, loop_end_3    # cond falsa → salir
    # ----- body -----
    # VAR i (v_i) → $t3
    lw   $t3, v_i
    # print int (consume $t3)
    move $a0, $t3
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # VAR j (v_j) → $t3
    lw   $t3, v_j
    # print int (consume $t3)
    move $a0, $t3
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # VAR k (v_k) → $t3
    lw   $t3, v_k
    # print int (consume $t3)
    move $a0, $t3
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # VAR i (v_i) → $t3
    lw   $t3, v_i
    # VAR j (v_j) → $t4
    lw   $t4, v_j
    # × : $t3 := $t3 × $t4
    mult $t3, $t4
    mflo $t3
    # VAR k (v_k) → $t4
    lw   $t4, v_k
    # × : $t3 := $t3 × $t4
    mult $t3, $t4
    mflo $t3
    # print int (consume $t3)
    move $a0, $t3
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # VAR k (v_k) → $t3
    lw   $t3, v_k
    # INT 1 → $t4
    li   $t4, 1
    # + : $t3 := $t3 + $t4
    add  $t3, $t3, $t4
    # k <-- (consume $t3)  → v_k
    sw   $t3, v_k
    j    loop_start_3                     # volver a evaluar cond
loop_end_3:
    # ===== fin while #3 =====
    # VAR j (v_j) → $t2
    lw   $t2, v_j
    # INT 1 → $t3
    li   $t3, 1
    # + : $t2 := $t2 + $t3
    add  $t2, $t2, $t3
    # j <-- (consume $t2)  → v_j
    sw   $t2, v_j
    j    loop_start_2                     # volver a evaluar cond
loop_end_2:
    # ===== fin while #2 =====
    # VAR i (v_i) → $t1
    lw   $t1, v_i
    # INT 1 → $t2
    li   $t2, 1
    # + : $t1 := $t1 + $t2
    add  $t1, $t1, $t2
    # i <-- (consume $t1)  → v_i
    sw   $t1, v_i
    j    loop_start_1                     # volver a evaluar cond
loop_end_1:
    # ===== fin while #1 =====
    # STRING "FIN" → $t0
    la   $t0, str_0
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


# → tests/iteracion6/04_tres_whiles_anidados.asm
