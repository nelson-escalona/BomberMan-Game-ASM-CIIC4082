.include "constants.inc"

.segment "ZEROPAGE"
.importzp player_x, player_y, tile_index, tile_count

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
  STA player_x
  LDA #$66
  STA player_y
  LDA #$04
  STA tile_index
  LDA #$00
  STA tile_count

vblankwait2:
  BIT $2002
  BPL vblankwait2
  JMP main
.endproc
