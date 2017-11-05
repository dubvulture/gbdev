	INCLUDE	"includes/Hardware.inc"
	INCLUDE "moving/positions.asm"


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
	DB	"MY OMINO",0,0,0
; $013F-$0142 (Product code assigned by Nintendo)
	DB	"    " ;0123
; $0143 (Color GameBoy compatibility code)
	DB	$00	; $00 - DMG 
; $0144 (High-nibble of license code - normally $00 if $014B != $33)
	DB	$00
; $0145 (Low-nibble of license code - normally $00 if $014B != $33)
	DB	$00
; $0146 (GameBoy/Super GameBoy indicator)
	DB	$00	; $00 - GameBoy
; $0147 (Cartridge type - all Color GameBoy cartridges are at least $19)
	DB	$00	; 0 - ROM ONLY
; $0148 (ROM size)
	DB	$00	; 0 - 	256Kbit	=  32KByte	=   2 banks
; $0149 (RAM size)
	DB	$00	; 0 - None
; $014A (Destination code)
	DB	$01	; $01 - All others
; $014B (Licensee code - this _must_ be $33)
	DB	$33	; $33 - Check $0144/$0145 for Licensee code.
; $014C (Mask ROM version - handled by RGBFIX)
	DB	$00
; $014D (Complement check - handled by RGBFIX)
	DB	$00
; $014E-$014F (Cartridge checksum - handled by RGBFIX)
	DW	$00


;************************************************************************
;*	Program Start

	SECTION "Program Start",HOME[$0150]
START::
	di						; disable interrupts
	ld	sp,$FFFE			; set the stack to $FFFE

	ld a,%00000001
	ldh	[rLCDC],a			; turn off LCD

	ld	a,%11100100			; load a normal palette up 11 10 01 00 - dark->light
	ldh	[rBGP],a			; load the palette
	ldh	[rOBP0],a			; load the palette for Objects

	call LOAD_TILES
	call LOAD_MAP
	call CLEAR_SPRITES
	call LOAD_SPRITES

	call MAIN_CHAR
	call DOWN_STILL

	ld	a,%10000011			;
	ldh	[rLCDC],a			; LCDC On, BG from $8800, OBJ ON, BG Display ON


CICLO:
	ld a,%00010000			;
	ldh [rIE], a			; Joypad interrupt
	ld	a,$E0				;
	ldh [rIF], a			; disable all IF
	ld	a,$2F				;
	ld	[rP1],a				; Set 0 at the output line P15 (Up/Down/Left/Right)

	ei
	halt
	nop

;	ld  bc,$0928			; minimum waiting
	ld	bc,$4A00
wait:
	dec	bc					; decrement our counter
	ld	a,b					; load B into A
	or	c					; if B or C != 0         			; 1 cycle
	jr  nz,wait  			; 4 cycles
	nop

	call RST_POS
	
;	ld  bc,$0928			; minimum waiting

	ld	a,%10000011			;
	ldh	[rLCDC],a			; LCDC On, BG from $8800, OBJ ON, BG Display ON

	ld	bc,$3FFF
wait2:
	dec	bc					; decrement our counter
	ld	a,b					; load B into A
	or	c					; if B or C != 0         			; 1 cycle
	jr  nz,wait2  			; 4 cycles
	
	jr	CICLO
	nop


;******************************************************************************
; Joypad interrupt handler
BTNS::
	push af
	push bc
	push hl

get:
	ld	a,[rP1]
	ld	a,[rP1]
	
	cpl
	and	$0F
	jr	z,no_btns
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

no_btns:
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
	ld	a,[_CHAR_POS]
	and $3C
	jr	z,up2
	ld	a,l
	sub $10
	ld	l,a
up2:
	call UP_MOVE
	jr redraw
down:
	ld	a,[_CHAR_POS]
	and $CC
	jr	z,down2
	ld	a,l
	add $10
	ld	l,a
down2:	
	call DOWN_MOVE
	jr redraw
sx:
	ld	a,[_CHAR_POS]
	and $F8
	jr	z,sx2
	ld	a,h
	sub	$10
	ld	h,a
sx2:
	call SX_MOVE
	jr	redraw
dx:
	ld	a,[_CHAR_POS]
	and $F4
	jr	z,dx2
	ld	a,h
	add $10
	ld	h,a
dx2:
	call DX_MOVE
	ld	a,$04

redraw:
	ld	a,h
	ldh	[rSCX],a
	ld	a,l
	ldh	[rSCY],a

	ld	a,%10000011			;
	ldh	[rLCDC],a			; LCDC On, BG from $8800, OBJ ON, BG Display ON

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
	ld	bc,$120					; $12 tiles * $10 bytes each
LOAD_SPRITES_LOOP::
	ld	a,[hl+]				; get a byte of the map and inc hl
	ld	[de],a				; put the byte at de
	inc	de
	dec	bc		
	ld	a,b
	or	c
	jr	nz,LOAD_SPRITES_LOOP		; then loop.

	pop	hl
	pop	de
	pop	bc
	pop	af
	ret

;******************************************************************************

SECTION "Sprites",HOME[$0A00]

; Start of tile array.

MY_SPRITES::

HEAD_FRONT_STILL::
DB $07,$07,$08,$0F,$10,$1F,$10,$1F,$3B,$3C,$3F,$37,$7F,$50,$7F,$42			; 00

BODY_FRONT_STILL::
DB $3F,$32,$3E,$39,$7F,$4F,$7F,$4F,$39,$3F,$16,$1F,$11,$1F,$0E,$0E			; 01

HEAD_FRONT_MOVE::
DB $00,$00,$07,$07,$08,$0F,$10,$1F,$10,$1F,$3B,$3C,$3F,$3F,$7F,$50			; 02

BODY_FRONT_MOVE_01::
DB $7F,$42,$3F,$32,$2E,$39,$3F,$2F,$3F,$33,$1E,$13,$0D,$0D,$00,$00			; 03

BODY_FRONT_MOVE_02::
DB $FE,$42,$FE,$4E,$7E,$9A,$FC,$FC,$D8,$F8,$70,$F0,$90,$F0,$E0,$E0			; 04

HEAD_SIDE_STILL_01::
DB $07,$07,$08,$0F,$10,$1F,$38,$37,$7C,$43,$31,$3F,$1F,$14,$1F,$14			; 05

HEAD_SIDE_STILL_02
DB $E0,$E0,$10,$F0,$08,$F8,$08,$F8,$1C,$FC,$FC,$FC,$FC,$FC,$F8,$98			; 06

BODY_SIDE_STILL_01::
DB $1F,$10,$0B,$0C,$07,$07,$03,$03,$03,$03,$04,$07,$04,$07,$03,$03			; 07

BODY_SIDE_STILL_02::
DB $F0,$10,$E8,$78,$C8,$F8,$E8,$38,$E8,$38,$F0,$F0,$20,$E0,$C0,$C0			; 08

HEAD_SIDE_MOVE_01::
DB $00,$00,$07,$07,$08,$0F,$10,$1F,$38,$37,$7C,$43,$31,$3F,$1F,$14			; 09

BODY_SIDE_MOVE_01::
DB $1F,$14,$1F,$10,$0B,$0C,$07,$07,$1F,$1F,$24,$3F,$13,$1F,$0E,$0E			; 0A

HEAD_SIDE_MOVE_02::
DB $00,$00,$E0,$E0,$10,$F0,$08,$F8,$08,$F8,$1C,$FC,$FC,$FC,$FC,$FC			; 0B

BODY_SIDE_MOVE_02::
DB $F8,$98,$F0,$10,$E8,$78,$E8,$F8,$F8,$98,$F4,$9C,$E4,$FC,$18,$18			; OC

HEAD_BACK_STILL::
DB $07,$07,$08,$0F,$10,$1F,$10,$1F,$30,$3F,$38,$3F,$7F,$5F,$7F,$4F			; 0D

BODY_BACK_STILL::
DB $3F,$33,$3C,$3F,$7B,$5F,$79,$5E,$3C,$3F,$17,$1F,$11,$1F,$0E,$0E			; 0E

HEAD_BACK_MOVE::
DB $00,$00,$07,$07,$08,$0F,$10,$1F,$10,$1F,$30,$3F,$38,$3F,$7F,$5F			; 0F

BODY_BACK_MOVE_01::
DB $7F,$4F,$3F,$33,$3C,$3F,$7B,$4F,$79,$4E,$3C,$3F,$03,$03,$00,$00			; 10

BODY_BACK_MOVE_02::
DB $FE,$F2,$FE,$CE,$3E,$FA,$DC,$FC,$98,$78,$30,$F0,$D0,$F0,$E0,$E0			; 11


;************************************************************
;* Tile map

SECTION "Map",HOME[$0C00]

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

 SECTION "Tiles", HOME[$1000]

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
