    .data
v_hex_var: .word 0
v_bin_var: .word 0
str_0: .asciiz "--- mezcla ---"
v_huerfana: .word 0

    .text
    .globl main
main:
    # expr BASED [FF:16]  (= 255)
    li   $t0, 255
    # assign hex_var <-- (consume $t0)
    sw   $t0, v_hex_var
    # expr BASED [1010:2]  (= 10)
    li   $t0, 10
    # assign bin_var <-- (consume $t0)
    sw   $t0, v_bin_var
    # expr STRING "--- mezcla ---"
    la   $t0, str_0
    # print string (consume $t0)
    move $a0, $t0
    li   $v0, 4
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # expr VAR hex_var  (label v_hex_var)
    lw   $t0, v_hex_var
    # print int (consume $t0)
    move $a0, $t0
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # expr VAR bin_var  (label v_bin_var)
    lw   $t0, v_bin_var
    # print int (consume $t0)
    move $a0, $t0
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # expr VAR huerfana  (label v_huerfana)
    lw   $t0, v_huerfana
    # print int (consume $t0)
    move $a0, $t0
    li   $v0, 1
    syscall
    # newline (LF)
    li   $v0, 11
    li   $a0, 10
    syscall
    # expr INT 1
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
