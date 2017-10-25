; Compute position in tiles coordinates (ONLY IF X MOD 8 = 0 = Y MOD 8) / otherwise set transition state
compute_2::

    push    bc
    push    de
    push    hl

    ld      a,[rPOS1_1]
    ld      d,a
    ld      a,[rPOS2_1]
    ld      e,a

    ld      a,h
    and     $07
    ld      b,a
    ld      a,l
    and     $07
    or      b
    jp      nz,.trans
    jr      .move

.trans:
; We can only move in the same direction or opposite one
    ld      a,[rDIRECTION_1]
    ld      b,a

    cp      $04                     ; If move >= 04 then updown only
    jp      nc,.updown
    
    ld      a,b
    cp      $01                     ; If move >= 01 (and < 04) then sxdx only
    jp      nc,.sxdx

; This part will be replaced with a debugging screen (hopefully)
.DOOM:
    jp      .DOOM


.updown:
    ld      a,[rMOVE_1]
    cp      $08                     ; Down
    jr      z,.down
    cp      $04                     ; Up
    jr      z,.up
    ld      a,[rDIRECTION_1]            ; else, set move to global direction
    ld      [rMOVE_1],a
    jr      .move

.sxdx:
    ld      a,[rMOVE_1]
    cp      $02                     ; Sx
    jr      z,.sx
    cp      $01                     ; Dx
    jr      z,.dx
    ld      a,[rDIRECTION_1]
    ld      [rMOVE_1],a


.move:
    ld      a,[rPOS1_1]
    ld      d,a
    ld      a,[rPOS2_1]             ; seems redundant too, but it is needed, WHY
    ld      e,a
    ld      a,[rMOVE_1]
.compare:
    cp      $08                     ; Down
    jr      z,.down
    cp      $04                     ; Up
    jr      z,.up
    cp      $02                     ; Sx
    jr      z,.sx
    cp      $01                     ; Dx
    jr      z,.dx
; If no move has been registered, follow direction
.global:
    ld      a,[rDIRECTION_1]
    or      a                       ; cp $00
    jr      nz,.compare

    jp      .DOOM


; Here's how every one of these works:
;   - If we are in a transition state, sprite position will be moved and updated (jp nz,dir2)
;   - Otherwise we update the position relative to the map, check if it is Pathable
;       - Pathable means we can proceed to dir2
;       - If it is non-pathable see below
.down:
    ld      a,[rTRANSITION_1]
    or      a                       ; cp $00
    jr      nz,.down2
    add16ir de,$0020
    call    GET_BITMAP
    and     $01
    jr      z,.try
.down2:
    inc     l
    call    _DOWN_1
    jr      .redraw
.up:
    ld      a,[rTRANSITION_1]
    or      a                       ; cp $00
    jr      nz,.up2
    sub16ir de,$0020
    call    GET_BITMAP
    and     $01
    jr      z,.try
.up2:
    dec     l
    call    _UP_1
    jr      .redraw
.sx:
    ld      a,[rTRANSITION_1]
    or      a                       ; cp $00
    jr      nz,.sx2
    sub16ir de,$0001
    call    GET_BITMAP
    and     $01
    jr      z,.try
.sx2:   
    dec     h
    call    _SX_1
    jr      .redraw
.dx:
    ld      a,[rTRANSITION_1]
    or      a                       ; cp $00
    jr      nz,.dx2
    add16ir de,$0001
    call    GET_BITMAP
    and     $01
    jr      z,.try
.dx2:
    inc     h
    call    _DX_1
    jr      .redraw
    
; It looks like we are:
;   - going/turning into a wall -> retry following global direction
;   - we already tried -> stop
.try:
    ld      a,[rDIRECTION_1]
    ld      [rMOVE_1],a

    ld      a,[rTRY_1]
    inc     a
    ld      [rTRY_1],a
    cp      $02
    jp      nz,.move


.redraw:
; teleport on sides check
.T1up:
    ld      a,l
    xor     $18
    ld      b,a
    ld      a,h
    xor     $58
    or      b
    jr      nz,.T2down
; Update coordinate
    ld      a,$98
    ld      l,a
    jr      .T3

.T2down:
    ld      a,l
    xor     $98
    ld      b,a
    ld      a,h
    xor     $58
    or      b
    jr      nz,.T3
; Update coordinate
    ld      a,$18
    ld      l,a
.T3:
    ld      a,l
    ld      [_GH1Y],a
    ld      a,h
    ld      [_GH1X],a

;;; Set forbidden direction, aka the opposite of [rDIRECTION_1]

    ld      a,[rDIRECTION_1]
    ld      b,a
    and     %00001010
    jr      z,shift_left
    srl     b
    jr      set_forbidden
shift_left:
    sla     b
set_forbidden:
    ld      a,b
    ld      [rFORBIDDEN],a

    ld      a,h
    and     $07
    ld      b,a
    ld      a,l
    and     $07
    or      b
    jr      nz,.is_trans
    xor     a
    jr      .set_trans
.is_trans:
    ld      a,$FF
.set_trans:
    ld      [rTRANSITION_1],a

    ld      a,[_GH1Y]
    ld      l,a
    ld      a,[_GH1X]
    ld      h,a

    ld      a,h
    and     $07
    ld      b,a
    ld      a,l
    and     $07
    or      b
    jr      nz,.return

    ld      d,$98
    ld      e,$00

    xor     a
    ld      b,a                     ; b = 0
    ld      a,h                     ; Get X coord
    sub     $08                     ; Subtract 8
    ld      c,a
    srl16   bc,3                    ; Divide by 8
    add16r  de,bc                   ; de = $9800 + $00XX

    xor     a
    ld      b,a                     ; b = 0
    ld      a,l                     ; Get Y coord
    sub     $10                     ; Subtract 16
    ld      c,a
    sla16   bc,2                    ; Multiply by 4
    add16r  de,bc                   ; de = $98XX + $00YY
; Update
    ld      a,d
    ld      [rPOS1_1],a
    ld      a,e
    ld      [rPOS2_1],a

.return:
    xor     a
    ld      [rTRY_1],a              ; reset try counter

    pop     hl
    pop     de
    pop     hl
    ret