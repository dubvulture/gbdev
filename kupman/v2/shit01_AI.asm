save:
    and     $01
    jr      nz,calling
    cpl                     ; store $FF if not pathable
    jr      save_   
calling:
    call    nz,euclidean    
save_:
    ld      [hl+],a
    ret


forbidden:
    xor     a
    cpl
    ld      [hl+],a
    ret

; a <- distance
euclidean:
    push    bc
    push    de
    push    hl

    ld      a,[_PACY]
    ld      h,a
    ld      a,[_PACX]
    ld      l,a

    ld      a,b
    cp      h
    jr      c,less_1
cp_2:   
    ld      a,c
    cp      l
    jr      c,less_2
    jr      do
less_1:
    swapr   b,h
    jr      cp_2
less_2:
    swapr   c,l
do:
    ld      a,b
    sub     h
    ld      d,a             ; d1 -> d
    ld      a,c
    sub     l               ; d2 -> a
    add     a,d             ; thank god maximum distance if $F8

    pop     hl
    pop     de
    pop     bc
    ret




AI_DIRECTION::

    push    bc
    push    de
    push    hl

    ld      a,[rPOS1_1]
    ld      d,a
    ld      a,[rPOS2_1]
    ld      e,a
    ld      a,[_GH1Y]
    ld      b,a
    ld      a,[_GH1X]
    ld      c,a
    ld      hl,arrMD

;; Down
    ld      a,b
    add     a,$08
    ld      b,a
    add16ir de,$0020
    ld      a,[rFORBIDDEN]
    cp      $08
    call    z,forbidden
    ld      a,[rFORBIDDEN]
    cp      $08
    jr      z,ai_up
    call    GET_BITMAP
    call    save
;; Up
ai_up:
    ld      a,b
    sub     $10
    ld      b,a
    sub16ir de,$0040
    ld      a,[rFORBIDDEN]
    cp      $04
    call    z,forbidden
    ld      a,[rFORBIDDEN]
    cp      $04
    jr      z,ai_sx
    call    GET_BITMAP
    call    save
;; Sx
ai_sx:
    ld      a,b 
    add     a,$08
    ld      b,a
    ld      a,c
    sub     $08
    ld      c,a
    add16ir de,$001F
    ld      a,[rFORBIDDEN]
    cp      $02
    call    z,forbidden
    ld      a,[rFORBIDDEN]
    cp      $02
    jr      z,ai_dx
    call    GET_BITMAP
    call    save
;; Dx
ai_dx:
    ld      a,c
    add     $10
    ld      c,a
    add16ir de,$0002
    ld      a,[rFORBIDDEN]
    cp      $01
    call    z,forbidden
    ld      a,[rFORBIDDEN]
    cp      $01
    jr      z,get_min
    call    GET_BITMAP
    call    save

get_min:
    ld      a,$08
    ld      d,a                 ; direction counter
    ld      e,a                 ; maximum direction ($08 default)
    xor     a
    cpl
    ld      c,a                 ; maximum value (FF)
    ld      hl,arrMD
max_loop:
    ld      a,[hl+]             ; get distance
    cp      c                   ; compare to maximum
    jr      nc,loop_check       ; if a<c then do not replace and jump
    ld      c,a                 ; replace maximum
    ld      a,d                 ;
    ld      e,a                 ; remember which direction is the maximum one
loop_check:
    srl     d                   ; next direction
    jr      nz,max_loop

    ld      a,e
    ld      [rMOVE_1],a ; store chosen direction

    pop     hl
    pop     de
    pop     bc

    ret
