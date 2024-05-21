# test add ($tx initialized with 1)
        .data   0x10008000      # start of Dynamic Data (pointed by $gp)
title:  .asciiz "Test: add"
        .text   0x00400000      # start of Text (pointed by PC), 
main:   add     $t0, $0, $0     # t0 = 0
        add     $t1, $0, $gp    # t1 = gp
        add     $t2, $t1, $gp   # t2 = 1 + gp
        add     $t3, $gp, $t2   # t3 = gp + 1
        add     $t4, $t2, $t2   # t4 = 1 + 1
        add     $t5, $t4, $t1   # t5 = 1 + gp
        add     $t6, $t4, $t2   # t6 = 1 + (1 + gp)
        add     $t7, $t4, $t3   # t7 = 2 + (gp + 1)
        add     $0, $0, $0
        add     $0, $t0, $t1
