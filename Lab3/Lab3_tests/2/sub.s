# test sub ($tx initialized with 1)
        .data   0x10008000      # start of Dynamic Data (pointed by $gp)
title:  .asciiz "Test: sub"
        .text   0x00400000      # start of Text (pointed by PC), 
main:   sub     $t1, $a2, $sp   # t1 = 0x7fffff7c - 0x7fffff74 = 8
        sub     $t0, $0, $t1    # t0 = 0 - 1
        sub     $t2, $t1, $t0   # t2 = 1 - 1
        sub     $t3, $t2, $t0   # t3 = 1 - 1
        sub     $t4, $0, $t2    # t4 = 0 - 1
        sub     $t4, $t2, $t4   # t4 = 0 - 1
        sub     $t5, $t4, $t0   # t5 = 1 - 0
        sub     $t5, $t5, $t3   # t5 = 1 - 0
        sub     $0, $0, $0
        sub     $0, $t0, $t1
