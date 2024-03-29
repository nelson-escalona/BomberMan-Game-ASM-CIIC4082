.include "constants.inc"
.include "header.inc"

.segment "ZEROPAGE"
player_x: .res 1
player_y: .res 1
player_dir: .res 1
.exportzp player_x, player_y

.segment "CODE"
.proc irq_handler
  RTI
.endproc

.proc nmi_handler
  LDA #$00
  STA OAMADDR
  LDA #$02
  STA OAMDMA
	LDA #$00

  ; update tiles *after* DMA transfer
  ; Deleted 
  JSR draw_player

	STA $2005
	STA $2005
  RTI
.endproc

.import reset_handler

.export main
.proc main
  ; write a palette
  LDX PPUSTATUS
  LDX #$3f
  STX PPUADDR
  LDX #$00
  STX PPUADDR
load_palettes:
  LDA palettes,X
  STA PPUDATA
  INX
  CPX #$20
  BNE load_palettes

; deleted nametable and attribute table. Whole bg really


; I can load sprites here. Make it the "outer loop" to call the subroutine
;
; INPUTS:
;   - X Coord
;   - Y Coord
;   - Tile Num

; I need X cleared before starting
LDX #$00

load_sprites:

  ; Define the tiles for the first sprite. Will index inside subroutine.
  ; Each byte will be increased on each iteration to change tile.

  ; Total number of tiles = 4 * 3 = 12
  ; On every loop, each item in the tiles would increase by 4. For example
  ; the next tile would then be : .byte $08, $09, $0A, $0B which is right
  tiles:
    .byte $04, $05, $06, $07


  ; I think it's proper to call the subroutine here.
  ; X is cleared, tiles is defined, and the Coords
  ; will be updated below on every iteration.
  JSR draw_player

  ; Make Updates Below


  ; Have to increase X four times to change
  ; the addresses where we write each sprite
  INX
  INX
  INX
  INX

  ; Update Coords.
  LDA player_x  ; Load coord `player_x` into accumulator
  CLC           ; Clear carry flag
  ADC #10       ; Add 10
  STA player_x  ; Load coord + 10 back to `player_x`


  ; After going through 6 tiles, X Should be 24 and we should increase 
  ; the `player_y` coord by 10. For such reason, we do the CMP below.

  CPX #$18        ; This is 24 Decimal
  BEQ increase_y  ; Increase Y if Condition is set.


  CPX #$40 ; This is 64 Decimal, at this point, we should've gone over 
           ; all of the sprites, so we can break. Otherwise loop again
  BNE load_sprites



  increase_y:
    LDA player_y  ; Load coord `player_y` into accumulator
    CLC           ; Clear carry flag
    ADC #10       ; Add 10
    STA player_y  ; Load coord + 10 back to `player_y`

    JMP load_sprites ; Back to the loop!


vblankwait:       ; wait for another vblank before continuing
  BIT PPUSTATUS
  BPL vblankwait

  LDA #%10010000  ; turn on NMIs, sprites use first pattern table
  STA PPUCTRL
  LDA #%00011110  ; turn on screen
  STA PPUMASK

forever:
  JMP forever
.endproc

; Deleted the update player subroutine

.proc draw_player
  ; save registers
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  ; I need so that these bum addresses increase on every call.
  ; Maybe I could make use of the X register and do:
  ;   STA $0201, X 
  ; Would do it for each, and every call, X += 16?
  ; The reason to increase by 16 is that we're loading in
  ; 4 tiles, each has an offset from the previous of 4 ($0201, $0205, $0209...)

  ; write player ship tile numbers
  LDA tiles       ; apparently this loads first from tiles
  STA $0201, X
  LDA tiles + 1   ; and this one the second and so on...
  STA $0205, X
  LDA tiles + 2
  STA $0209, X
  LDA tiles + 3
  STA $020d, X

  ; Same shit here, put the X for offset.
  ; write tile attributes, use palette 0
  LDA #$00   ; Doesn't have to be changed, as we'll use palette 00 for all
  STA $0202, X
  STA $0206, X
  STA $020a, X
  STA $020e, X

  ; Here too...
  ; store tile locations / X,Y Coords
  ; top left tile:
  LDA player_y
  STA $0200, X
  LDA player_x
  STA $0203, X

  ; And here... great! Gotta think though, eventually I'll have to increase
  ; `Y` because I can only put up to 8 sprites on a horizontal I think. 

  ; In this case, `player_y` and `player_x` are being referenced from the
  ; Zero Page. I could also work on increasing these in the loop above.

  ; `player_x` would increase +10 on every tile that is rendered.
  ; `player_y` would increase +10 after 6 [?] tiles are render, so when
  ;     `player_x` == 60. Can do a CMP for this, branch somewhere outside of the 
  ;      loop and come back to sequence?

  ; top right tile (x + 8):
  LDA player_y
  STA $0204, X
  LDA player_x
  CLC
  ADC #$08
  STA $0207, X

  ; bottom left tile (y + 8):
  LDA player_y
  CLC
  ADC #$08
  STA $0208, X
  LDA player_x
  STA $020b, X

  ; bottom right tile (x + 8, y + 8)
  LDA player_y
  CLC
  ADC #$08
  STA $020c, X
  LDA player_x
  CLC
  ADC #$08
  STA $020f, X

  ; restore registers and return
  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS
.endproc

.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

.segment "RODATA"
palettes:
.byte $0f, $12, $23, $27
.byte $0f, $2b, $3c, $39
.byte $0f, $0c, $07, $13
.byte $0f, $19, $09, $29

.byte $0f, $2d, $10, $15
.byte $0f, $19, $09, $29
.byte $0f, $19, $09, $29
.byte $0f, $19, $09, $29

.segment "CHR"
.incbin "starfield.chr"
