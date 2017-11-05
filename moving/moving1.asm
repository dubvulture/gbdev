	INCLUDE	"includes/Hardware.inc"

_SPR0_Y     EQU     _OAMRAM			; sprite Y 0 is the beginning of the sprite mem
_SPR0_X     EQU     _OAMRAM+1
_SPR0_NUM   EQU     _OAMRAM+2
_SPR0_ATT   EQU     _OAMRAM+3

_SPR1_Y     EQU     _OAMRAM+4
_SPR1_X     EQU     _OAMRAM+5
_SPR1_NUM   EQU     _OAMRAM+6
_SPR1_ATT   EQU     _OAMRAM+7

_SPR2_Y     EQU     _OAMRAM+8
_SPR2_X     EQU     _OAMRAM+9
_SPR2_NUM   EQU     _OAMRAM+10
_SPR2_ATT   EQU     _OAMRAM+11

_SPR3_Y     EQU     _OAMRAM+12
_SPR3_X     EQU     _OAMRAM+13
_SPR3_NUM   EQU     _OAMRAM+14
_SPR3_ATT   EQU     _OAMRAM+15

_MAP_VRAM   EQU     _VRAM+$1000


	SECTION	"Org $00",HOME[$00]
RST_00:	
	jp	$100
	SECTION	"Org $08",HOME[$08]
RST_08:	
	jp	$100
	SECTION	"Org $10",HOME[$10]
RST_10:
	jp	$100
	SECTION	"Org $18",HOME[$18]
RST_18:
	jp	$100
	SECTION	"Org $20",HOME[$20]
RST_20:
	jp	$100
	SECTION	"Org $28",HOME[$28]
RST_28:
	jp	$100
	SECTION	"Org $30",HOME[$30]
RST_30:
	jp	$100
	SECTION	"Org $38",HOME[$38]
RST_38:
	jp	$100


	SECTION	"V-Blank IRQ Vector",HOME[$40]
VBL_VECT:
	jp DRAW
	
	SECTION	"LCD IRQ Vector",HOME[$48]
LCD_VECT:
	reti

	SECTION	"Timer IRQ Vector",HOME[$50]
TIMER_VECT:
	reti

	SECTION	"Serial IRQ Vector",HOME[$58]
SERIAL_VECT:
	reti

	SECTION	"Joypad IRQ Vector",HOME[$60]
JOYPAD_VECT:
	jp BTNS
	
	SECTION	"Start",HOME[$100]
	nop
	jp START


; $0104-$0133 (Nintendo logo)
	DB	$CE,$ED,$66,$66,$CC,$0D,$00,$0B,$03,$73,$00,$83,$00,$0C,$00,$0D
	DB	$00,$08,$11,$1F,$88,$89,$00,$0E,$DC,$CC,$6E,$E6,$DD,$DD,$D9,$99
	DB	$BB,$BB,$67,$63,$6E,$0E,$EC,$CC,$DD,$DC,$99,$9F,$BB,$B9,$33,$3E

; $0134-$013E (Game title 11 upper case ASCII characters; pad with $00)
	DB	"MOVING_1",0,0,0
; $013F-$0142 (Product code assigned by Nintendo)
	DB	"    "		; 0123
; $0143 (Color GameBoy compatibility code)
	DB	$00			; $00 - DMG 
; $0144 (High-nibble of license code - normally $00 if $014B != $33)
	DB	$00
; $0145 (Low-nibble of license code - normally $00 if $014B != $33)
	DB	$00
; $0146 (GameBoy/Super GameBoy indicator)
	DB	$00			; $00 - GameBoy
; $0147 (Cartridge type - all Color GameBoy cartridges are at least $19)
	DB	$00			; 0 - ROM ONLY
; $0148 (ROM size)
	DB	$00			; 0 - 	256Kbit	=  32KByte	=   2 banks
; $0149 (RAM size)
	DB	$00			; 0 - None
; $014A (Destination code)
	DB	$01			; $01 - All others
; $014B (Licensee code - this _must_ be $33)
	DB	$33			; $33 - Check $0144/$0145 for Licensee code.
; $014C (Mask ROM version - handled by RGBFIX)
	DB	$00
; $014D (Complement check - handled by RGBFIX)
	DB	$00
; $014E-$014F (Cartridge checksum - handled by RGBFIX)
	DW	$00


;******************************************************************************
;*	Program Start

	SECTION "Program Start",HOME[$0150]
START::
	di						; disable interrupts
	ld	sp,$FFFE			; set the stack to $FFFE

	ld a,%00000001
	ldh	[rLCDC],a			; turn off LCD

	ld	a,%11100100			; load a normal palette - 11 10 01 00 - dark->light
	ldh	[rBGP],a			; load the palette for background
	ldh	[rOBP0],a			; load the palette for objects

	call LOAD_TILES
	call LOAD_MAP
	call CLEAR_SPRITES
	call LOAD_SPRITES

; Sprite Top-Sx
	ld	a,80
	ld	[_SPR0_Y],a			; Y position of the sprite     
	ld	a,77
	ld	[_SPR0_X],a			; X position of the sprite
	ld	a, $01
	ld	[_SPR0_NUM],a		; number of tile on the table that we will use tiles
	xor	a
	ld	[_SPR0_ATT],a		; special attributes
; Sprite Top-Dx
	ld	a,80
	ld	[_SPR1_Y],a			; Y position of the sprite     
	ld	a,85
	ld	[_SPR1_X],a			; X position of the sprite
	ld	a,$01
	ld	[_SPR1_NUM],a		; number of tile on the table that we will use tiles
	ld	a,%00100000
	ld	[_SPR1_ATT],a		; special attributes
; Sprite Bottom-Sx
	ld	a,88
	ld	[_SPR2_Y],a			; Y position of the sprite     
	ld	a,77
	ld	[_SPR2_X],a			; X position of the sprite
	ld	a,$03
	ld	[_SPR2_NUM],a		; number of tile on the table that we will use tiles
	ld	a,%00000000
	ld	[_SPR2_ATT],a		; special attributes
; Sprite Bottom-Dx
	ld	a,88
	ld	[_SPR3_Y],a			; Y position of the sprite     
	ld	a,85
	ld	[_SPR3_X],a			; X position of the sprite
	ld	a,$03
	ld	[_SPR3_NUM],a		; number of tile on the table that we will use tiles
	ld	a,%00100000
	ld	[_SPR3_ATT],a		; special attributes


	ld	a,%10000011			;
	ldh	[rLCDC],a			; LCDC On, BG from $8800, OBJ ON, BG Display ON

CICLO:
	ld	a,%00010000			;
	ldh [rIE], a			; Joypad interrupt

	ld	a,$E0				;
	ldh [rIF], a			; disable all IF
	ld	a,$2F				;
	ld	[rP1],a				; Set 0 at the output line P15 (Up/Down/Left/Right)
	ei
	halt
	nop

	ld	a,%10000011			;
	ldh	[rLCDC],a			; LCDC On, BG from $8800, OBJ ON, BG Display ON

	ld	bc,$50F0
wait:
	dec	bc					; decrement our counter
	ld	a,b					; load B into A
	or	c					; if B or C != 0         			; 1 cycle
	jr  nz,wait  			; 4 cycles
	nop
	jr	CICLO
	nop


;*******************************************************************************************
; Joypad interrupt handler
BTNS::
	push af
	push bc
	push hl

	ld	a,[rP1]
	ld	a,[rP1]
	ld	a,[rP1]

	cpl
	and	$0F
	ld	b,a

	ld	a,$30				;
	ld	[rP1],a				; Set 1s at both P14 and P15 lines (off)

	ld a,%00000001			;
	ldh [rIE], a			; enable only VBlank interrupt in order to redraw

	ld	a,$E0				;
	ldh [rIF], a			; disable all IF

	ei 						; VBlank will occur, interrupt will be handled and screen redrawn correctly
	halt
	nop

	pop	hl	
	pop	bc
	pop	af
	ret						; return from handler w\o enabling interrupts


;******************************************************************************
; VBlank interrupt handler
DRAW::
	push af
	push bc
	push hl
	
	ld 	a,%00000001
	ldh	[rLCDC],a
	
	ld	a,[rSCX]
	ld	h,a
	ld	a,[rSCY]
	ld	l,a

	ld	a,b

	cp	$08
	jr	z,down
	cp	$04
	jr	z,up
	cp	$02
	jr	z,sx
	cp	$01
	jr	z,dx
	jr	redraw

up:										; Attributes don't matter here
	ld	a,l
	sub	$08
	ld	l,a
	xor	a
	ld	[_SPR0_ATT],a
	ld	a,$06
	ld	[_SPR0_NUM],a
	ld	[_SPR1_NUM],a
	ld	[_SPR2_NUM],a
	ld	[_SPR3_NUM],a
	jr	redraw 
down:
	ld	a,l
	add	$08
	ld	l,a
	ld	a,$02
	ld	[_SPR0_NUM],a
	ld	[_SPR1_NUM],a
	xor	a
	ld	[_SPR0_ATT],a
	ld	a,%00100000
	ld	[_SPR1_ATT],a
	ld	a,$04
	ld	[_SPR2_NUM],a
	ld	[_SPR3_NUM],a
	jr	redraw
sx:
	ld	a,h
	sub $08
	ld	h,a
	ld	a,$08
	ld	[_SPR0_NUM],a
	xor	a
	ld	[_SPR0_ATT],a
	ld	a,$04
	ld	[_SPR1_NUM],a
	ld	[_SPR3_NUM],a
	ld	a,%01100000
	ld	[_SPR1_ATT],a
	ld	a,$0A
	ld	[_SPR2_NUM],a
	jr	redraw
dx:
	ld	a,h
	add	$08
	ld	h,a
	ld	a,$04
	ld	[_SPR0_NUM],a
	ld	[_SPR2_NUM],a
	ld	a,%01000000
	ld	[_SPR0_ATT],a
	ld	a,$08
	ld	[_SPR1_NUM],a
	ld	a,%00100000
	ld	[_SPR1_ATT],a
	ld	a,$0A
	ld	[_SPR3_NUM],a

redraw:
	ld	a,h
	ldh	[rSCX],a
	ld	a,l
	ldh	[rSCY],a

	pop	hl
	pop	bc	
	pop af
	ret						; return from handler w\o enabling interrupts


;******************************************************************************
;* SUBROUTINES

LOAD_TILES::
	ld	hl,STREET_TILES
	ld	de,_MAP_VRAM
	ld	bc,$0240			; Number of tiles * 16 bytes each
LOAD_TILES_LOOP::
	ld	a,[hl+]				; get a byte from our tiles, and increment.
	ld	[de],a				; put that byte in VRAM and
	inc	de					; increment.
	dec	bc
	ld	a,b
	or	c					; if B or C != 0,
	jr	nz,LOAD_TILES_LOOP	; then loop.
	ret

LOAD_MAP::
	push hl
	push de
	push bc

	ld	de, _SCRN0
	ld	hl,STREET_MAP
	ld	bc,$0400
LOAD_MAP_LOOP::
	ld	a,[hl+]				; get a byte of the map and inc hl
	ld	[de],a				; put the byte at de
	inc	de
	dec	bc		
	ld	a,b
	or	c
	jr	nz,LOAD_MAP_LOOP

	pop bc
	pop de
	pop hl
	ret

CLEAR_SPRITES::
	push hl
	push bc

	ld	hl,_OAMRAM
	ld	b,$A0					; counter - $FEA0 - $FE00
CLEAR_SPRITES_LOOP::
	xor a
	ld	[hl+],a					; load A into [HL], then increment HL
	dec	b						; decrement our counter
	jr	nz,CLEAR_SPRITES_LOOP	; then loop
	
	pop bc
	pop hl
	ret

; Move sprites to VRAM[$8000]
LOAD_SPRITES::	
	push af
	push bc
	push de
	push hl

	ld	hl,MY_SPRITES
	ld	de,_VRAM
	ld	b,$B0					; Number of tiles * 16 bytes each
LOAD_SPRITES_LOOP::
	ld	a,[hl+]					; get a byte from our tiles, and increment.
	ld	[de],a					; put that byte in VRAM and
	inc	de						; increment.
	dec	b
	jr	nz,LOAD_SPRITES_LOOP		; then loop.

	pop	hl
	pop	de
	pop	bc
	pop	af
	ret

;******************************************************************************

 SECTION "Sprites",HOME[$1000]

; Start of tile array.

MY_SPRITES::

BLANK_TILE::
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00		; 00

FRONT_EYE_STILL::
;DB $00,$FF,$00,$FF,$00,$C0,$00,$C0,$06,$C6,$06,$C6,$00,$C0,$00,$C0		; 01
DB $00,$FF,$00,$FF,$3F,$C0,$3F,$C0,$3F,$C0,$3F,$C6,$3F,$C6,$3F,$C0

FRONT_EYE_MOVE::
;DB $FF,$FF,$FF,$FF,$C0,$C0,$C0,$C0,$C6,$C6,$C6,$C6,$C0,$C0,$C0,$C0		; 02
DB $FF,$FF,$FF,$FF,$FF,$C0,$FF,$C0,$FF,$C0,$FF,$C6,$FF,$C6,$FF,$C0

FRONT_BODY_STILL::
;DB $00,$C0,$00,$C0,$00,$C0,$00,$C0,$00,$C0,$00,$C0,$00,$FF,$00,$FF		; 03
DB $3F,$C0,$3F,$C0,$3F,$C0,$3F,$C0,$3F,$C0,$3F,$C0,$00,$FF,$00,$FF

FRONT_BODY_MOVE::
;DB $C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$FF,$FF,$FF,$FF		; 04
DB $FF,$C0,$FF,$C0,$FF,$C0,$FF,$C0,$FF,$C0,$FF,$C0,$FF,$FF,$FF,$FF

BACK_STILL::
DB $00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF		; 05

BACK_MOVE::
DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF		; 06

SIDE_EYE_STILL::
;DB $00,$FF,$00,$FF,$00,$80,$00,$80,$30,$B0,$30,$B0,$00,$80,$00,$80		; 07
DB $00,$FF,$00,$FF,$7F,$80,$7F,$80,$7F,$80,$7F,$B0,$7F,$B0,$7F,$80

SIDE_EYE_MOVE::
;DB $FF,$FF,$FF,$FF,$80,$80,$80,$80,$B0,$B0,$B0,$B0,$80,$80,$80,$80		; 08
DB $FF,$FF,$FF,$FF,$FF,$80,$FF,$80,$FF,$80,$FF,$B0,$FF,$B0,$FF,$80

SIDE_BODY_STILL::
;DB $00,$80,$00,$80,$00,$80,$00,$80,$00,$80,$00,$80,$00,$FF,$00,$FF		; 09
DB $7F,$80,$7F,$80,$7F,$80,$7F,$80,$7F,$80,$7F,$80,$00,$FF,$00,$FF

SIDE_BODY_MOVE::
;DB $80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$FF,$FF,$FF,$FF		; 10
DB $FF,$80,$FF,$80,$FF,$80,$FF,$80,$FF,$80,$FF,$80,$FF,$FF,$FF,$FF


;************************************************************
;* Tile map

SECTION "Map",HOME

STREET_MAP::
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$02,$02,$02,$02
DB $03,$02,$02,$02,$04,$05,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$02,$02,$02,$02
DB $06,$02,$02,$02,$04,$05,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$02,$02,$02,$02
DB $07,$02,$02,$02,$04,$05,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$02,$02,$02,$02
DB $03,$02,$02,$02,$04,$05,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$02,$02,$02,$02
DB $08,$02,$02,$02,$04,$05,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$02,$02,$02,$02
DB $09,$02,$02,$02,$04,$05,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$02,$02,$02,$02
DB $03,$02,$02,$02,$04,$05,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$02,$02,$02,$02
DB $0A,$02,$02,$02,$04,$05,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$02,$02,$02,$02
DB $03,$02,$02,$02,$04,$05,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$02,$02,$02,$02
DB $03,$02,$02,$02,$04,$05,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$02,$02,$02,$02
DB $02,$02,$02,$02,$04,$05,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$02,$02,$02,$02
DB $03,$02,$02,$02,$04,$05,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0C,$0D,$0D,$0D,$0D
DB $03,$02,$02,$02,$04,$0E,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B
DB $0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F
DB $10,$02,$02,$02,$04,$11,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F
DB $02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02
DB $02,$02,$02,$02,$04,$12,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02
DB $02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02
DB $02,$02,$02,$02,$04,$12,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02
DB $13,$14,$15,$16,$14,$17,$18,$14,$17,$18,$14,$17,$02,$02,$02,$02
DB $02,$02,$02,$02,$04,$19,$15,$16,$14,$15,$16,$14,$15,$16,$14,$1A
DB $02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$1B,$1C,$02,$02,$02,$02
DB $02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02
DB $02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$1B,$1C,$02,$02,$02,$02
DB $02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02
DB $02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$1B,$1C,$02,$02,$02,$02
DB $02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02
DB $1D,$1D,$1D,$1D,$1D,$1D,$1D,$1D,$1D,$1D,$1D,$1E,$02,$02,$02,$02
DB $1F,$1F,$1F,$1F,$1F,$20,$1D,$1D,$1D,$1D,$1D,$1D,$1D,$1D,$1D,$1D
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$02,$02,$02,$02
DB $03,$02,$02,$02,$04,$05,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$02,$02,$02,$02
DB $21,$02,$02,$02,$04,$05,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$02,$02,$02,$02
DB $09,$02,$02,$02,$04,$05,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$02,$02,$02,$02
DB $03,$02,$02,$02,$04,$05,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$02,$02,$02,$02
DB $22,$02,$02,$02,$04,$05,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$02,$02,$02,$02
DB $07,$02,$02,$02,$04,$05,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$02,$02,$02,$02
DB $03,$02,$02,$02,$04,$05,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$02,$02,$02,$02
DB $06,$02,$02,$02,$04,$05,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$02,$02,$02,$02
DB $23,$02,$02,$02,$04,$05,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$02,$02,$02,$02
DB $03,$02,$02,$02,$04,$05,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$02,$02,$02,$02
DB $08,$02,$02,$02,$04,$05,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

;********************************************************************

 SECTION "Tiles", HOME

STREET_TILES::
DB $FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00
DB $80,$7C,$80,$7C,$80,$7C,$80,$7C,$80,$7C,$80,$7C,$80,$7C,$80,$7C
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$E0,$00,$E0,$00,$E0,$00,$E0,$00,$E0,$00,$E0,$00,$E0,$00,$E0
DB $00,$0F,$00,$0F,$00,$0F,$00,$0F,$00,$0F,$00,$0F,$00,$0F,$00,$0F
DB $7F,$80,$7F,$80,$7F,$80,$7F,$80,$7F,$80,$7F,$80,$7F,$80,$7F,$80
DB $00,$E0,$00,$E0,$00,$E0,$00,$E0,$00,$E0,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$E0,$00,$E0,$00,$E0,$00,$E0
DB $00,$E0,$00,$E0,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$E0,$00,$E0,$00,$E0,$00,$E0,$00,$E0,$00,$E0
DB $00,$E0,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$E0
DB $FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$00,$FF
DB $80,$7C,$80,$7C,$80,$7C,$80,$7C,$80,$7F,$80,$7F,$80,$7F,$00,$FF
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$00,$FF,$00,$FF,$00,$FF
DB $7F,$80,$7F,$80,$7F,$80,$7F,$80,$7F,$80,$7F,$80,$7F,$80,$00,$FF
DB $00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$E0,$00,$E0,$00,$E0,$00,$E0,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$F0,$00,$F0,$00,$F0,$00,$F0
DB $00,$F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$1F,$00,$1F,$00,$1F
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$00,$FF,$00,$FF
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$F8,$00,$F8,$00,$F8
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07,$00,$07,$00,$07
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FC,$00,$FC,$00,$FC
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$00,$03,$00,$03
DB $00,$F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00,$FF,$00,$FF,$00,$FF
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$F0,$00,$F0,$00,$F0
DB $00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03
DB $00,$FC,$00,$FC,$00,$FC,$00,$FC,$00,$FC,$00,$FC,$00,$FC,$00,$FC
DB $00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$FF,$00,$FF,$00,$FF,$00
DB $00,$FC,$00,$FC,$00,$FC,$00,$FC,$00,$FC,$80,$7C,$80,$7C,$80,$7C
DB $00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF
DB $00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$7F,$80,$7F,$80,$7F,$80
DB $00,$E0,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$E0,$00,$E0,$00,$E0,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$E0,$00,$E0
