    .data
vf_doble_x: .word 0    # param de doble
vf_suma_a: .word 0    # param de suma
vf_suma_b: .word 0    # param de suma
vf_resta_a: .word 0    # param de resta
vf_resta_b: .word 0    # param de resta

    .text
    .globl main
main:
    # INT 5 → $t0
    li   $t0, 5
    # ─── llamada a doble(x) ───
    move $a0, $t0    # arg 1 (x)
    jal  func_doble
    # resultado de doble: $v0 → $t0
    move $t0, $v0
    # print int (consume $t0)
    move $a0, $t0
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # INT 3 → $t0
    li   $t0, 3
    # INT 4 → $t1
    li   $t1, 4
    # ─── llamada a suma(a, b) ───
    move $a0, $t0    # arg 1 (a)
    move $a1, $t1    # arg 2 (b)
    jal  func_suma
    # resultado de suma: $v0 → $t1
    move $t1, $v0
    # print int (consume $t1)
    move $a0, $t1
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # INT 7 → $t1
    li   $t1, 7
    # ─── llamada a doble(x) ───
    move $a0, $t1    # arg 1 (x)
    jal  func_doble
    # resultado de doble: $v0 → $t1
    move $t1, $v0
    # print int (consume $t1)
    move $a0, $t1
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # INT 10 → $t1
    li   $t1, 10
    # INT 20 → $t0
    li   $t0, 20
    # ─── llamada a suma(a, b) ───
    move $a0, $t1    # arg 1 (a)
    move $a1, $t0    # arg 2 (b)
    jal  func_suma
    # resultado de suma: $v0 → $t0
    move $t0, $v0
    # print int (consume $t0)
    move $a0, $t0
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # INT 3 → $t0
    li   $t0, 3
    # INT 5 → $t1
    li   $t1, 5
    # ─── llamada a resta(a, b) ───
    move $a0, $t0    # arg 1 (a)
    move $a1, $t1    # arg 2 (b)
    jal  func_resta
    # resultado de resta: $v0 → $t1
    move $t1, $v0
    # print int (consume $t1)
    move $a0, $t1
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall

    # exit (main) — frontera con código de funciones
    li   $v0, 10
    syscall

# ===== func doble(x) — línea 8 =====
func_doble:
    sw   $a0, vf_doble_x    # copia del param x
    # VAR x (vf_doble_x) → $t0
    lw   $t0, vf_doble_x
    # VAR x (vf_doble_x) → $t1
    lw   $t1, vf_doble_x
    # + : $t0 := $t0 + $t1
    add  $t0, $t0, $t1
    # return: $t0 → $v0 y regresar a quien llamó
    move $v0, $t0
    jr   $ra
    # fallback: regresar si no hubo return explícito
    jr   $ra
# ===== fin func doble =====

# ===== func suma(a, b) — línea 12 =====
func_suma:
    sw   $a0, vf_suma_a    # copia del param a
    sw   $a1, vf_suma_b    # copia del param b
    # VAR a (vf_suma_a) → $t0
    lw   $t0, vf_suma_a
    # VAR b (vf_suma_b) → $t1
    lw   $t1, vf_suma_b
    # + : $t0 := $t0 + $t1
    add  $t0, $t0, $t1
    # return: $t0 → $v0 y regresar a quien llamó
    move $v0, $t0
    jr   $ra
    # fallback: regresar si no hubo return explícito
    jr   $ra
# ===== fin func suma =====

# ===== func resta(a, b) — línea 16 =====
func_resta:
    sw   $a0, vf_resta_a    # copia del param a
    sw   $a1, vf_resta_b    # copia del param b
    # VAR a (vf_resta_a) → $t0
    lw   $t0, vf_resta_a
    # VAR b (vf_resta_b) → $t1
    lw   $t1, vf_resta_b
    # - : $t0 := $t0 - $t1
    sub  $t0, $t0, $t1
    # return: $t0 → $v0 y regresar a quien llamó
    move $v0, $t0
    jr   $ra
    # fallback: regresar si no hubo return explícito
    jr   $ra
# ===== fin func resta =====


# → tests/iteracion7/01_funciones_basicas.asm
