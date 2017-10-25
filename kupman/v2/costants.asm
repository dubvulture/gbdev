_MAP_VRAM       EQU     _VRAM+$1000
_BITMAP         EQU     _RAM+$0A0

rINPUTS         EQU     _RAM
;   Start   |   Select  |   B   |   A   |   Down    |   Up  |   Sx  |   Dx  |

rMOVE           EQU     _RAM+$01    ; Current moving direction
;   0       |   0       |   0   |   0   |   Down    |   Up  |   Sx  |   Dx  |

rMOVE_1         EQU     _RAM+$02

rDIRECTION      EQU     _RAM+$03    ; Global direction

rDIRECTION_1    EQU     _RAM+$04

rTRANSITION     EQU     _RAM+$05    ; Transition state (all bits, who fucking cares)

rTRANSITION_1   EQU     _RAM+$06

rPOS2           EQU     _RAM+$07
; Current position expressed in Map Tile, inverted for debugging reasons
rPOS1           EQU     _RAM+$08

rPOS2_1         EQU     _RAM+$09
rPOS1_1         EQU     _RAM+$0A

rTRY            EQU     _RAM+$0B

rTRY_1          EQU     _RAM+$0C

rSCORE          EQU     _RAM+$0D
rREMDOTS        EQU     _RAM+$0E
rFORBIDDEN      EQU     _RAM+$0F
rTURN           EQU     _RAM+$10

; Array of 4 elements in which are stored moving direction to be considered by AI algorithm
arrMD           EQU     _RAM+$20


_PACY           EQU     _RAM+$1000
_PACX           EQU     _RAM+$1001
_PAC_NUM        EQU     _RAM+$1002
_PAC_ATT        EQU     _RAM+$1003

_GH1Y           EQU     _RAM+$1004
_GH1X           EQU     _RAM+$1005
_GH1_NUM        EQU     _RAM+$1006
_GH1_ATT        EQU     _RAM+$1007


; Costants for setting copying loops
LOAD_SHORT      EQU     $C600
LOAD_LONG       EQU     $C500
mWHERE1         EQU     $C606
mWHERE2         EQU     $C605
mWHAT1          EQU     $C609
mWHAT2          EQU     $C608
mCOUNT          EQU     $C60B
mWHERE1_L       EQU     $C506
mWHERE2_L       EQU     $C505
mWHAT1_L        EQU     $C509
mWHAT2_L        EQU     $C508
mCOUNT1_L       EQU     $C50C
mCOUNT2_L       EQU     $C50B


; I don't think these should ever be used
; (OAM DMA transfer will take care of filling these)
_SPR0_Y         EQU     _OAMRAM
_SPR0_X         EQU     _OAMRAM+$01
_SPR0_NUM       EQU     _OAMRAM+$02
_SPR0_ATT       EQU     _OAMRAM+$03

