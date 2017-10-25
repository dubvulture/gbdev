	INCLUDE	"includes/Hardware.inc"
	INCLUDE	"includes/Addsub1.inc"

_MAP_VRAM   EQU     _VRAM+$1000
rSCX_COPY	EQU		_RAM
rSCY_COPY	EQU		_RAM+$01
isFIZZ		EQU		_RAM+$02
isBUZZ		EQU		_RAM+$03
rPOSITION1	EQU		_RAM+$04
rPOSITION2	EQU		_RAM+$05


	SECTION	"V-Blank IRQ Vector",HOME[$40]
VBL_VECT:
	jp DRAW
	SECTION	"Joypad IRQ Vector",HOME[$60]
JOYPAD_VECT:
	jp BTNS

	
	SECTION	"Start",HOME[$100]
	nop
	jp		START

; $0104-$0133 (Nintendo logo)
	DB	$CE,$ED,$66,$66,$CC,$0D,$00,$0B,$03,$73,$00,$83,$00,$0C,$00,$0D
	DB	$00,$08,$11,$1F,$88,$89,$00,$0E,$DC,$CC,$6E,$E6,$DD,$DD,$D9,$99
	DB	$BB,$BB,$67,$63,$6E,$0E,$EC,$CC,$DD,$DC,$99,$9F,$BB,$B9,$33,$3E
; $0134-$013E (Game title 11 upper case ASCII characters; pad with $00)
	DB	0,"FIZZ BUZZ",0
; $013F-$0142 (Product code assigned by Nintendo)
	DB	"    "
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
	di								; disable interrupts
	ld		sp,$FFFE				; set the stack to $FFFE

	call	WAIT
	call	WAIT					; Time wasted to show Nintendo's logo on BGB Emulator
	call	WAIT					; (dunno about others)

	call	WAIT_VBLANK
	ld		a,%00000001
	ldh		[rLCDC],a				; turn off LCD

	ld		a,%11100100				; normal palette loading
	ldh		[rBGP],a

	call	CLEAR_MAP
	call	LOAD_TILES

	ld		a,%00010000				;
	ldh		[rIE], a				; enable only Joypad interrupt

	ld		a,$E0					;
	ldh		[rIF], a				; disable all Interrupt Flags
	ld		a,$2F					;
	ld		[rP1],a					; Set to 0 at the output line P15 (Up/Down/Left/Right)


	ld		a,%10000001				;
	ldh		[rLCDC],a				; LCDC On, BG from $8800, OBJ OFF, BG Display ON

	ld		a,[rSCX]
	ld		[rSCX_COPY],a			; copy scroll registers' value
	ld		a,[rSCY]
	ld		[rSCY_COPY],a

	xor		a
	ld		[rPOSITION2],a			; set initial printing position to $9800
	ld		a,$98
	ld		[rPOSITION1],a

	ei								; enable interrupts (only joypad is enabled)
	nop

	xor		a
	ld		h,a
	ld		a,$03
	ld		b,a						; fizz every 3 numbers
	ld		a,$05
	ld		c,a						; buzz every 5 numbers
	ld		a,$06
	ld		d,a						; newline every 6 numbers
_fb_loop:
	inc		h
	ld		a,h
	cp		100
	jr		z,_halt

	dec		b
	dec		c
	dec		d

	xor		a
	ld		[isFIZZ],a
	ld		[isBUZZ],a

; fizz check
	ld		a,b
	or		a
	jr		nz,_skip_fizz
	ld		a,$03
	ld		b,a
	call	_print_fizz
_skip_fizz:

; buzz check
	ld		a,c
	or		a
	jr		nz,_skip_buzz
	ld		a,$05
	ld		c,a
	call	_print_buzz
_skip_buzz:

; only number check
	ld		a,[isFIZZ]
	ld		e,a
	ld		a,[isBUZZ]
	or		e
	call	z,_print_number

	ld		a,d
	or		a
	jr		nz,_skip_newline
	ld		a,$06
	ld		d,a
	call	_newline
	jr		_fb_loop
_skip_newline:
	call	_print_space
	jr		_fb_loop

; halt system with interrupts enabled (in order to scroll freely)
_halt:
	halt
	nop
	jr		_halt



;;; ROUTINES

WAIT_VBLANK::
	ldh		a,[rLY]
	cp		$91
	jr		nz,WAIT_VBLANK
	ret

; Clear _VRAM from $9800 to $9C00 (1° BG area)
CLEAR_MAP::
	push	hl
	push	bc
	ld		hl,_SCRN0
	ld		bc,$0400				; counter - $9C00 - $9800
CLEAR_MAP_LOOP::
	xor		a
	ld		[hl+],a
	dec		bc
	ld		a,b
	or		c
	jr		nz,CLEAR_MAP_LOOP
	pop		bc
	pop		hl
	ret

LOAD_TILES::
	push	hl
	push	de
	push	bc
	ld		hl,LETTERS
	ld		de,_MAP_VRAM
	ld		bc,$0100				; 10 tiles * 0x10bytes each
LOAD_TILES_LOOP::
	ld		a,[hl+]
	ld		[de],a
	inc		de
	dec		bc
	ld		a,b
	or		c
	jr		nz,LOAD_TILES_LOOP
	pop		bc
	pop		de
	pop		hl
	ret



_print_fizz:
	push	hl

	ld		a,$FF					; set Fizz flag
	ld		[isFIZZ],a				; a whole byte and I do not care

	ld		a,[rPOSITION1]
	ld		h,a
	ld		a,[rPOSITION2]
	ld		l,a

	call	WAIT_VBLANK
	ld		a,$01
	ld		[hl+],a
	inc		a
	ld		[hl+],a
	ld		a,$05
	ld		[hl+],a
	ld		[hl+],a

	ld		a,h
	ld		[rPOSITION1],a
	ld		a,l
	ld		[rPOSITION2],a

	pop		hl
	ret



_print_buzz:
	push	hl

	ld		a,$FF					; set Buzz flag
	ld		[isBUZZ],a

	ld		a,[rPOSITION1]
	ld		h,a
	ld		a,[rPOSITION2]
	ld		l,a

	call	WAIT_VBLANK
	ld		a,$03
	ld		[hl+],a
	inc		a
	ld		[hl+],a
	inc		a
	ld		[hl+],a
	ld		[hl+],a

	ld		a,h
	ld		[rPOSITION1],a
	ld		a,l
	ld		[rPOSITION2],a
	
	pop		hl
	ret



_print_space:
	push	hl

	ld		a,[rPOSITION1]
	ld		h,a
	ld		a,[rPOSITION2]
	ld		l,a

	call	WAIT_VBLANK
	xor		a
	ld		[hl+],a

	ld		a,h
	ld		[rPOSITION1],a
	ld		a,l
	ld		[rPOSITION2],a
	
	pop		hl
	ret


_newline:
	push	hl

	ld		a,[rPOSITION1]
	ld		h,a
	ld		a,[rPOSITION2]
	ld		l,a

	add16ir	hl,$20					; newline, same position

	ld		a,h
	ld		[rPOSITION1],a
	ld		a,l
	and		$E0						; start of line
	ld		[rPOSITION2],a

	pop		hl
	ret


; number in register h
_print_number:
	push	hl
	push	de
	push	bc

	xor		a
	ld		b,a
	ld		c,a
	ld		a,h
_sub_loop:							; count tens
	sub		$0A
	jr		c,_end_sub_loop
	inc		b
	jr		_sub_loop
_end_sub_loop:						; b = tens

	add		$0A
	ld		c,a						; c = units

	ld		a,[rPOSITION1]
	ld		h,a
	ld		a,[rPOSITION2]
	ld		l,a
	call	WAIT_VBLANK

	ld		a,b
	add		$06						; 0 = $06 bg map
	ld		[hl+],a
	ld		a,c
	add		$06
	ld		[hl+],a

	ld		a,h
	ld		[rPOSITION1],a
	ld		a,l
	ld		[rPOSITION2],a

	pop		bc
	pop		de
	pop		hl
	ret





;;; INTERRUPT HANDLER ROUTINES


; Joypad interrupt handler
BTNS:
	push	af
	push	bc
	push	hl

	ld		a,[rP1]
	ld		a,[rP1]
	ld		a,[rP1]

	cpl
	and		$0F
	ld		b,a
	jr		z,no_btns

	ld		a,$3F				;
	ld		[rP1],a				; Set 1s at both P14 and P15 lines (off)


	ld		a,[rSCX_COPY]
	ld		h,a
	ld		a,[rSCY_COPY]
	ld		l,a

	ld		a,b

	cp		$08
	jr		z,down
	cp		$04
	jr		z,up
	cp		$02
	jr		z,dx
	cp		$01
	jr		z,sx
	jr		redraw

up:
	dec		l
	jr		redraw
down:
	inc		l
	jr		redraw
dx:
	dec		h
	jr		redraw
sx:
	inc		h

redraw:
	ld		a,h
	ld		[rSCX_COPY],a
	ld		a,l
	ld		[rSCY_COPY],a

	ld		a,%00000001			;
	ldh		[rIE], a			; enable only VBlank interrupt in order to redraw

	ld		a,$E0				;
	ldh		[rIF], a			; disable all IF

	ei 							; VBlank will occur, interrupt will be handled and screen redrawn correctly
	halt
	nop

no_btns:
	ld		a,$20					;
	ld		[rP1],a					; Set 0 at the output line P15 (Up/Down/Left/Right)

	pop		hl	
	pop		bc
	pop		af
	reti						; return and enable interrupts


; VBlank interrupt handler
DRAW:
	ld		a,[rSCX_COPY]
	ld		[rSCX],a
	ld		a,[rSCY_COPY]
	ld		[rSCY],a

	ld		a,%00010000			;
	ldh		[rIE], a			; joypad only interrupt

	ret						; return from handler w\o enabling interrupts



; Just waste time
WAIT::
	push	bc

	ld		bc,$EF00
wait:
	dec		bc
	ld		a,b
	or		c
	jr  	nz,wait

	pop		bc
	ret



SECTION "Sprites",HOME[$0800]
LETTERS::
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00			; 00 - #\Space
DB $3F,$3F,$20,$20,$20,$20,$3C,$3C,$20,$20,$20,$20,$20,$20,$00,$00			; 01 - #\F
DB $00,$00,$08,$08,$00,$00,$18,$18,$08,$08,$08,$08,$08,$08,$00,$00			; 02 - #\i
DB $7C,$7C,$46,$46,$46,$46,$7C,$7C,$46,$46,$46,$46,$7C,$7C,$00,$00			; 03 - #\B
DB $00,$00,$00,$00,$44,$44,$44,$44,$44,$44,$44,$44,$7C,$7C,$00,$00			; 04 - #\u
DB $00,$00,$00,$00,$7C,$7C,$08,$08,$10,$10,$20,$20,$7C,$7C,$00,$00			; 05 - #\z

NUMBERS::
DB $7E,$7E,$46,$46,$4E,$4E,$56,$56,$66,$66,$46,$46,$7E,$7E,$00,$00			; 06 - 0
DB $38,$38,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$3C,$3C,$00,$00			; 07 - 1
DB $7E,$7E,$06,$06,$06,$06,$7E,$7E,$60,$60,$60,$60,$7E,$7E,$00,$00			; 08 - 2
DB $7E,$7E,$06,$06,$06,$06,$1E,$1E,$06,$06,$06,$06,$7E,$7E,$00,$00			; 09 - 3
DB $60,$60,$60,$60,$60,$60,$66,$66,$7E,$7E,$06,$06,$06,$06,$00,$00			; 0A - 4
DB $7E,$7E,$60,$60,$60,$60,$7E,$7E,$06,$06,$06,$06,$7E,$7E,$00,$00			; 0B - 5
DB $7E,$7E,$60,$60,$60,$60,$7E,$7E,$62,$62,$62,$62,$7E,$7E,$00,$00			; 0C - 6
DB $7E,$7E,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$00,$00			; 0D - 7
DB $7E,$7E,$46,$46,$46,$46,$7E,$7E,$46,$46,$46,$46,$7E,$7E,$00,$00			; 0E - 8
DB $7E,$7E,$46,$46,$46,$46,$7E,$7E,$06,$06,$06,$06,$7E,$7E,$00,$00			; 0F - 9
