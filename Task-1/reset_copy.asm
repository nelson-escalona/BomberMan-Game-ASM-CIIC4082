.include "constants.inc"

.segment "ZEROPAGE"
.importzp sprite1_x, sprite1_y, sprite1_tile, sprite2_x, sprite2_y, sprite2_tile, sprite3_x, sprite3_y, sprite3_tile, sprite4_x, sprite4_y, sprite4_tile, sprite5_x, sprite5_y, sprite5_tile, sprite6_x, sprite6_y, sprite6_tile, sprite7_x, sprite7_y, sprite7_tile, sprite8_x, sprite8_y, sprite8_tile, sprite9_x, sprite9_y, sprite9_tile, sprite10_x, sprite10_y, sprite10_tile, sprite11_x, sprite11_y, sprite11_tile, sprite12_x, sprite12_y, sprite12_tile

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
  LDA #$46
  STA sprite1_x
  LDA #$66
  STA sprite1_y
  LDA #$04
  STA sprite1_tile
  LDA #$56
  STA sprite2_x
  LDA #$66
  STA sprite2_y
  LDA #$08
  STA sprite2_tile
  LDA #$66
  STA sprite3_x
  LDA #$66
  STA sprite3_y
  LDA #$0c
  STA sprite3_tile
  LDA #$76
  STA sprite4_x
  LDA #$66
  STA sprite4_y
  LDA #$10
  STA sprite4_tile
  LDA #$46
  STA sprite5_x
  LDA #$76
  STA sprite5_y
  LDA #$14
  STA sprite5_tile
  LDA #$56
  STA sprite6_x
  LDA #$76
  STA sprite6_y
  LDA #$18
  STA sprite6_tile
  LDA #$66
  STA sprite7_x
  LDA #$76
  STA sprite7_y
  LDA #$1c
  STA sprite7_tile
  LDA #$76
  STA sprite8_x
  LDA #$76
  STA sprite8_y
  LDA #$20
  STA sprite8_tile
  LDA #$46
  STA sprite9_x
  LDA #$86
  STA sprite9_y
  LDA #$24
  STA sprite9_tile
  LDA #$56
  STA sprite10_x
  LDA #$86
  STA sprite10_y
  LDA #$28
  STA sprite10_tile
  LDA #$66
  STA sprite11_x
  LDA #$86
  STA sprite11_y
  LDA #$2c
  STA sprite11_tile
  LDA #$76
  STA sprite12_x
  LDA #$86
  STA sprite12_y
  LDA #$30
  STA sprite12_tile

vblankwait2:
  BIT $2002
  BPL vblankwait2
  JMP main
.endproc
