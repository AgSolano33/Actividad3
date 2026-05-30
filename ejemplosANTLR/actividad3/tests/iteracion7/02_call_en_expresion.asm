    .data
vf_doble_x: .word 0    # param de doble
vf_triple_x: .word 0    # param de triple
v_y: .word 0

    .text
    .globl main
main:
    # INT 3 → $t0
    li   $t0, 3
    # ─── llamada a doble(x) ───
    move $a0, $t0    # arg 1 (x)
    jal  func_doble
    # resultado de doble: $v0 → $t0
    move $t0, $v0
    # INT 1 → $t1
    li   $t1, 1
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
    # INT 4 → $t1
    li   $t1, 4
    # ─── llamada a triple(x) ───
    # preservar 1 t-reg(s) vivos: $t0
    addiu $sp, $sp, -4
    sw   $t0, 0($sp)
    move $a0, $t1    # arg 1 (x)
    jal  func_triple
    lw   $t0, 0($sp)
    addiu $sp, $sp, 4
    # resultado de triple: $v0 → $t1
    move $t1, $v0
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
    # INT 5 → $t0
    li   $t0, 5
    # ─── llamada a doble(x) ───
    move $a0, $t0    # arg 1 (x)
    jal  func_doble
    # resultado de doble: $v0 → $t0
    move $t0, $v0
    # INT 2 → $t1
    li   $t1, 2
    # ─── llamada a triple(x) ───
    # preservar 1 t-reg(s) vivos: $t0
    addiu $sp, $sp, -4
    sw   $t0, 0($sp)
    move $a0, $t1    # arg 1 (x)
    jal  func_triple
    lw   $t0, 0($sp)
    addiu $sp, $sp, 4
    # resultado de triple: $v0 → $t1
    move $t1, $v0
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
    # INT 8 → $t0
    li   $t0, 8
    # ─── llamada a doble(x) ───
    move $a0, $t0    # arg 1 (x)
    jal  func_doble
    # resultado de doble: $v0 → $t0
    move $t0, $v0
    # y <-- (consume $t0)  → v_y
    sw   $t0, v_y
    # VAR y (v_y) → $t0
    lw   $t0, v_y
    # print int (consume $t0)
    move $a0, $t0
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # ===== if #1 (linea 28) =====
    # ----- cond -----
    # INT 3 → $t0
    li   $t0, 3
    # ─── llamada a doble(x) ───
    move $a0, $t0    # arg 1 (x)
    jal  func_doble
    # resultado de doble: $v0 → $t0
    move $t0, $v0
    # INT 5 → $t1
    li   $t1, 5
    # >  : $t0 := ($t0 > $t1) ? 1 : 0   (slt operandos invertidos)
    slt  $t0, $t1, $t0
    beq  $t0, $zero, if_else_1   # cond falsa → else
    # ----- then -----
    # INT 1 → $t1
    li   $t1, 1
    # print int (consume $t1)
    move $a0, $t1
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    j    if_end_1                       # then ejecutado → fin
if_else_1:
    # ----- else -----
    # INT 0 → $t1
    li   $t1, 0
    # print int (consume $t1)
    move $a0, $t1
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
if_end_1:
    # ===== fin if #1 =====
    # INT 2 → $t0
    li   $t0, 2
    # ─── llamada a doble(x) ───
    move $a0, $t0    # arg 1 (x)
    jal  func_doble
    # resultado de doble: $v0 → $t0
    move $t0, $v0
    # INT 4 → $t1
    li   $t1, 4
    # ─── llamada a doble(x) ───
    # preservar 1 t-reg(s) vivos: $t0
    addiu $sp, $sp, -4
    sw   $t0, 0($sp)
    move $a0, $t1    # arg 1 (x)
    jal  func_doble
    lw   $t0, 0($sp)
    addiu $sp, $sp, 4
    # resultado de doble: $v0 → $t1
    move $t1, $v0
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

    # exit (main) — frontera con código de funciones
    li   $v0, 10
    syscall

# ===== func doble(x) — línea 13 =====
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

# ===== func triple(x) — línea 17 =====
func_triple:
    sw   $a0, vf_triple_x    # copia del param x
    # INT 3 → $t0
    li   $t0, 3
    # VAR x (vf_triple_x) → $t1
    lw   $t1, vf_triple_x
    # × : $t0 := $t0 × $t1
    mult $t0, $t1
    mflo $t0
    # return: $t0 → $v0 y regresar a quien llamó
    move $v0, $t0
    jr   $ra
    # fallback: regresar si no hubo return explícito
    jr   $ra
# ===== fin func triple =====


# → tests/iteracion7/02_call_en_expresion.asm
