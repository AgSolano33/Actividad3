    .data
str_0: .asciiz "hola"
vf_suma4_a: .word 0    # param de suma4
vf_suma4_b: .word 0    # param de suma4
vf_suma4_c: .word 0    # param de suma4
vf_suma4_d: .word 0    # param de suma4
vf_absoluto_n: .word 0    # param de absoluto
vf_resetX_x: .word 0
v_x: .word 0

    .text
    .globl main
main:
    # INT 100 → $t0
    li   $t0, 100
    # x <-- (consume $t0)  → v_x
    sw   $t0, v_x
    # ─── llamada a saludo(∅) ───
    jal  func_saludo
    # resultado de saludo: $v0 → $t0
    move $t0, $v0
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
    # INT 4 → $t3
    li   $t3, 4
    # ─── llamada a suma4(a, b, c, d) ───
    move $a0, $t0    # arg 1 (a)
    move $a1, $t1    # arg 2 (b)
    move $a2, $t2    # arg 3 (c)
    move $a3, $t3    # arg 4 (d)
    jal  func_suma4
    # resultado de suma4: $v0 → $t3
    move $t3, $v0
    # print int (consume $t3)
    move $a0, $t3
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # INT 42 → $t3
    li   $t3, 42
    # ± : $t3 := 0 - $t3
    sub  $t3, $zero, $t3
    # ─── llamada a absoluto(n) ───
    move $a0, $t3    # arg 1 (n)
    jal  func_absoluto
    # resultado de absoluto: $v0 → $t3
    move $t3, $v0
    # print int (consume $t3)
    move $a0, $t3
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # INT 7 → $t3
    li   $t3, 7
    # ─── llamada a absoluto(n) ───
    move $a0, $t3    # arg 1 (n)
    jal  func_absoluto
    # resultado de absoluto: $v0 → $t3
    move $t3, $v0
    # print int (consume $t3)
    move $a0, $t3
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # ─── llamada a resetX(∅) ───
    jal  func_resetX
    # resultado de resetX: $v0 → $t3
    move $t3, $v0
    # print int (consume $t3)
    move $a0, $t3
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # VAR x (v_x) → $t3
    lw   $t3, v_x
    # print int (consume $t3)
    move $a0, $t3
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall

    # exit (main) — frontera con código de funciones
    li   $v0, 10
    syscall

# ===== func saludo(∅) — línea 17 =====
func_saludo:
    # STRING "hola" → $t0
    la   $t0, str_0
    # print string (consume $t0)
    move $a0, $t0
    li   $v0, 4
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # INT 0 → $t0
    li   $t0, 0
    # return: $t0 → $v0 y regresar a quien llamó
    move $v0, $t0
    jr   $ra
    # fallback: regresar si no hubo return explícito
    jr   $ra
# ===== fin func saludo =====

# ===== func suma4(a, b, c, d) — línea 22 =====
func_suma4:
    sw   $a0, vf_suma4_a    # copia del param a
    sw   $a1, vf_suma4_b    # copia del param b
    sw   $a2, vf_suma4_c    # copia del param c
    sw   $a3, vf_suma4_d    # copia del param d
    # VAR a (vf_suma4_a) → $t0
    lw   $t0, vf_suma4_a
    # VAR b (vf_suma4_b) → $t1
    lw   $t1, vf_suma4_b
    # + : $t0 := $t0 + $t1
    add  $t0, $t0, $t1
    # VAR c (vf_suma4_c) → $t1
    lw   $t1, vf_suma4_c
    # + : $t0 := $t0 + $t1
    add  $t0, $t0, $t1
    # VAR d (vf_suma4_d) → $t1
    lw   $t1, vf_suma4_d
    # + : $t0 := $t0 + $t1
    add  $t0, $t0, $t1
    # return: $t0 → $v0 y regresar a quien llamó
    move $v0, $t0
    jr   $ra
    # fallback: regresar si no hubo return explícito
    jr   $ra
# ===== fin func suma4 =====

# ===== func absoluto(n) — línea 26 =====
func_absoluto:
    sw   $a0, vf_absoluto_n    # copia del param n
    # ===== if #1 (linea 27) =====
    # ----- cond -----
    # VAR n (vf_absoluto_n) → $t0
    lw   $t0, vf_absoluto_n
    # INT 0 → $t1
    li   $t1, 0
    # <  : $t0 := ($t0 < $t1) ? 1 : 0
    slt  $t0, $t0, $t1
    beq  $t0, $zero, if_end_1    # cond falsa → fin
    # ----- then -----
    # VAR n (vf_absoluto_n) → $t1
    lw   $t1, vf_absoluto_n
    # ± : $t1 := 0 - $t1
    sub  $t1, $zero, $t1
    # return: $t1 → $v0 y regresar a quien llamó
    move $v0, $t1
    jr   $ra
if_end_1:
    # ===== fin if #1 =====
    # VAR n (vf_absoluto_n) → $t0
    lw   $t0, vf_absoluto_n
    # return: $t0 → $v0 y regresar a quien llamó
    move $v0, $t0
    jr   $ra
    # fallback: regresar si no hubo return explícito
    jr   $ra
# ===== fin func absoluto =====

# ===== func resetX(∅) — línea 31 =====
func_resetX:
    # INT 0 → $t0
    li   $t0, 0
    # x <-- (consume $t0)  → vf_resetX_x
    sw   $t0, vf_resetX_x
    # VAR x (vf_resetX_x) → $t0
    lw   $t0, vf_resetX_x
    # return: $t0 → $v0 y regresar a quien llamó
    move $v0, $t0
    jr   $ra
    # fallback: regresar si no hubo return explícito
    jr   $ra
# ===== fin func resetX =====


# → tests/iteracion7/04_borde_y_scoping.asm
