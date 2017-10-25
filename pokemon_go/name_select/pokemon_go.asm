	INCLUDE	"includes/Hardware.inc"
	INCLUDE	"includes/Addsub1.inc"

rINPUTS			EQU		$C000
rSELPOS2		EQU		$C001
rSELPOS1		EQU		$C002
LOAD_SHORT		EQU		$C600
LOAD_LONG		EQU		$C500
mWHERE1			EQU		$C606
mWHERE2			EQU		$C605
mWHAT1			EQU		$C609
mWHAT2			EQU		$C608
mCOUNT			EQU		$C60B
mWHERE1_L		EQU		$C506
mWHERE2_L		EQU		$C505
mWHAT1_L		EQU		$C509
mWHAT2_L		EQU		$C508
mCOUNT1_L		EQU		$C50C
mCOUNT2_L		EQU		$C50B

fstLINE			EQU		$9841
sndLINE			EQU		$9881


	SECTION	"V-Blank IRQ Vector",HOME[$40]
VBL_VECT:
	jp		DRAW
	SECTION	"Joypad IRQ Vector",HOME[$60]
JOYPAD_VECT:
	jp		BTNS
	
	SECTION	"Start",HOME[$100]
	nop
	jp		START

; $0104-$0133 (Nintendo logo)
	DB	$CE,$ED,$66,$66,$CC,$0D,$00,$0B,$03,$73,$00,$83,$00,$0C,$00,$0D
	DB	$00,$08,$11,$1F,$88,$89,$00,$0E,$DC,$CC,$6E,$E6,$DD,$DD,$D9,$99
	DB	$BB,$BB,$67,$63,$6E,$0E,$EC,$CC,$DD,$DC,$99,$9F,$BB,$B9,$33,$3E
; $0134-$013E (Game title 11 upper case ASCII characters; pad with $00)
	DB	"POKEMON GO",0
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

	call	WAITERINO
	call	WAITERINO				; I want to see nintendo's logo
	call	WAITERINO

	xor		a
	ld		[rINPUTS],a				; No input so far
	ld		a,$9C
	ld		[rSELPOS2],a
	ld		a,$A1
	ld		[rSELPOS1],a

	call	WAIT_VBLANK
	ld		a,%00000001
	ldh		[rLCDC],a				; turn off LCD

	ld		a,%11100100				; normal palette loading
	ldh		[rBGP],a
	ldh		[rOBP0],a


; Write OAM DMA Transfer instruction to $FF80 
	ld		c,$80
	ld		b,$0A					; # bytes of instructions
	ld		hl,DMADATA
L1:
	ld		a,[hl+]
	ld		[c],a					; ld [c],a			a -> $FF00 + [c]
	inc		c
	dec		b
	jr		nz,L1


; Setup copying-loops
; loop with counter < 1 byte
	call	SELF_COPY
	ld		a,$C6					; adjust loop JUMP
	ld		de,$C612
	ld		[de],a
; loop with counter >= 1 byte
	ld		a,$1B
	ld		[mCOUNT],a
	ld		bc,LONG_COPY
	ld		a,b
	ld		[mWHAT1],a
	ld		a,c
	ld		[mWHAT2],a
	ld		bc,LOAD_LONG
	ld		a,b
	ld		[mWHERE1],a
	ld		a,c
	ld		[mWHERE2],a
	call	LOAD_SHORT				; copy LONG_COPY

	call	LOAD_LONG				; already setup to copy START_TILES
	call	LOAD_REMAINING
	call	LOAD_CHAR_TILES
	call	LOAD_START

	call	LOAD_BOX_TILES
	call	LOAD_BOX_WINDOW


	ld		a,%10001001				;
	ldh		[rLCDC],a				; LCDC On, BG_data from $8800, show SCRN1, BG Display ON

	call	WAITERINO
	call	WAITERINO

	call	WAIT_VBLANK

	ld		a,$60
	ld		[rWY],a
	ld		a,$07
	ld		[rWX],a


	call	WAITERINO

	ld		a,%10101001
	ldh		[rLCDC],a

	call	WAIT_VBLANK
	ld		hl,INTRODUCTION
	call	print_fst_line
	call	WAIT_VBLANK
	ld		hl,INTRODUCTION+$11
	call	print_snd_line
	call	WAIT_VBLANK
	call	print_arrow

HALT_PLS:
	ld		a,%00010000				;
	ldh		[rIE], a				; Joypad interrupt only
	ld		a,$E0					;
	ldh		[rIF], a				; disable all IF
	ld		a,$4F					;
	ld		[rP1],a					; Set 0 at the output line P14
	ei
	halt
	nop
	ld		a,[rINPUTS]
	and		$10
	jr		z,HALT_PLS

	call	WAIT_VBLANK
	call	rem_text

	call	WAIT_VBLANK
	ld		a,%00000001
	ldh		[rLCDC],a				; turn off LCD
	call	LOAD_NAME_SELECTION
	ld		a,%10001001
	ldh		[rLCDC],a

NAME_LOOP:
	ld		a,%00010000				;
	ldh		[rIE], a				; Joypad interrupt only
	ld		a,$2F				;
	ld		[rP1],a				; Set 0 at the output line P15 (Up/Down/Left/Right)
	xor		a
	ld		[rINPUTS],a
	ld		a,$E0					;
	ldh		[rIF], a				; disable all IF
	ei
	halt
	nop
	ld		a,[rSELPOS1]
	ld		e,a
	ld		a,[rSELPOS2]
	ld		d,a
	call	WAIT_VBLANK
	call	rem_arrow
	sub16ir	de,$00A1
	ld		a,d
	sub		$9C
	ld		d,a
	ld		a,[rINPUTS]
;	Start	|	Select	|	B	|	A	|	Down	|	Up	|	Sx	|	Dx	|
	and		$0F
	cp		$08
	jp		z,down
	cp		$04
	jp		z,up
	cp		$02
	jp		z,sx
	cp		$01
	jp		z,dx
	and		$03
	cp		$02
	jp		z,sx
	jp		dx
	ld		a,[rINPUTS]
	and		$0C
	cp		$08
	jp		z,down
	jp		up

down:
	ld		a,d
	or		$00
	jp		nz,special_down
	add16ir	de,$40
	jp		end
special_down:
	ld		a,e
	cp		$40
	jp		nz,to_case
	xor		a
	ld		d,a
	ld		e,a
	jp		end

to_case:
	ld		a,$40
	ld		e,a
	jp		end

up:
	ld		a,d
	or		$00
	jp		nz,up_2
	ld		a,e
	cp		$11
	jp		c,special_up
up_2:
	sub16ir	de,$40
	jp		end
special_up:
	ld		de,$0140
	jp		end

sx:
	ld		a,d
	cp		$01
	jp		z,sx_2
	ld		a,e
	and		$1F
	jp		z,special_sx
	sub16ir	de,$02
	jp		end
special_sx:
	add16ir	de,$10
	jp		end
sx_2:
	ld		a,e
	cp		$40
	jp		nz,end
	jp		to_case

dx:
	ld		a,d
	cp		$01
	jp		z,dx_2
	ld		a,e
	and		$1F
	cp		$10
	jp		z,special_dx
	add16ir	de,$02
	jp		end
special_dx:
	sub16ir	de,$10
	jp		end

dx_2:
	ld		a,e
	cp		$40
	jp		nz,end
	jp		to_case

end:
	add16ir de,$9CA1
	ld		a,d
	ld		[rSELPOS2],a
	ld		a,e
	ld		[rSELPOS1],a
	call	WAIT_VBLANK
	call	move_arrow
	jp		NAME_LOOP


rem_arrow:
	xor		a
	ld		[de],a
	ret

move_arrow:
	ld		a,$DA
	ld		[de],a
	ret






















	call	WAIT_VBLANK
	ld		hl,STRINGS
	call	print_fst_line

	call	WAIT_VBLANK
	ld		hl,STRINGS+$11
	call	print_snd_line
	call	WAIT_VBLANK
	call	print_arrow


HALT_PLS_2:
	ld		a,%00010000				;
	ldh		[rIE], a				; Joypad interrupt only
	ld		a,$E0					;
	ldh		[rIF], a				; disable all IF
	ei
	halt
	nop
	ld		a,[rINPUTS]
	and		$10
	jr		z,HALT_PLS_2

	call	WAIT_VBLANK
	call	rem_text

	call	WAIT_VBLANK
	ld		hl,STRINGS+$22
	call	print_fst_line

	call	WAIT_VBLANK
	ld		hl,STRINGS+$33
	call	print_snd_line

hang:
	xor		a						;
	ldh		[rIE], a				; no interrupts
	ld		a,$E0					;
	ldh		[rIF], a				; disable all IF
	ei
	halt
	nop



;******************************************************
;* SUBROUTINES



print_fst_line::
	ld		de,fstLINE
	jp		print_line

print_snd_line::
	ld		de,sndLINE
	jp		print_line


print_line::
	ld		b,$11
print_line_loop:
	call	DELAY5
	ld		a,[hl+]
	ld		[de],a
	inc		de
	dec		b
	jr		nz,print_line_loop
	ret


print_arrow::
	ld		de,$9892 ;arrow position
	ld		a,$D9
	ld		[de],a
	ret

rem_text::
	push	bc
	push	de
	ld		de,fstLINE
	ld		c,$02
rem_text_loop_2:
	ld		b,$12
rem_text_loop_1:
	xor		a
	ld		[de],a
	inc		de
	dec		b
	jr		nz,rem_text_loop_1
	ld		a,e
	add		a,$2E					; go to second line start
	ld		e,a
	dec		c
	jr		nz,rem_text_loop_2
	pop		de
	pop		bc
	ret


; Just waste time
WAITERINO::
	push	bc
	ld		bc,$EF00
wait:
	dec		bc
	ld		a,b
	or		c
	jr  	nz,wait
	pop		bc
	ret

WAIT_HBLANK::
	ld		a,[rSTAT]
	cp		$80
	jp		nz,WAIT_HBLANK
	ret



LOAD_START::
	ld		bc,START_MAP
	ld		a,b
	ld		[mWHAT1_L],a
	ld		a,c
	ld		[mWHAT2_L],a
	ld		bc,_SCRN1
	ld		a,b
	ld		[mWHERE1_L],a
	ld		a,c
	ld		[mWHERE2_L],a
	ld		bc,$0240
	ld		a,b
	ld		[mCOUNT1_L],a
	ld		a,c
	ld		[mCOUNT2_L],a
	jp		LOAD_LONG

LOAD_NAME_SELECTION::
	ld		bc,NAME_SELECTION_MAP
	ld		a,b
	ld		[mWHAT1_L],a
	ld		a,c
	ld		[mWHAT2_L],a
	ld		bc,_SCRN1
	ld		a,b
	ld		[mWHERE1_L],a
	ld		a,c
	ld		[mWHERE2_L],a
	ld		bc,$0240
	ld		a,b
	ld		[mCOUNT1_L],a
	ld		a,c
	ld		[mCOUNT2_L],a
	jp		LOAD_LONG

LOAD_BOX_WINDOW::
	ld		bc,BOX_MAP
	ld		a,b
	ld		[mWHAT1_L],a
	ld		a,c
	ld		[mWHAT2_L],a
	ld		bc,_SCRN0
	ld		a,b
	ld		[mWHERE1_L],a
	ld		a,c
	ld		[mWHERE2_L],a
	ld		bc,$00B4
	ld		a,b
	ld		[mCOUNT1_L],a
	ld		a,c
	ld		[mCOUNT2_L],a
	jp		LOAD_LONG

LOAD_BOX_TILES::
	ld		bc,BOX_TILES
	ld		a,b
	ld		[mWHAT1],a
	ld		a,c
	ld		[mWHAT2],a
	ld		bc,$8830
	ld		a,b
	ld		[mWHERE1],a
	ld		a,c
	ld		[mWHERE2],a
	ld		a,$70
	ld		[mCOUNT],a
	jp		LOAD_SHORT

LOAD_CHAR_TILES::
	ld		bc,CHARSET
	ld		a,b
	ld		[mWHAT1_L],a
	ld		a,c
	ld		[mWHAT2_L],a
	ld		bc,$88A0
	ld		a,b
	ld		[mWHERE1_L],a
	ld		a,c
	ld		[mWHERE2_L],a
	ld		bc,$530
	ld		a,b
	ld		[mCOUNT1_L],a
	ld		a,c
	ld		[mCOUNT2_L],a
	jp		LOAD_LONG

; Load remaining start
LOAD_REMAINING::
	ld		bc,START_TILES+$0800
	ld		a,b
	ld		[mWHAT1],a
	ld		a,c
	ld		[mWHAT2],a
	ld		bc,$8800
	ld		a,b
	ld		[mWHERE1],a
	ld		a,c
	ld		[mWHERE2],a
	ld		a,$30
	ld		[mCOUNT],a
	jp		LOAD_SHORT






;******************************************************
; VBlank interrupt handler
DRAW::
	call	$FF80				; OAM DMA TRANSFER
	ret


;******************************************************************************
; Joypad interrupt handler
BTNS::
	push	af
	push	bc

	ld		a,$2F					;
	ld		[rP1],a					; Set 0 at the output line P14 (Up/Down/Left/Right)
	ld		a,[rP1]
	ld		a,[rP1]
	
	cpl
	and		$0F
	swap	a
	ld		b,a

	ld		a,$1F
	ld		[rP1],a
	ld		a,[rP1]
	ld		a,[rP1]
	ld		a,[rP1]
	ld		a,[rP1]
	ld		a,[rP1]
	ld		a,[rP1]

	cpl
	and		$0F
	or		b
	swap	a
	jp		nz,store
	ld		a,[rINPUTS]
store:
	ld		[rINPUTS],a

	ld		a,$30
	ld		[rP1],a

	pop		bc
	pop		af
	ret





SECTION "MyCode",HOME[$0700]

; Loop for counter =< 1byte - self-copying at first run
SELF_COPY::
					  ;where ;     ; self;     ;#;
DB $F5,$C5,$D5,$E5,$11,$00,$C6,$21,$00,$07,$06,$18,$2A,$12,$13,$05
DB $C2,$0C,$07,$E1,$D1,$C1,$F1,$C9

LONG_COPY::
; we will write this to $C500
; Already setup to write START_TILES ($2000) to _MAP_VRAM ($9000)
                       ;where;     ;what ;     ;count;
DB $F5,$C5,$D5,$E5,$11,$00,$90,$21,$00,$20,$01,$00,$08,$2A,$12,$13
DB $0B,$78,$B1,$C2,$0D,$C5,$E1,$D1,$C1,$F1,$C9

WAIT_VBLANK::
	ldh		a,[rLY]
	cp		$91
	jr		nz,WAIT_VBLANK
	ret

DELAY5::
	call	WAIT_VBLANK
	call	WAIT_VBLANK
	call	WAIT_VBLANK
	call	WAIT_VBLANK
	call	WAIT_VBLANK
	ret


SECTION "DmaTransfer",HOME[$0800]
DMADATA::
DB $3E,$D0,$E0,$46,$3E,$28,$3D,$20,$FD,$C9
; 3ED0		:	ld	a,$D0
; E046		:	ld	[rDMA],a
; 3E28		:	ld	a,$28
; L1:
; 3D		:	dec	a
; 20FD		:	jr	nz,L1
; C9		:	ret


SECTION "Map",HOME[$0A00]

START_MAP:
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$02,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$03,$04,$05,$06,$07,$08,$09,$0A,$0B,$0C,$0D,$00,$0E
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$0F,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$1A,$1B,$1C
DB $1D,$1E,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$1F,$20,$21,$22,$23,$24,$25,$26,$27,$28,$29,$2A,$2B,$2C
DB $2D,$2E,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$2F,$30,$31,$32,$33,$34,$35,$36,$37,$38,$39,$3A,$3B,$3C
DB $3D,$3E,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$3F,$40,$41,$42,$43,$44,$45,$46,$47,$48,$49,$4A,$4B
DB $4C,$4D,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$4E,$4F,$50,$51,$52,$53,$54,$55,$56,$57,$58,$59,$5A
DB $5B,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$5C,$5D,$5E,$5F,$60,$61,$62,$63,$64,$65,$00
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$66,$67,$68,$69,$6A,$6B,$6C,$6D,$6E,$6F,$00
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$70,$71,$72,$73,$74,$75,$76,$77,$78,$79,$00
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$7A,$7B,$7C,$7D,$7E,$7F,$80,$81,$82,$00
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00


BOX_MAP:
DB $83,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84
DB $84,$84,$84,$85,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83
DB $86,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87
DB $87,$87,$87,$86,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83
DB $86,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87
DB $87,$87,$87,$86,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83
DB $86,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87
DB $87,$87,$87,$86,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83
DB $86,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87
DB $87,$87,$87,$86,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83
DB $88,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84
DB $84,$84,$84,$89


NAME_SELECTION_MAP:
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; blank
DB $BC,$B2,$B8,$B5,$00,$B1,$A4,$B0,$A8,$D1,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; YOUR NAME?
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; blank
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$DB,$DC,$DC,$DC,$DC,$DC
DB $DC,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; name
DB $83,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84
DB $84,$84,$84,$85,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; cornice
DB $86,$DA,$A4,$00,$A5,$00,$A6,$00,$A7,$00,$A8,$00,$A9,$00,$AA,$00
DB $AB,$00,$AC,$86,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; arrow->A-I
DB $86,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$86,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; blank
DB $86,$00,$AD,$00,$AE,$00,$AF,$00,$B0,$00,$B1,$00,$B2,$00,$B3,$00
DB $B4,$00,$B5,$86,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; J-R
DB $86,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$86,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; blank
DB $86,$00,$B6,$00,$B7,$00,$B8,$00,$B9,$00,$BA,$00,$BB,$00,$BC,$00
DB $BD,$00,$00,$86,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; S-Z
DB $86,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$86,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; blank
DB $86,$00,$00,$00,$C8,$00,$C9,$00,$CA,$00,$CB,$00,$CC,$00,$CD,$00
DB $CE,$00,$CF,$86,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; special1
DB $86,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$86,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; blank
DB $86,$00,$D0,$00,$D1,$00,$D2,$00,$D3,$00,$D4,$00,$D5,$00,$D6,$00
DB $D7,$00,$D8,$86,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; special2
DB $88,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84
DB $84,$84,$84,$89,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; cornice
DB $00,$00,$95,$98,$A0,$8E,$9B,$00,$8C,$8A,$9C,$8E,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; lower case
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; blank
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; blank

DB $86,$00,$8A,$00,$8B,$00,$8C,$00,$8D,$00,$8E,$00,$8F,$00,$90,$00
DB $91,$00,$92,$86,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; a-i
DB $86,$00,$93,$00,$94,$00,$95,$00,$96,$00,$97,$00,$98,$00,$99,$00
DB $9A,$00,$9B,$86,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; j-r
DB $86,$00,$9C,$00,$9D,$00,$9E,$00,$9F,$00,$A0,$00,$A1,$00,$A2,$00
DB $A3,$00,$00,$86,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; s-z
DB $00,$B8,$B3,$B3,$A8,$B5,$00,$A6,$A4,$B6,$A8,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; UPPER CASE


STRINGS:
; Our servers are--
DB $B2,$9E,$9B,$00,$9C,$8E,$9B,$9F,$8E,$9B,$9C,$00,$8A,$9B,$8E,$00,$00
; experiencing-----
DB $8E,$A1,$99,$8E,$9B,$92,$8E,$97,$8C,$92,$97,$90,$00,$00,$00,$00,$00
; issues. Please---
DB $92,$9C,$9C,$9E,$8E,$9C,$D6,$00,$B3,$95,$8E,$8A,$9C,$8E,$00,$00,$00
; come back later.-
DB $8C,$98,$96,$8E,$00,$8B,$8A,$8C,$94,$00,$95,$8A,$9D,$8E,$9B,$D6,$00
INTRODUCTION:
; Press A to choose
DB $B3,$9B,$8E,$9C,$9C,$00,$A4,$00,$9D,$98,$00,$8C,$91,$98,$98,$9C,$8E
; your name!-------
DB $A2,$98,$9E,$9B,$00,$97,$8A,$96,$8E,$D2,$00,$00,$00,$00,$00,$00,$00


SECTION "Tiles", HOME[$2000]

START_TILES:
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$00,$02,$03,$03,$07,$07,$0F,$1E,$0D
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80,$00,$80,$80,$80,$C0
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$06,$01,$07,$1F,$BE,$7F
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$38,$FF,$FF,$FF,$7C,$83
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80,$00,$C0,$E0,$E8,$F0
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$01,$01
DB $00,$00,$00,$00,$00,$00,$00,$00,$05,$03,$2F,$1F,$7C,$FF,$EF,$F0
DB $00,$00,$00,$00,$00,$00,$E8,$04,$E4,$CE,$FE,$CF,$EB,$DF,$5F,$F9
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$03,$01,$02,$81,$C0,$C3
DB $3F,$18,$7F,$30,$7F,$60,$DD,$E3,$B7,$CF,$9C,$FF,$F8,$FF,$FF,$FF
DB $E0,$C0,$F0,$60,$70,$E0,$A0,$C0,$00,$80,$42,$81,$41,$83,$C3,$83
DB $00,$00,$00,$00,$00,$00,$00,$00,$03,$01,$03,$FF,$FF,$FF,$7B,$87
DB $00,$00,$00,$00,$00,$00,$00,$00,$FE,$FC,$FC,$FE,$FC,$86,$FE,$86
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$10,$E0,$7B,$FC
DB $02,$01,$0B,$07,$0E,$1F,$3B,$1C,$0B,$1C,$2D,$1E,$07,$7E,$86,$7F
DB $F7,$F8,$BF,$C0,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00
DB $FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$E0,$1F,$EF,$1F,$FF,$0F
DB $BC,$78,$EE,$1C,$F6,$0E,$FE,$07,$FA,$07,$FF,$03,$FF,$83,$FF,$C3
DB $01,$01,$01,$01,$05,$03,$00,$07,$00,$07,$80,$07,$80,$07,$B4,$0F
DB $FF,$80,$FF,$80,$FF,$E0,$FF,$E0,$FF,$E0,$2F,$F0,$2F,$F0,$2F,$F0
DB $7F,$F0,$6F,$F0,$5F,$E0,$7F,$C0,$3F,$C0,$FF,$00,$FF,$00,$FF,$01
DB $F7,$E3,$B7,$7F,$DD,$3E,$DB,$3C,$F7,$38,$FF,$70,$EF,$F0,$EF,$F0
DB $C1,$FF,$7F,$80,$FF,$00,$C3,$3C,$BF,$7C,$7F,$F8,$F7,$F8,$BE,$C1
DB $F3,$E3,$FF,$73,$D2,$3F,$FE,$1F,$DE,$3F,$B7,$7E,$67,$FE,$EF,$F6
DB $FF,$03,$FD,$03,$FD,$03,$FF,$01,$FE,$01,$FF,$00,$FF,$00,$FF,$00
DB $FE,$86,$FE,$06,$FF,$06,$FA,$07,$FE,$03,$FF,$03,$FF,$03,$FF,$03
DB $00,$00,$00,$00,$00,$03,$00,$03,$00,$03,$30,$0F,$BF,$7F,$EF,$F0
DB $7F,$FF,$7C,$C3,$7F,$C0,$6F,$F0,$6F,$F0,$2F,$F0,$EF,$F0,$6F,$F0
DB $90,$E0,$F5,$F2,$FB,$37,$DA,$37,$DD,$3E,$FD,$1E,$FF,$1C,$FF,$1C
DB $00,$00,$80,$00,$D8,$E0,$FD,$FE,$E7,$1E,$FC,$06,$F4,$0E,$FE,$0C
DB $03,$7F,$41,$3F,$01,$3F,$20,$1F,$10,$0F,$00,$0F,$08,$07,$00,$07
DB $FF,$00,$2F,$F0,$FF,$F0,$F7,$F8,$1F,$F8,$1B,$FC,$0F,$FC,$0F,$FC
DB $F7,$0F,$FE,$01,$FF,$00,$FF,$00,$FF,$00,$FE,$01,$FF,$00,$FF,$00
DB $DF,$E3,$DF,$E3,$5B,$E7,$7F,$C7,$F7,$8E,$EF,$1C,$DB,$3C,$BF,$78
DB $BF,$7F,$DF,$E0,$FF,$80,$E7,$18,$DF,$30,$FF,$30,$FF,$38,$DF,$3F
DB $EF,$F0,$7F,$F0,$D7,$38,$FF,$18,$EB,$1C,$FF,$0C,$F7,$8C,$F7,$8C
DB $FD,$03,$FE,$07,$F6,$0F,$FB,$07,$FF,$00,$FF,$00,$FF,$00,$9F,$60
DB $7F,$E0,$7F,$E0,$FF,$60,$EF,$F0,$7F,$F0,$DF,$38,$FB,$1C,$FF,$0F
DB $FD,$83,$7B,$87,$F7,$0E,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$7E,$81
DB $F7,$FE,$5D,$BE,$ED,$1E,$F7,$0F,$FE,$07,$ED,$1E,$DF,$3C,$FB,$FC
DB $FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$E7,$18,$EF,$18,$EB,$1C
DB $FD,$03,$FF,$03,$FB,$07,$FF,$06,$B5,$4E,$FF,$4C,$FF,$4C,$5F,$EC
DB $BF,$C0,$E7,$18,$DF,$30,$FF,$30,$F7,$38,$DF,$3F,$FF,$1F,$F1,$0E
DB $D7,$38,$FF,$18,$EB,$1C,$7B,$8C,$FF,$8C,$F7,$8C,$FF,$0C,$FB,$0C
DB $EF,$1C,$EB,$1C,$FF,$08,$FF,$08,$F7,$08,$FF,$00,$FF,$00,$FF,$00
DB $FC,$0C,$E8,$1C,$FC,$18,$F8,$18,$D0,$38,$F8,$30,$F0,$30,$A0,$70
DB $04,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $87,$7E,$07,$7E,$02,$7F,$03,$3F,$03,$3F,$21,$1F,$01,$1F,$10,$0F
DB $FF,$00,$FE,$01,$FF,$01,$FE,$01,$7F,$80,$FF,$80,$BF,$C0,$FF,$C0
DB $7F,$F8,$CF,$F8,$8F,$F8,$8B,$FC,$CF,$FC,$C5,$FE,$C6,$FF,$43,$FF
DB $FF,$1F,$F1,$0E,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$BD,$C3
DB $F7,$0C,$FF,$0C,$EB,$1C,$FF,$18,$DF,$38,$BF,$78,$7F,$F8,$DF,$F8
DB $F7,$78,$FD,$7E,$EF,$7F,$E3,$7F,$E0,$7F,$E0,$7F,$E0,$7F,$F0,$6F
DB $FB,$07,$FE,$01,$7F,$80,$FF,$C0,$77,$F8,$1D,$FE,$07,$FF,$03,$FF
DB $FF,$FF,$FF,$FF,$F0,$3F,$D0,$3F,$D0,$3F,$D1,$3E,$58,$B0,$F8,$F0
DB $DB,$FC,$1F,$F8,$1F,$F8,$1C,$FF,$0F,$FF,$00,$7F,$00,$7F,$80,$7F
DB $EF,$1C,$FD,$1E,$F7,$1F,$53,$BF,$F1,$FF,$11,$FF,$00,$FF,$00,$DF
DB $DF,$EC,$FD,$EE,$F5,$EE,$FE,$E7,$FB,$E7,$7D,$E3,$7F,$E0,$7F,$E0
DB $FF,$00,$FF,$00,$FF,$00,$FF,$00,$3E,$C1,$FF,$FF,$FE,$FF,$E0,$7F
DB $EF,$18,$FF,$18,$FF,$30,$AE,$71,$DE,$E1,$FF,$C1,$FF,$C1,$FF,$C1
DB $7F,$80,$7F,$80,$FF,$80,$FF,$80,$FF,$80,$FE,$81,$FE,$81,$FF,$81
DB $F0,$60,$E0,$60,$40,$E0,$E0,$C0,$C0,$C0,$80,$C0,$C0,$80,$80,$80
DB $00,$0F,$08,$07,$00,$07,$00,$07,$00,$03,$00,$03,$02,$01,$00,$01
DB $FF,$C0,$7F,$E0,$7F,$E0,$2F,$F0,$3F,$F0,$16,$F9,$1F,$FF,$1E,$FF
DB $E1,$7F,$E0,$7F,$A0,$7F,$A0,$7F,$F8,$37,$F8,$F3,$C8,$F0,$40,$80
DB $FF,$FF,$7C,$FF,$00,$FF,$00,$FF,$01,$FE,$04,$F8,$F0,$00,$00,$00
DB $09,$FF,$0F,$FF,$00,$FF,$00,$FF,$00,$7F,$00,$7F,$0C,$70,$00,$00
DB $F4,$E3,$F1,$E0,$40,$80,$40,$80,$40,$80,$40,$80,$00,$00,$00,$00
DB $00,$FF,$00,$FF,$40,$3F,$10,$0F,$04,$03,$01,$00,$00,$00,$00,$00
DB $78,$F0,$10,$F8,$38,$C0,$20,$C0,$20,$C0,$00,$E0,$60,$00,$00,$00
DB $00,$7F,$1C,$03,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$CF,$00,$C5,$00,$01,$00,$01,$00,$01,$01,$00,$00,$00,$00,$00
DB $7F,$FF,$3F,$FF,$00,$FF,$00,$FF,$00,$FF,$80,$7F,$06,$01,$00,$00
DB $E0,$FF,$E0,$FF,$00,$FF,$70,$83,$40,$83,$40,$83,$43,$80,$00,$00
DB $DD,$E3,$FF,$FF,$07,$FF,$01,$FF,$01,$FF,$01,$FF,$00,$FF,$08,$07
DB $FD,$83,$FD,$83,$FF,$83,$FA,$87,$FB,$86,$E6,$FE,$3C,$FE,$06,$FC
DB $00,$80,$80,$00,$00,$00,$00,$00,$F1,$F1,$5B,$5B,$55,$55,$51,$51
DB $01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $0C,$FF,$00,$FF,$80,$7F,$01,$7E,$48,$30,$00,$00,$00,$00,$00,$00
DB $00,$C0,$20,$C0,$20,$C0,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$03,$03,$0C,$0C,$10,$10,$21,$21,$47,$47,$8F,$8F
DB $1F,$1F,$E0,$E0,$00,$00,$1F,$1F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FD
DB $E0,$E0,$1C,$1C,$03,$03,$E0,$E0,$FC,$FC,$FE,$FE,$FF,$F7,$FF,$FF
DB $00,$00,$00,$00,$00,$00,$C0,$C0,$20,$20,$10,$10,$88,$88,$C4,$C4
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$02,$02,$04,$04
DB $00,$00,$07,$07,$18,$18,$60,$60,$87,$87,$0F,$0F,$3F,$3F,$7F,$7F
DB $FF,$FF,$00,$00,$00,$00,$FF,$FF,$FF,$EF,$FF,$FF,$FF,$FF,$FF,$FF
DB $00,$00,$E0,$E0,$18,$18,$06,$06,$E1,$E1,$F0,$F0,$FC,$FC,$FE,$FE
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80,$80,$40,$40,$20,$20
DB $08,$07,$08,$07,$04,$03,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $04,$F8,$00,$F8,$00,$F8,$C8,$30,$00,$00,$00,$00,$00,$00,$00,$00
DB $01,$01,$01,$01,$02,$02,$02,$02,$04,$04,$04,$04,$04,$04,$09,$09
DB $1F,$1F,$3F,$3F,$3F,$3F,$7F,$77,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
DB $FF,$FF,$FF,$BF,$FF,$FF,$F0,$F0,$C0,$C0,$87,$87,$1C,$1C,$3D,$3D
DB $FF,$FF,$FF,$FF,$FF,$FF,$3F,$3F,$0E,$0E,$C5,$C5,$00,$00,$FF,$FF
DB $E8,$E8,$D0,$D0,$A0,$A0,$40,$40,$80,$80,$FF,$FF,$00,$00,$FE,$FE
DB $08,$08,$09,$09,$11,$11,$13,$13,$27,$27,$A7,$A7,$A7,$A7,$CF,$CF
DB $FF,$FF,$FF,$FF,$FF,$DF,$FF,$FF,$FE,$FE,$FC,$FC,$F8,$F8,$F9,$F9
DB $FF,$FF,$FF,$7F,$FF,$FF,$81,$81,$00,$00,$3C,$3C,$C3,$FF,$00,$FF
DB $FF,$FF,$FF,$DF,$FF,$FF,$FF,$FF,$7F,$7F,$3F,$3F,$1F,$1F,$9F,$9B
DB $10,$10,$90,$90,$88,$88,$C8,$C8,$E4,$E4,$E4,$E4,$E4,$E4,$F2,$F2
DB $09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$08,$08,$04,$04
DB $FF,$FF,$FE,$FE,$FE,$F6,$FE,$FE,$F8,$F8,$80,$87,$00,$7F,$00,$FF
DB $3D,$3D,$7D,$7D,$7C,$7C,$7C,$7D,$7C,$7D,$3C,$3C,$3F,$3F,$1F,$1F
DB $FF,$F7,$FF,$7F,$00,$00,$00,$FF,$00,$FF,$00,$01,$F0,$F3,$E0,$E3
DB $FE,$FE,$FE,$F6,$00,$00,$00,$FE,$00,$FE,$00,$FE,$00,$FE,$00,$FC
DB $4F,$4F,$4F,$4F,$40,$40,$40,$4F,$40,$4F,$40,$4F,$40,$4F,$A0,$A7
DB $F1,$B1,$F2,$F3,$03,$03,$02,$F2,$02,$F2,$01,$F1,$01,$F9,$00,$F8
DB $00,$FF,$18,$FF,$E7,$E7,$24,$24,$18,$18,$00,$00,$00,$00,$C3,$C3
DB $9F,$9F,$4F,$CF,$CF,$CF,$4F,$4F,$43,$43,$80,$9C,$80,$9F,$00,$1F
DB $F2,$F2,$F2,$F2,$F2,$F2,$F2,$F2,$F2,$F2,$32,$32,$02,$C2,$04,$E4
DB $04,$04,$04,$04,$02,$02,$02,$02,$01,$01,$01,$01,$00,$00,$00,$00
DB $00,$FF,$00,$FF,$00,$7F,$00,$3F,$00,$3F,$00,$1F,$80,$8F,$40,$47
DB $07,$87,$00,$C0,$00,$F8,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF
DB $80,$87,$00,$0F,$00,$7F,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF
DB $00,$FC,$00,$FC,$01,$F9,$01,$F1,$02,$F2,$02,$E2,$04,$C4,$08,$88
DB $A0,$A7,$A0,$A7,$10,$13,$10,$11,$08,$09,$08,$08,$04,$04,$02,$02
DB $00,$FC,$00,$FE,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$7F,$00,$3F
DB $3C,$3C,$00,$00,$00,$C3,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF
DB $00,$3F,$00,$7F,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FE,$00,$FC
DB $04,$E4,$04,$E4,$08,$C8,$08,$88,$10,$90,$10,$10,$20,$20,$40,$40
DB $20,$21,$10,$10,$0C,$0C,$03,$03,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$FF,$00,$FF,$00,$1F,$00,$00,$E0,$E0,$1F,$1F,$00,$00,$00,$00
DB $00,$FE,$00,$FC,$00,$E0,$03,$03,$1C,$1C,$E0,$E0,$00,$00,$00,$00
DB $10,$10,$20,$20,$C0,$C0,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$0F,$80,$87,$60,$60,$18,$18,$07,$07,$00,$00,$00,$00,$00,$00
DB $00,$FF,$00,$FF,$00,$FF,$00,$00,$00,$00,$FF,$FF,$00,$00,$00,$00
DB $00,$F0,$01,$E1,$06,$06,$18,$18,$E0,$E0,$00,$00,$00,$00,$00,$00
DB $80,$80,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00


BOX_TILES:
DB $00,$00,$18,$18,$2D,$2D,$7E,$7E,$42,$42,$25,$25,$1A,$1A,$14,$14
DB $00,$00,$00,$00,$FF,$FF,$00,$00,$FF,$FF,$FF,$FF,$00,$00,$00,$00
DB $00,$00,$18,$18,$AC,$AC,$7E,$7E,$42,$42,$A4,$A4,$58,$58,$28,$28
DB $28,$28,$28,$28,$28,$28,$28,$28,$28,$28,$28,$28,$28,$28,$28,$28
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $14,$14,$1A,$1A,$2D,$2D,$7E,$7E,$42,$42,$25,$25,$18,$18,$00,$00
DB $28,$28,$58,$58,$AC,$AC,$7E,$7E,$42,$42,$A4,$A4,$18,$18,$00,$00


CHARSET:
DB $00,$00,$00,$00,$38,$38,$04,$04,$3C,$3C,$44,$44,$3E,$3E,$00,$00 ; a
DB $40,$40,$40,$40,$40,$40,$7C,$7C,$42,$42,$42,$42,$7C,$7C,$00,$00 ; b
DB $00,$00,$00,$00,$3C,$3C,$42,$42,$40,$40,$42,$42,$3C,$3C,$00,$00 ; c
DB $02,$02,$02,$02,$02,$02,$3E,$3E,$42,$42,$42,$42,$3E,$3E,$00,$00 ; d
DB $00,$00,$00,$00,$3C,$3C,$42,$42,$7E,$7E,$40,$40,$3E,$3E,$00,$00 ; e
DB $0C,$0C,$12,$12,$10,$10,$7E,$7E,$10,$10,$10,$10,$10,$10,$00,$00 ; f
DB $00,$00,$00,$00,$3E,$3E,$42,$42,$42,$42,$3E,$3E,$02,$02,$7C,$7C ; g
DB $40,$40,$40,$40,$40,$40,$78,$78,$44,$44,$44,$44,$44,$44,$00,$00 ; h
DB $00,$00,$10,$10,$00,$00,$10,$10,$10,$10,$10,$10,$10,$10,$00,$00 ; i
DB $00,$00,$08,$08,$00,$00,$08,$08,$08,$08,$08,$08,$08,$08,$30,$30 ; j
DB $40,$40,$40,$40,$46,$46,$58,$58,$60,$60,$58,$58,$46,$46,$00,$00 ; k
DB $10,$10,$10,$10,$10,$10,$10,$10,$10,$10,$10,$10,$10,$10,$00,$00 ; l
DB $00,$00,$00,$00,$EC,$EC,$92,$92,$92,$92,$92,$92,$92,$92,$00,$00 ; m
DB $00,$00,$00,$00,$3C,$3C,$22,$22,$22,$22,$22,$22,$22,$22,$00,$00 ; n
DB $00,$00,$00,$00,$3C,$3C,$42,$42,$42,$42,$42,$42,$3C,$3C,$00,$00 ; o
DB $00,$00,$00,$00,$7C,$7C,$42,$42,$42,$42,$7C,$7C,$40,$40,$40,$40 ; p
DB $00,$00,$00,$00,$3E,$3E,$42,$42,$42,$42,$3E,$3E,$02,$02,$02,$02 ; q
DB $00,$00,$00,$00,$4E,$4E,$50,$50,$60,$60,$40,$40,$40,$40,$00,$00 ; r
DB $00,$00,$00,$00,$3C,$3C,$40,$40,$3C,$3C,$02,$02,$7C,$7C,$00,$00 ; s
DB $00,$00,$10,$10,$7C,$7C,$10,$10,$10,$10,$10,$10,$0C,$0C,$00,$00 ; t
DB $00,$00,$00,$00,$44,$44,$44,$44,$44,$44,$44,$44,$3C,$3C,$00,$00 ; u
DB $00,$00,$00,$00,$44,$44,$44,$44,$44,$44,$28,$28,$10,$10,$00,$00 ; v
DB $00,$00,$00,$00,$82,$82,$92,$92,$92,$92,$AA,$AA,$44,$44,$00,$00 ; w
DB $00,$00,$00,$00,$C4,$C4,$28,$28,$10,$10,$28,$28,$46,$46,$00,$00 ; x
DB $00,$00,$00,$00,$44,$44,$44,$44,$44,$44,$3C,$3C,$04,$04,$78,$78 ; y
DB $00,$00,$00,$00,$7E,$7E,$04,$04,$18,$18,$20,$20,$7E,$7E,$00,$00 ; z
DB $10,$10,$28,$28,$28,$28,$44,$44,$7C,$7C,$82,$82,$82,$82,$00,$00 ; A
DB $F8,$F8,$84,$84,$84,$84,$FC,$FC,$82,$82,$82,$82,$FC,$FC,$00,$00 ; B
DB $3C,$3C,$42,$42,$80,$80,$80,$80,$80,$80,$42,$42,$3C,$3C,$00,$00 ; C
DB $F8,$F8,$84,$84,$82,$82,$82,$82,$82,$82,$84,$84,$F8,$F8,$00,$00 ; D
DB $FE,$FE,$80,$80,$80,$80,$FC,$FC,$80,$80,$80,$80,$FE,$FE,$00,$00 ; E
DB $FE,$FE,$80,$80,$80,$80,$FC,$FC,$80,$80,$80,$80,$80,$80,$00,$00 ; F
DB $3C,$3C,$42,$42,$80,$80,$9E,$9E,$82,$82,$42,$42,$3C,$3C,$00,$00 ; G
DB $82,$82,$82,$82,$82,$82,$FE,$FE,$82,$82,$82,$82,$82,$82,$00,$00 ; H
DB $7C,$7C,$10,$10,$10,$10,$10,$10,$10,$10,$10,$10,$7C,$7C,$00,$00 ; I
DB $7E,$7E,$08,$08,$08,$08,$08,$08,$88,$88,$88,$88,$70,$70,$00,$00 ; J
DB $84,$84,$88,$88,$90,$90,$B0,$B0,$C8,$C8,$84,$84,$82,$82,$00,$00 ; K
DB $80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$FE,$FE,$00,$00 ; L
DB $82,$82,$C6,$C6,$AA,$AA,$92,$92,$82,$82,$82,$82,$82,$82,$00,$00 ; M
DB $82,$82,$C2,$C2,$A2,$A2,$92,$92,$8A,$8A,$86,$86,$82,$82,$00,$00 ; N
DB $38,$38,$44,$44,$82,$82,$82,$82,$82,$82,$44,$44,$38,$38,$00,$00 ; O
DB $FC,$FC,$82,$82,$82,$82,$FC,$FC,$80,$80,$80,$80,$80,$80,$00,$00 ; P
DB $38,$38,$44,$44,$82,$82,$82,$82,$8A,$8A,$44,$44,$3A,$3A,$00,$00 ; Q
DB $FC,$FC,$82,$82,$82,$82,$FC,$FC,$88,$88,$84,$84,$82,$82,$00,$00 ; R
DB $78,$78,$84,$84,$80,$80,$7C,$7C,$02,$02,$82,$82,$7C,$7C,$00,$00 ; S
DB $FE,$FE,$10,$10,$10,$10,$10,$10,$10,$10,$10,$10,$10,$10,$00,$00 ; T
DB $82,$82,$82,$82,$82,$82,$82,$82,$82,$82,$42,$42,$3E,$3E,$00,$00 ; U
DB $82,$82,$82,$82,$44,$44,$44,$44,$28,$28,$28,$28,$10,$10,$00,$00 ; V
DB $82,$82,$92,$92,$AA,$AA,$AA,$AA,$C6,$C6,$C6,$C6,$82,$82,$00,$00 ; W
DB $C6,$C6,$44,$44,$28,$28,$10,$10,$28,$28,$44,$44,$C6,$C6,$00,$00 ; X
DB $82,$82,$44,$44,$28,$28,$10,$10,$10,$10,$10,$10,$10,$10,$00,$00 ; Y
DB $FE,$FE,$04,$04,$08,$08,$10,$10,$20,$20,$40,$40,$FE,$FE,$00,$00 ; Z
DB $00,$00,$38,$38,$4C,$4C,$C6,$C6,$C6,$C6,$64,$64,$38,$38,$00,$00 ; 0
DB $00,$00,$18,$18,$38,$38,$18,$18,$18,$18,$18,$18,$7E,$7E,$00,$00 ; 1
DB $00,$00,$7C,$7C,$C6,$C6,$0E,$0E,$78,$78,$E0,$E0,$FE,$FE,$00,$00 ; 2
DB $00,$00,$7E,$7E,$0C,$0C,$38,$38,$06,$06,$C6,$C6,$7C,$7C,$00,$00 ; 3
DB $00,$00,$1C,$1C,$3C,$3C,$6C,$6C,$CC,$CC,$FE,$FE,$0C,$0C,$00,$00 ; 4
DB $00,$00,$FC,$FC,$C0,$C0,$FC,$FC,$06,$06,$C6,$C6,$7C,$7C,$00,$00 ; 5
DB $00,$00,$7C,$7C,$C0,$C0,$FC,$FC,$C6,$C6,$C6,$C6,$7C,$7C,$00,$00 ; 6
DB $00,$00,$FE,$FE,$C6,$C6,$0C,$0C,$18,$18,$30,$30,$30,$30,$00,$00 ; 7
DB $00,$00,$7C,$7C,$C6,$C6,$7C,$7C,$C6,$C6,$C6,$C6,$7C,$7C,$00,$00 ; 8
DB $00,$00,$7C,$7C,$C6,$C6,$C6,$C6,$7E,$7E,$06,$06,$7C,$7C,$00,$00 ; 9
DB $06,$06,$08,$08,$10,$10,$10,$10,$10,$10,$08,$08,$06,$06,$00,$00 ; (
DB $C0,$C0,$20,$20,$10,$10,$10,$10,$10,$10,$20,$20,$C0,$C0,$00,$00 ; )
DB $00,$00,$18,$18,$18,$18,$00,$00,$00,$00,$18,$18,$18,$18,$00,$00 ; :
DB $00,$00,$18,$18,$18,$18,$00,$00,$18,$18,$18,$18,$08,$08,$10,$10 ; ;
DB $07,$07,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$07,$07,$00,$00 ; [
DB $E0,$E0,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$E0,$E0,$00,$00 ; ]
DB $E0,$E0,$A0,$A0,$E0,$E0,$8A,$8A,$8A,$8A,$0C,$0C,$0A,$0A,$0A,$0A ; Pk
DB $D8,$D8,$A8,$A8,$88,$88,$88,$88,$92,$92,$1A,$1A,$16,$16,$12,$12 ; Mn
DB $00,$00,$00,$00,$00,$00,$00,$00,$7E,$7E,$00,$00,$00,$00,$00,$00 ; _
DB $00,$00,$7E,$7E,$E7,$E7,$CE,$CE,$18,$18,$00,$00,$18,$18,$18,$18 ; ?
DB $18,$18,$3C,$3C,$3C,$3C,$3C,$3C,$18,$18,$00,$00,$18,$18,$18,$18 ; !
DB $10,$10,$38,$38,$54,$54,$92,$92,$38,$38,$44,$44,$44,$44,$38,$38 ; Male
DB $38,$38,$44,$44,$44,$44,$38,$38,$10,$10,$7C,$7C,$10,$10,$10,$10 ; Female
DB $00,$00,$02,$02,$04,$04,$08,$08,$10,$10,$20,$20,$40,$40,$80,$80 ; /
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$30,$30,$30,$30,$00,$00 ; .
DB $00,$00,$00,$00,$00,$00,$00,$00,$60,$60,$60,$60,$20,$20,$40,$40 ; ,
DB $F0,$F0,$C0,$C0,$F0,$F0,$CE,$CE,$FD,$FD,$0D,$0D,$0D,$0D,$0E,$0E ; End
ARROW_DOWN:
DB $FE,$FE,$FE,$FE,$7C,$7C,$38,$38,$10,$10,$00,$00,$00,$00,$00,$00
ARROW_RIGHT:
DB $00,$00,$60,$60,$70,$70,$78,$78,$7C,$7C,$78,$78,$70,$70,$60,$60
CURRENT_CHAR:
DB $FE,$FE,$FE,$FE,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; ^_
X_CHAR:
DB $00,$00,$00,$00,$00,$00,$FE,$FE,$FE,$FE,$00,$00,$00,$00,$00,$00 ; v_