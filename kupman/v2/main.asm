    INCLUDE     "includes/Hardware.inc"
    INCLUDE     "includes/Addsub1.inc"
    INCLUDE     "includes/SHIFT.INC"
    INCLUDE     "includes/LOAD1.INC"
    INCLUDE     "kupman/v2/costants.asm"
    INCLUDE     "kupman/v2/data.asm"
    INCLUDE     "kupman/v2/move_01.asm"
    INCLUDE     "kupman/v2/move_02.asm"
    INCLUDE     "kupman/v2/AI.asm"


    SECTION     "V-Blank IRQ Vector",HOME[$40]
VBL_VECT:
    jp      DRAW
    
    SECTION     "Start",HOME[$100]
    nop
    jp      START

; $0104-$0133 (Nintendo logo)
    DB  $CE,$ED,$66,$66,$CC,$0D,$00,$0B,$03,$73,$00,$83,$00,$0C,$00,$0D
    DB  $00,$08,$11,$1F,$88,$89,$00,$0E,$DC,$CC,$6E,$E6,$DD,$DD,$D9,$99
    DB  $BB,$BB,$67,$63,$6E,$0E,$EC,$CC,$DD,$DC,$99,$9F,$BB,$B9,$33,$3E
; $0134-$013E (Game title 11 upper case ASCII characters; pad with $00)
    DB  "WOW PACMAN",0
; $013F-$0142 (Product code assigned by Nintendo)
    DB  "    "
; $0143 (Color GameBoy compatibility code)
    DB  $00 ; $00 - DMG 
; $0144 (High-nibble of license code - normally $00 if $014B != $33)
    DB  $00
; $0145 (Low-nibble of license code - normally $00 if $014B != $33)
    DB  $00
; $0146 (GameBoy/Super GameBoy indicator)
    DB  $00 ; $00 - GameBoy
; $0147 (Cartridge type - all Color GameBoy cartridges are at least $19)
    DB  $00 ; 0 - ROM ONLY
; $0148 (ROM size)
    DB  $00 ; 0 -   256Kbit =  32KByte  =   2 banks
; $0149 (RAM size)
    DB  $00 ; 0 - None
; $014A (Destination code)
    DB  $01 ; $01 - All others
; $014B (Licensee code - this _must_ be $33)
    DB  $33 ; $33 - Check $0144/$0145 for Licensee code.
; $014C (Mask ROM version - handled by RGBFIX)
    DB  $00
; $014D (Complement check - handled by RGBFIX)
    DB  $00
; $014E-$014F (Cartridge checksum - handled by RGBFIX)
    DW  $00


;************************************************************************
;*  Program Start

    SECTION     "Program Start",HOME[$0150]
START::
    di                     ; disable interrupts
    ld      sp,$FFFE                ; set the stack to $FFFE

    call    WAITERINO
    call    WAITERINO               ; I want to see nintendo's logo
    call    WAITERINO

    call    WAIT_VBLANK
    ld      a,%00000001
    ldh     [rLCDC],a               ; turn off LCD

    ld      a,%11100100             ; normal palette loading
    ldh     [rBGP],a
    ldh     [rOBP0],a


; Write OAM DMA Transfer instruction to $FF80 
    ld      c,$80
    ld      b,$0A                   ; # bytes of instructions
    ld      hl,DMADATA
L1:
    ld      a,[hl+]
    ld      [c],a                   ; ld [c],a          a -> $FF00 + [c]
    inc     c
    dec     b
    jr      nz,L1

; Setup copying-loops
; loop with counter < 1 byte
    call    SELF_COPY
    ld      a,$C6                   ; adjust loop JUMP
    ld      de,$C612
    ld      [de],a
; loop with counter >= 1 byte
    ld      a,$1B
    ld      [mCOUNT],a
    ld      bc,LONG_COPY
    ld      a,b
    ld      [mWHAT1],a
    ld      a,c
    ld      [mWHAT2],a
    ld      bc,LOAD_LONG
    ld      a,b
    ld      [mWHERE1],a
    ld      a,c
    ld      [mWHERE2],a
    call    LOAD_SHORT              ; copy LONG_COPY


; First write of OBJ in WRAM
    ld      b,$A0
    ld      hl,_PACY
L2:
    xor     a
    ld      [hl+],a
    dec     b
    jp      nz,L2
; First write of my variables in WRAM
    xor     a
    ld      [rTRY],a
    ld      [rTRY_1],a
    ld      [rMOVE],a
    ld      [rMOVE_1],a
    ld      [rDIRECTION],a
    ld      [rDIRECTION_1],a
    ld      [rTRANSITION],a
    ld      [rTRANSITION_1],a
    ld      [rFORBIDDEN],a
    ld      [rINPUTS],a
    ld      [rSCORE],a
    ld      [arrMD],a
    ld      [arrMD+$01],a
    ld      [arrMD+$02],a
    ld      [arrMD+$03],a
    ld      a,$90
    ld      [rREMDOTS],a            ; Dots on map
    ld      a,$99
    ld      [rPOS1],a               ; Starting position
    ld      [rPOS1_1],a
    ld      a,$25
    ld      [rPOS2],a
    ld      a,$2F
    ld      [rPOS2_1],a
    ld      a,$FF
    ld      [rTURN],a

; Starting screen
    call    LOAD_LONG               ; already setup to copy START_TILES
    call    LOAD_START


    ld      a,%10001001             ;
    ldh     [rLCDC],a               ; LCDC On, BG_data from $8800, show SCRN1, BG Display ON

; Wait START input
waitstart:
    call    INPUTS
    ld      a,[rINPUTS]
    cp      $80
    jp      nz,waitstart

; Fading screen (each palette update occurs during VBlank period)
    call    WAIT_VBLANK
    ld      a,%10010000
    ldh     [rBGP],a
    call    WAITERINO
    call    WAIT_VBLANK
    ld      a,%01000000
    ldh     [rBGP],a
    call    WAITERINO

    call    WAIT_VBLANK
    ld      a,%00000001
    ldh     [rLCDC],a               ; turn off LCD
    call    WAITERINO

    ld      a,%11100100             ; restore normal palette
    ldh     [rBGP],a

    call    LOAD_TILES              
    call    LOAD_MAP
    call    LOAD_BITMAP
    call    LOAD_SPRITES

    call    MAIN_CHAR               ; setup main char
    call    SECOND_CHAR

    ld      a,%10000011             ;
    ldh     [rLCDC],a               ; LCDC On, BG_data from $8800, OBJ ON, BG Display ON

    ld      a,%00000001             ;
    ldh     [rIE], a                ; VBlank interrupt only

    ei
    halt
    nop

    xor     a
    ld      [rINPUTS],a             
waitinput:                          
    call    INPUTS                  ; Wait first direction input
    call    AI_DIRECTION
    ld      a,[rINPUTS]
    and     $0C
    jp      z,waitinput

    ld      b,$02

CICLO:

    ld      a,[_PACY]
    ld      l,a
    ld      a,[_PACX]
    ld      h,a

    call    compute_1

    call    AI_DIRECTION            ; register AI direction

    ld      a,[_GH1Y]
    ld      l,a
    ld      a,[_GH1X]
    ld      h,a

    ld      a,[rTURN]
    and     $3F
    cp      $16
    jr      z,_skipped
    call    compute_2

_skipped:
    ld      a,$E0                   ;
    ldh     [rIF], a                ; disable all IF
    
    ei
    halt                            ; Wait for VBlank for OAM DMA Transer
    nop

    call    INPUTS                  ; register current input, if any

    ld      a,[rREMDOTS]            ; if there are no remeaning dots, restart game
    or      a                       ; cp $00
    jp      z,EXIT


    call    WAIT_VBLANK
    call    WAIT_VBLANK


    ld      a,[rTURN]
    dec     a
    jp      z,_reset_counter
    ld      [rTURN],a
    jp      CICLO
_reset_counter:
    ld      a,$FF
    ld      [rTURN],a
    jp      CICLO
    nop

EXIT:
    jp      START



    INCLUDE "kupman/v2/utilities.asm"
