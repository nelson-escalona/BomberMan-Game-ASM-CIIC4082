.include "constants.inc"

.segment "ZEROPAGE"
.importzp sprite1_x, sprite1_y, sprite1_tile, sprite1_counter, sprite1_timer, sprite2_x, sprite2_y, sprite2_tile, sprite2_counter, sprite2_timer, sprite3_x, sprite3_y, sprite3_tile, sprite3_counter, sprite3_timer, sprite4_x, sprite4_y, sprite4_tile, sprite4_counter, sprite4_timer

.segment "CODE"
.import main
.export reset_handler
.proc reset_handler
  SEI
  CLD
  LDX #$40
  STX $4017
  LDX #$FF
  TXS
  INX
  STX $2000
  STX $2001
  STX $4010
  BIT $2002
vblankwait:
  BIT $2002
  BPL vblankwait

   ; initialize zero-page values
  LDA #$66
  STA sprite1_x
  LDA #$66
  STA sprite1_y
  LDA #$04
  STA sprite1_tile
  LDA #$00
  STA sprite1_counter
  LDA #$00
  STA sprite1_timer
  LDA #$66
  STA sprite2_x
  LDA #$76
  STA sprite2_y
  LDA #$10
  STA sprite2_tile
  LDA #$00
  STA sprite2_counter
  LDA #$00
  STA sprite2_timer
  LDA #$76
  STA sprite3_x
  LDA #$66
  STA sprite3_y
  LDA #$1c
  STA sprite3_tile
  LDA #$00
  STA sprite3_counter
  LDA #$00
  STA sprite3_timer
  LDA #$76
  STA sprite4_x
  LDA #$76
  STA sprite4_y
  LDA #$28
  STA sprite4_tile
  LDA #$00
  STA sprite4_counter
  LDA #$00
  STA sprite4_timer

vblankwait2:
  BIT $2002
  BPL vblankwait2
  JMP main
.endproc
