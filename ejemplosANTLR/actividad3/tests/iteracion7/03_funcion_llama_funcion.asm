    .data
vf_doble_x: .word 0    # param de doble
vf_cuadruple_x: .word 0    # param de cuadruple
vf_suma_a: .word 0    # param de suma
vf_suma_b: .word 0    # param de suma
vf_suma_de_2_a: .word 0    # param de suma_de_2
vf_suma_de_2_b: .word 0    # param de suma_de_2

    .text
    .globl main
main:
    # ─── llamada a externa(∅) ───
    jal  func_externa
    # resultado de externa: $v0 → $t1
    move $t1, $v0
    # print int (consume $t1)
    move $a0, $t1
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # ─── llamada a externa(∅) ───
    jal  func_externa
    # resultado de externa: $v0 → $t1
    move $t1, $v0
    # INT 2 → $t0
    li   $t0, 2
    # × : $t1 := $t1 × $t0
    mult $t1, $t0
    mflo $t1
    # print int (consume $t1)
    move $a0, $t1
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # INT 11 → $t1
    li   $t1, 11
    # ─── llamada a cuadruple(x) ───
    move $a0, $t1    # arg 1 (x)
    jal  func_cuadruple
    # resultado de cuadruple: $v0 → $t1
    move $t1, $v0
    # print int (consume $t1)
    move $a0, $t1
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # INT 3 → $t1
    li   $t1, 3
    # INT 4 → $t0
    li   $t0, 4
    # ─── llamada a suma_de_2(a, b) ───
    move $a0, $t1    # arg 1 (a)
    move $a1, $t0    # arg 2 (b)
    jal  func_suma_de_2
    # resultado de suma_de_2: $v0 → $t0
    move $t0, $v0
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

# ===== func interna(∅) — línea 19 =====
func_interna:
    # INT 42 → $t0
    li   $t0, 42
    # return: $t0 → $v0 y regresar a quien llamó
    move $v0, $t0
    jr   $ra
    # fallback: regresar si no hubo return explícito
    jr   $ra
# ===== fin func interna =====

# ===== func externa(∅) — línea 23 =====
func_externa:
    # ─── llamada a interna(∅) ───
    # guardar $ra (estamos dentro de una función)
    addiu $sp, $sp, -4
    sw   $ra, 0($sp)
    jal  func_interna
    lw   $ra, 0($sp)
    addiu $sp, $sp, 4
    # resultado de interna: $v0 → $t0
    move $t0, $v0
    # INT 1 → $t1
    li   $t1, 1
    # + : $t0 := $t0 + $t1
    add  $t0, $t0, $t1
    # return: $t0 → $v0 y regresar a quien llamó
    move $v0, $t0
    jr   $ra
    # fallback: regresar si no hubo return explícito
    jr   $ra
# ===== fin func externa =====

# ===== func doble(x) — línea 27 =====
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

# ===== func cuadruple(x) — línea 31 =====
func_cuadruple:
    sw   $a0, vf_cuadruple_x    # copia del param x
    # VAR x (vf_cuadruple_x) → $t0
    lw   $t0, vf_cuadruple_x
    # ─── llamada a doble(x) ───
    move $a0, $t0    # arg 1 (x)
    # guardar $ra (estamos dentro de una función)
    addiu $sp, $sp, -4
    sw   $ra, 0($sp)
    jal  func_doble
    lw   $ra, 0($sp)
    addiu $sp, $sp, 4
    # resultado de doble: $v0 → $t0
    move $t0, $v0
    # ─── llamada a doble(x) ───
    move $a0, $t0    # arg 1 (x)
    # guardar $ra (estamos dentro de una función)
    addiu $sp, $sp, -4
    sw   $ra, 0($sp)
    jal  func_doble
    lw   $ra, 0($sp)
    addiu $sp, $sp, 4
    # resultado de doble: $v0 → $t0
    move $t0, $v0
    # return: $t0 → $v0 y regresar a quien llamó
    move $v0, $t0
    jr   $ra
    # fallback: regresar si no hubo return explícito
    jr   $ra
# ===== fin func cuadruple =====

# ===== func suma(a, b) — línea 35 =====
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

# ===== func suma_de_2(a, b) — línea 39 =====
func_suma_de_2:
    sw   $a0, vf_suma_de_2_a    # copia del param a
    sw   $a1, vf_suma_de_2_b    # copia del param b
    # VAR a (vf_suma_de_2_a) → $t0
    lw   $t0, vf_suma_de_2_a
    # VAR b (vf_suma_de_2_b) → $t1
    lw   $t1, vf_suma_de_2_b
    # ─── llamada a suma(a, b) ───
    move $a0, $t0    # arg 1 (a)
    move $a1, $t1    # arg 2 (b)
    # guardar $ra (estamos dentro de una función)
    addiu $sp, $sp, -4
    sw   $ra, 0($sp)
    jal  func_suma
    lw   $ra, 0($sp)
    addiu $sp, $sp, 4
    # resultado de suma: $v0 → $t1
    move $t1, $v0
    # INT 0 → $t0
    li   $t0, 0
    # + : $t1 := $t1 + $t0
    add  $t1, $t1, $t0
    # return: $t1 → $v0 y regresar a quien llamó
    move $v0, $t1
    jr   $ra
    # fallback: regresar si no hubo return explícito
    jr   $ra
# ===== fin func suma_de_2 =====
