;******************************************************************************


;******************************************************
; VBlank interrupt handler
DRAW::
    call    $FF80               ; OAM DMA TRANSFER
    ret

;******************************************************
;* SUBROUTINES


; Just waste time
WAITERINO::
    ld      bc,$EF00
wait:
    dec     bc
    ld      a,b
    or      c
    jr      nz,wait
    ret

WAIT_HBLANK::
    ld      a,[rSTAT]
    cp      $80
    jp      nz,WAIT_HBLANK
    ret

WAIT_VBLANK::
    ldh     a,[rLY]
    cp      $91
    jr      nz,WAIT_VBLANK
    ret


; de -> position on map
REMOVE_DOT::
    push    af
    ld      a,[rREMDOTS]            ; decrement remaining dots counter
    dec     a
    ld      [rREMDOTS],a
    call    GET_POINTS              ; update points
    ld      a,%00000001
    call    WRITE_BITMAP            ; update bitmap
    call    WAIT_HBLANK             ; update map FAST
    ld      a,$03
    ld      [de],a
    pop     af
    ret

; de -> position on map
GET_POINTS::
    push    af
    push    bc
    push    de
    push    hl
    call    GET_BITMAP
    and     %00000111               ; Get only PowerDot or normal dot
    cp      $07                     ; PowerDot
    jp      nz,normaldot
    ld      a,[rSCORE]
    add     $05
    ld      [rSCORE],a
    jp      endpoints
normaldot:
    cp      $03                     ; Normal Dot
    jp      nz,DOOM
    ld      a,[rSCORE]
    inc     a
    ld      [rSCORE],a
endpoints:
    ld      h,a
    call    WRITE_POINTS
    pop     hl
    pop     de
    pop     bc
    pop     af
    ret

;  h -> points
WRITE_POINTS::
    xor     a
    ld      b,a
    ld      c,a
    ld      d,a
    ld      a,h
_sub1_loop:                         ; count tens
    sub     $0A
    jr      c,_end_sub1_loop
    inc     b
    jr      _sub1_loop
_end_sub1_loop:

    add     $0A
_sub2_loop:                         ; count units
    cp      $00
    jr      z,_end_sub2_loop
    dec     a
    inc     c
    jr      _sub2_loop
_end_sub2_loop:

    ld      a,b
_sub3_loop:
    sub     $0A
    jr      c,_end_sub3_loop
    inc     d
    jr      _sub3_loop
_end_sub3_loop:
    add     $0A
    ld      b,a
    
    ; b = tens
    ; c = units
    ; d = hundreds

    call    WAIT_VBLANK

    ld      hl,$9810
    ld      a,d
    add     $04
    ld      [hl+],a
    ld      a,b
    add     $04
    ld      [hl+],a
    ld      a,c
    add     $04
    ld      [hl],a

    ret



; de -> position on map
;  a <- bitmap value
GET_BITMAP::
    push    hl
    push    de
    sub16i  de,$9800
    ld      hl,_BITMAP
    add16r  hl,de
    ld      a,[hl]
    pop     de
    pop     hl
    ret

; de -> position on map
;  a -> bitmap value
WRITE_BITMAP::
    push    hl
    push    de
    push    bc
    ld      b,a
    sub16i  de,$9800
    ld      hl,_BITMAP
    add16r  de,hl
    ld      a,b
    ld      [de],a
    pop     bc
    pop     de
    pop     hl
    ret

; Register input if any, otherwise keep last input
; Then update [rMOVE]
INPUTS::
    push    af
    push    bc

    ld      a,$2F                   ;
    ld      [rP1],a                 ; Set 0 at the output line P14 (Up/Down/Left/Right)
    ld      a,[rP1]
    ld      a,[rP1]
    
    cpl
    and     $0F
    swap    a
    ld      b,a

    ld      a,$1F
    ld      [rP1],a
    ld      a,[rP1]
    ld      a,[rP1]
    ld      a,[rP1]
    ld      a,[rP1]
    ld      a,[rP1]
    ld      a,[rP1]

    cpl
    and     $0F
    or      b
    swap    a
    jp      nz,store
    ld      a,[rINPUTS]
store:
    ld      [rINPUTS],a
    ld      [rMOVE],a

    ld      a,$30
    ld      [rP1],a

    pop     bc
    pop     af
    ret

; Initialize main character
MAIN_CHAR::
    ld      a,$30
    ld      [_PACX],a
    ld      a,$58  
    ld      [_PACY],a
    call    _UP
    ret


; Main character positions
_DOWN::
    ld      b,$01
    ld      a,[rTURN]
    bit     2,a
    jr      z,_open_down
    ld      b,$03
_open_down:
    ld      a,b
    ld      [_PAC_NUM],a
    ld      a,$C0               ; Flip vertical
    ld      [_PAC_ATT],a
    ld      a,$08
    ld      [rDIRECTION],a
    ret

_UP::
    ld      b,$01
    ld      a,[rTURN]
    bit     2,a
    jr      z,_open_up
    ld      b,$03
_open_up:
    ld      a,b
    ld      [_PAC_NUM],a
    ld      a,$80
    ld      [_PAC_ATT],a
    ld      a,$04
    ld      [rDIRECTION],a
    ret

_SX::
    ld      b,$00
    ld      a,[rTURN]
    bit     2,a
    jr      z,_open_sx
    ld      b,$02
_open_sx:
    ld      a,b
    ld      [_PAC_NUM],a
    ld      a,$A0               ; Flip horizontal
    ld      [_PAC_ATT],a
    ld      a,$02
    ld      [rDIRECTION],a
    ret

_DX::
    ld      b,$00
    ld      a,[rTURN]
    bit     2,a
    jr      z,_open_dx
    ld      b,$02
_open_dx:
    ld      a,b
    ld      [_PAC_NUM],a
    ld      a,$80
    ld      [_PAC_ATT],a
    ld      a,$01
    ld      [rDIRECTION],a
    ret

; Initialize main character
SECOND_CHAR::
    ld      a,$80
    ld      [_GH1X],a
    ld      a,$58  
    ld      [_GH1Y],a
    call    _UP_1
    ret


; Main character positions
_DOWN_1::
    ld      a,$06
    ld      [_GH1_NUM],a
    ld      a,$80               ; Flip vertical
    ld      [_GH1_ATT],a
    ld      a,$08
    ld      [rDIRECTION_1],a
    ret

_UP_1::
    ld      a,$05
    ld      [_GH1_NUM],a
    ld      a,$80
    ld      [_GH1_ATT],a
    ld      a,$04
    ld      [rDIRECTION_1],a
    ret

_SX_1::
    ld      a,$04
    ld      [_GH1_NUM],a
    ld      a,$80
    ld      [_GH1_ATT],a
    ld      a,$02
    ld      [rDIRECTION_1],a
    ret

_DX_1::
    ld      a,$04
    ld      [_GH1_NUM],a
    ld      a,$A0               ; Flip horizontal
    ld      [_GH1_ATT],a
    ld      a,$01
    ld      [rDIRECTION_1],a
    ret



;******************************************************************************
; Loading a bunch of shit.

LOAD_TILES::
    ld      bc,SHIT_TILES
    ld      a,b
    ld      [mWHAT1],a
    ld      a,c
    ld      [mWHAT2],a
    ld      bc,_MAP_VRAM
    ld      a,b
    ld      [mWHERE1],a
    ld      a,c
    ld      [mWHERE2],a
    ld      a,$E0
    ld      [mCOUNT],a
    jp      LOAD_SHORT



LOAD_MAP::
    ld      bc,SHIT_MAP
    ld      a,b
    ld      [mWHAT1_L],a
    ld      a,c
    ld      [mWHAT2_L],a
    ld      bc,_SCRN0
    ld      a,b
    ld      [mWHERE1_L],a
    ld      a,c
    ld      [mWHERE2_L],a
    ld      bc,$0400
    ld      a,b
    ld      [mCOUNT1_L],a
    ld      a,c
    ld      [mCOUNT2_L],a
    jp      LOAD_LONG


LOAD_START::
    ld      bc,STARTMAP
    ld      a,b
    ld      [mWHAT1_L],a
    ld      a,c
    ld      [mWHAT2_L],a
    ld      bc,_SCRN1
    ld      a,b
    ld      [mWHERE1_L],a
    ld      a,c
    ld      [mWHERE2_L],a
    ld      bc,$0400
    ld      a,b
    ld      [mCOUNT1_L],a
    ld      a,c
    ld      [mCOUNT2_L],a
    jp      LOAD_LONG


LOAD_BITMAP::
    ld      bc,BITMAP
    ld      a,b
    ld      [mWHAT1_L],a
    ld      a,c
    ld      [mWHAT2_L],a
    ld      bc,_BITMAP
    ld      a,b
    ld      [mWHERE1_L],a
    ld      a,c
    ld      [mWHERE2_L],a
    ld      bc,$0400
    ld      a,b
    ld      [mCOUNT1_L],a
    ld      a,c
    ld      [mCOUNT2_L],a
    jp      LOAD_LONG


LOAD_SPRITES::
    ld      bc,MY_SPRITES
    ld      a,b
    ld      [mWHAT1],a
    ld      a,c
    ld      [mWHAT2],a
    ld      bc,_VRAM
    ld      a,b
    ld      [mWHERE1],a
    ld      a,c
    ld      [mWHERE2],a
    ld      a,$70
    ld      [mCOUNT],a
    jp      LOAD_SHORT