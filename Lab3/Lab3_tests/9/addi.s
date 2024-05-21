# test beq & addi
        .data   0x10008000      # start of Dynamic Data (pointed by $gp)
title:  .asciiz "Test: beq & addi (for-loop sum from 0 to 8)"
        .text   0x00400000      # start of Text (pointed by PC), 
main:   
        addi    $a0, $0, 8      # N: a0 = 8
        addi    $t0, $0, 0      # i: t0 = 0
        nop
        nop
loop:   beq     $t0, $a0, exit	# if i == N exit
        add     $t1, $t1, $t0   # c += i
        addi    $t0, $t0, 1     # i++
        nop
        nop
        beq     $0, $0, loop
exit:   nop
        nop
        nop
