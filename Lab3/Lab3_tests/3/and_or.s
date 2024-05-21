# test and & or ($tx & $sx initialized with 1, except t3 & s3)
        .data   0x10008000      # start of Dynamic Data (pointed by $gp)
title:  .asciiz "Test: and & or"
        .text   0x00400000      # start of Text (pointed by PC), 
main:   and     $t0, $gp, $gp   # t0 = gp
        and     $t1, $gp, $sp   # t1 = gp & sp
        and     $t2, $a2, $sp   # t2 = a2 & sp
        and     $t3, $t1, $t2   # t3 = 1
        and     $0, $gp, $gp
        or      $s0, $gp, $gp   # s0 = gp
        or      $s1, $gp, $sp   # s1 = gp | sp
        or      $s2, $a2, $sp   # s2 = a2 | sp
        or      $s3, $s1, $s2   # s3 = 1
        or      $0, $gp, $gp