    .data
v_hex_var: .word 0
v_bin_var: .word 0
str_0: .asciiz "--- mezcla ---"
v_huerfana: .word 0

    .text
    .globl main
main:
    # BASED [FF:16] (= 255) → $t0
    li   $t0, 255
    # hex_var <-- (consume $t0)
    sw   $t0, v_hex_var
    # BASED [1010:2] (= 10) → $t0
    li   $t0, 10
    # bin_var <-- (consume $t0)
    sw   $t0, v_bin_var
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
    # VAR hex_var (v_hex_var) → $t0
    lw   $t0, v_hex_var
    # print int (consume $t0)
    move $a0, $t0
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # VAR bin_var (v_bin_var) → $t0
    lw   $t0, v_bin_var
    # print int (consume $t0)
    move $a0, $t0
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # VAR huerfana (v_huerfana) → $t0
    lw   $t0, v_huerfana
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


# → tests/iteracion2/04_mixto_con_bases_y_uso_previo.asm
