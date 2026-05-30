    .data
v_x: .word 0
v_y: .word 0
str_0: .asciiz "--- y negativo, if no entra ---"

    .text
    .globl main
main:
    # INT 0 → $t0
    li   $t0, 0
    # x <-- (consume $t0)  → v_x
    sw   $t0, v_x
    # ===== while #1 (linea 19) =====
loop_start_1:
    # ----- cond -----
    # VAR x (v_x) → $t0
    lw   $t0, v_x
    # INT 6 → $t1
    li   $t1, 6
    # <  : $t0 := ($t0 < $t1) ? 1 : 0
    slt  $t0, $t0, $t1
    beq  $t0, $zero, loop_end_1    # cond falsa → salir
    # ----- body -----
    # ===== if #1 (linea 20) =====
    # ----- cond -----
    # VAR x (v_x) → $t1
    lw   $t1, v_x
    # INT 2 → $t2
    li   $t2, 2
    # ⊞ : $t1 := $t1 mod $t2  (mfhi = residuo)
    div  $t1, $t2
    mfhi $t1
    # INT 0 → $t2
    li   $t2, 0
    # == : $t1 := ($t1 == $t2) ? 1 : 0
    seq  $t1, $t1, $t2
    beq  $t1, $zero, if_end_1    # cond falsa → fin
    # ----- then -----
    # VAR x (v_x) → $t2
    lw   $t2, v_x
    # print int (consume $t2)
    move $a0, $t2
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
if_end_1:
    # ===== fin if #1 =====
    # VAR x (v_x) → $t1
    lw   $t1, v_x
    # INT 1 → $t2
    li   $t2, 1
    # + : $t1 := $t1 + $t2
    add  $t1, $t1, $t2
    # x <-- (consume $t1)  → v_x
    sw   $t1, v_x
    j    loop_start_1                     # volver a evaluar cond
loop_end_1:
    # ===== fin while #1 =====
    # INT 3 → $t0
    li   $t0, 3
    # y <-- (consume $t0)  → v_y
    sw   $t0, v_y
    # ===== if #2 (linea 24) =====
    # ----- cond -----
    # VAR y (v_y) → $t0
    lw   $t0, v_y
    # INT 0 → $t1
    li   $t1, 0
    # >  : $t0 := ($t0 > $t1) ? 1 : 0   (slt operandos invertidos)
    slt  $t0, $t1, $t0
    beq  $t0, $zero, if_end_2    # cond falsa → fin
    # ----- then -----
    # ===== while #2 (linea 24) =====
loop_start_2:
    # ----- cond -----
    # VAR y (v_y) → $t1
    lw   $t1, v_y
    # INT 0 → $t2
    li   $t2, 0
    # >  : $t1 := ($t1 > $t2) ? 1 : 0   (slt operandos invertidos)
    slt  $t1, $t2, $t1
    beq  $t1, $zero, loop_end_2    # cond falsa → salir
    # ----- body -----
    # VAR y (v_y) → $t2
    lw   $t2, v_y
    # print int (consume $t2)
    move $a0, $t2
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # VAR y (v_y) → $t2
    lw   $t2, v_y
    # INT 1 → $t3
    li   $t3, 1
    # - : $t2 := $t2 - $t3
    sub  $t2, $t2, $t3
    # y <-- (consume $t2)  → v_y
    sw   $t2, v_y
    j    loop_start_2                     # volver a evaluar cond
loop_end_2:
    # ===== fin while #2 =====
if_end_2:
    # ===== fin if #2 =====
    # STRING "--- y negativo, if no entra ---" → $t0
    la   $t0, str_0
    # print string (consume $t0)
    move $a0, $t0
    li   $v0, 4
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # INT 2 → $t0
    li   $t0, 2
    # ± : $t0 := 0 - $t0
    sub  $t0, $zero, $t0
    # y <-- (consume $t0)  → v_y
    sw   $t0, v_y
    # ===== if #3 (linea 30) =====
    # ----- cond -----
    # VAR y (v_y) → $t0
    lw   $t0, v_y
    # INT 0 → $t1
    li   $t1, 0
    # >  : $t0 := ($t0 > $t1) ? 1 : 0   (slt operandos invertidos)
    slt  $t0, $t1, $t0
    beq  $t0, $zero, if_end_3    # cond falsa → fin
    # ----- then -----
    # ===== while #3 (linea 30) =====
loop_start_3:
    # ----- cond -----
    # VAR y (v_y) → $t1
    lw   $t1, v_y
    # INT 0 → $t2
    li   $t2, 0
    # >  : $t1 := ($t1 > $t2) ? 1 : 0   (slt operandos invertidos)
    slt  $t1, $t2, $t1
    beq  $t1, $zero, loop_end_3    # cond falsa → salir
    # ----- body -----
    # INT 999 → $t2
    li   $t2, 999
    # print int (consume $t2)
    move $a0, $t2
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # VAR y (v_y) → $t2
    lw   $t2, v_y
    # INT 1 → $t3
    li   $t3, 1
    # - : $t2 := $t2 - $t3
    sub  $t2, $t2, $t3
    # y <-- (consume $t2)  → v_y
    sw   $t2, v_y
    j    loop_start_3                     # volver a evaluar cond
loop_end_3:
    # ===== fin while #3 =====
if_end_3:
    # ===== fin if #3 =====

    # exit (main) — frontera con código de funciones
    li   $v0, 10
    syscall


# → tests/iteracion6/03_if_while_cruzados.asm
