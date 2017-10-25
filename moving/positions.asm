_SPR0_Y     EQU     _OAMRAM ; sprite Y 0 is the beginning of the sprite mem
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

_CHAR_POS	EQU		_RAM

; _CHAR_POS ->	$0C000-$0C01	->	DOWN_MOVE_01 | DOWN_MOVE_02 | UP_MOVE_01 | UP_MOVE_02 | SX_MOVE | DX_MOVE | Unused | Unused


SECTION "Positions",HOME[$500]


MAIN_CHAR::
	ld	a,$40
	ld	[_CHAR_POS],a		; Default position.
	ld	a,80
	ld	[_SPR0_Y],a			; Y position of the sprite     
	ld	a,77
	ld	[_SPR0_X],a			; X position of the sprite
	ld	a,80
	ld	[_SPR1_Y],a			; Y position of the sprite     
	ld	a,85
	ld	[_SPR1_X],a			; X position of the sprite
	ld	a,88
	ld	[_SPR2_Y],a			; Y position of the sprite     
	ld	a,77
	ld	[_SPR2_X],a			; X position of the sprite
	ld	a,88
	ld	[_SPR3_Y],a			; Y position of the sprite     
	ld	a,85
	ld	[_SPR3_X],a			; X position of the sprite
	ret

RST_POS::
	call WAIT_VBLANK
	ld	a,%10000001			;
	ldh	[rLCDC],a			; OBJ off

	ld	a,[_CHAR_POS]
	cp	$80
	jp	z,DOWN_STILL
	cp	$40
	jp	z,DOWN_STILL
	cp	$20
	jp	z,UP_STILL
	cp	$10
	jp	z,UP_STILL
	cp	$08
	jp	z,SX_STILL
	cp	$04
	jp	z,DX_STILL

	ld	a,%10000011			;
	ldh	[rLCDC],a			; LCDC On, BG from $8800, OBJ ON, BG Display ON
	
	ret


DOWN_STILL::
	push af
; Sprite Top-Sx
	xor a
	ld	[_SPR0_NUM],a
	xor	a
	ld	[_SPR0_ATT],a
; Sprite Top-Dx
	ld	a,$00
	ld	[_SPR1_NUM],a
	ld	a,%00100000
	ld	[_SPR1_ATT],a
; Sprite Bottom-Sx
	ld	a,$01
	ld	[_SPR2_NUM],a
	xor	a
	ld	[_SPR2_ATT],a
; Sprite Bottom-Dx
	ld	a,$01
	ld	[_SPR3_NUM],a
	ld	a,%00100000
	ld	[_SPR3_ATT],a

	pop	af
	ret


DOWN_MOVE::
	push af
; Sprite Top-Sx
	ld	a, $02
	ld	[_SPR0_NUM],a
	xor	a
	ld	[_SPR0_ATT],a
; Sprite Top-Dx
	ld	a,$02
	ld	[_SPR1_NUM],a
	ld	a,%00100000
	ld	[_SPR1_ATT],a

	ld	a,[_CHAR_POS]
	cp	$80
	jp	z,DOWN_MOVE_02
	cp	$40
	jp	z,DOWN_MOVE_01

DOWN_MOVE_01:	
; Sprite Bottom-Sx
	ld	a,$03
	ld	[_SPR2_NUM],a
	xor	a
	ld	[_SPR2_ATT],a
; Sprite Bottom-Dx
	ld	a,$04
	ld	[_SPR3_NUM],a
	xor	a
	ld	[_SPR3_ATT],a

	ld	a,%10000000
	ld	[_CHAR_POS],a

	pop af
	ret

DOWN_MOVE_02:	
; Sprite Bottom-Sx
	ld	a,$04
	ld	[_SPR2_NUM],a
	ld	a,%00100000
	ld	[_SPR2_ATT],a
; Sprite Bottom-Dx
	ld	a,$03
	ld	[_SPR3_NUM],a
	ld	a,%00100000
	ld	[_SPR3_ATT],a

	ld	a,%01000000
	ld	[_CHAR_POS],a

	pop	af
	ret


UP_STILL::
	push af
; Sprite Top-Sx
	ld	a, $0D
	ld	[_SPR0_NUM],a
	xor	a
	ld	[_SPR0_ATT],a
; Sprite Top-Dx
	ld	a,$0D
	ld	[_SPR1_NUM],a
	ld	a,%00100000
	ld	[_SPR1_ATT],a
; Sprite Bottom-Sx
	ld	a,$0E
	ld	[_SPR2_NUM],a
	xor	a
	ld	[_SPR2_ATT],a
; Sprite Bottom-Dx
	ld	a,$0E
	ld	[_SPR3_NUM],a
	ld	a,%00100000
	ld	[_SPR3_ATT],a

	pop	af
	ret

UP_MOVE::
	push af
; Sprite Top-Sx
	ld	a, $0F
	ld	[_SPR0_NUM],a
	xor	a
	ld	[_SPR0_ATT],a
; Sprite Top-Dx
	ld	a,$0F
	ld	[_SPR1_NUM],a
	ld	a,%00100000
	ld	[_SPR1_ATT],a

	ld	a,[_CHAR_POS]
	cp	$20
	jp	z,UP_MOVE_02
	cp	$10
	jp	z,UP_MOVE_01

UP_MOVE_01:	
; Sprite Bottom-Sx
	ld	a,$10
	ld	[_SPR2_NUM],a
	xor	a
	ld	[_SPR2_ATT],a
; Sprite Bottom-Dx
	ld	a,$11
	ld	[_SPR3_NUM],a
	xor	a
	ld	[_SPR3_ATT],a

	ld	a,%00100000
	ld	[_CHAR_POS],a

	pop	af
	ret

UP_MOVE_02:	
; Sprite Bottom-Sx
	ld	a,$11
	ld	[_SPR2_NUM],a
	ld	a,%00100000
	ld	[_SPR2_ATT],a
; Sprite Bottom-Dx
	ld	a,$10
	ld	[_SPR3_NUM],a
	ld	a,%00100000
	ld	[_SPR3_ATT],a

	ld	a,%00010000
	ld	[_CHAR_POS],a

	pop	af
	ret


SX_STILL::
	push af
; Sprite Top-Sx
	ld	a, $05
	ld	[_SPR0_NUM],a
	xor	a
	ld	[_SPR0_ATT],a
; Sprite Top-Dx
	ld	a,$06
	ld	[_SPR1_NUM],a
	xor	a
	ld	[_SPR1_ATT],a
; Sprite Bottom-Sx
	ld	a,$07
	ld	[_SPR2_NUM],a
	xor	a
	ld	[_SPR2_ATT],a
; Sprite Bottom-Dx
	ld	a,$08
	ld	[_SPR3_NUM],a
	xor	a
	ld	[_SPR3_ATT],a

	pop	af
	ret

SX_MOVE::
	push af
; Sprite Top-Sx
	ld	a, $09
	ld	[_SPR0_NUM],a
	xor	a
	ld	[_SPR0_ATT],a
; Sprite Top-Dx
	ld	a,$0B
	ld	[_SPR1_NUM],a
	xor	a
	ld	[_SPR1_ATT],a
; Sprite Bottom-Sx
	ld	a,$0A
	ld	[_SPR2_NUM],a
	xor	a
	ld	[_SPR2_ATT],a
; Sprite Bottom-Dx
	ld	a,$0C
	ld	[_SPR3_NUM],a
	xor	a
	ld	[_SPR3_ATT],a

	ld	a,%00001000
	ld	[_CHAR_POS],a

	pop	af
	ret

DX_STILL::
	push af
; Sprite Top-Sx
	ld	a, $06
	ld	[_SPR0_NUM],a
	ld	a,%00100000
	ld	[_SPR0_ATT],a
; Sprite Top-Dx
	ld	a,$05
	ld	[_SPR1_NUM],a
	ld	a,%00100000
	ld	[_SPR1_ATT],a
; Sprite Bottom-Sx
	ld	a,$08
	ld	[_SPR2_NUM],a
	ld	a,%00100000
	ld	[_SPR2_ATT],a
; Sprite Bottom-Dx
	ld	a,$07
	ld	[_SPR3_NUM],a
	ld	a,%00100000
	ld	[_SPR3_ATT],a

	pop	af
	ret

DX_MOVE::
	push af
; Sprite Top-Sx
	ld	a, $0B
	ld	[_SPR0_NUM],a
	ld	a,%00100000
	ld	[_SPR0_ATT],a
; Sprite Top-Dx
	ld	a,$09
	ld	[_SPR1_NUM],a
	ld	a,%00100000
	ld	[_SPR1_ATT],a
; Sprite Bottom-Sx
	ld	a,$0C
	ld	[_SPR2_NUM],a
	ld	a,%00100000
	ld	[_SPR2_ATT],a
; Sprite Bottom-Dx
	ld	a,$0A
	ld	[_SPR3_NUM],a
	ld	a,%00100000
	ld	[_SPR3_ATT],a

	ld	a,%00000100
	ld	[_CHAR_POS],a

	pop	af
	ret


; Hello darkness my old friend, I've come to talk to you again
WAIT_VBLANK::
	ldh	a,[rLY]				; get current scanline
	cp	$91					; Are we in v-blank yet?
	jr	nz,WAIT_VBLANK		; if A-91 != 0 then loop
	ret