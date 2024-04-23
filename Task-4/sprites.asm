.include "constants.inc"
.include "header.inc"

.segment "ZEROPAGE"
m_index: .res 1
MYb: .res 1
MXb: .res 1
index: .res 1
index_high: .res 1
index_low: .res 1
current_byte: .res 1
.exportzp m_index

.segment "CODE"
.proc irq_handler
  RTI
.endproc

.proc nmi_handler
  LDA #$00
  STA OAMADDR
  LDA #$02
  STA OAMDMA

  ; update tiles *after* DMA transfer


  LDA #$00
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

vblankwait:       ; wait for another vblank before continuing
  BIT PPUSTATUS
  BPL vblankwait

  JSR load_M_segment

  LDA #%10010000  ; turn on NMIs, sprites use first pattern table
  STA PPUCTRL
  LDA #%10011110  ; turn on screen
  STA PPUMASK

forever:
  JMP forever
.endproc

.proc load_M_segment
  ; save registers
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  LDA m_index ; load the current M index into A
  LSR A       ; first shift right
  LSR A       ; second shift right
  STA MYb     ; store A into MYb
  LDA m_index
  AND #$03    ; mask out the first two bits (from right to left)
  STA MXb     ; store A into MXb

  LDA MYb
  ASL A
  ASL A
  ASL A
  ASL A
  ASL A
  ASL A ; 6 shifts left makes this = to A * 64
  STA MYb
  LDA MXb
  ASL A
  ASL A
  ASL A ; 3 shifts left makes this = to A * 8
  STA MXb
  LDA $00
  ADC MXb
  ADC MYb
  STA index

  LDA MYb
  LSR A
  LSR A
  AND #$03
  STA index_high
  LDA MXb
  ASL A
  ASL A
  ASL A
  STA MXb
  LDA MYb
  ASL A
  ASL A
  ASL A
  ASL A
  ASL A
  ASL A
  ADC MXb
  STA index_low
  LDA #$00
  LDX m_index

  Load_Background:
    LDA #$20
    ADC index_high
    STA PPUADDR
    LDA #$00
    ADC index_low
    STA PPUADDR
    ;LDY stage1left,X
  Calculate_tile:
    LDA stage1left,X
    AND #$03
    CMP #$01
    BEQ Load_Stone ; We encountered a stone tile
    CMP #$10
    BEQ Load_Brick
    ASL A
    ASL A

  Load_Bush:
    ; logic to draw a bush
    ; we need to update index to go to the next megatile

  Load_Stone:
    ; logic to draw a stone block
    ; we need to update index to go to the next megatile

  Load_Brick:
    ; logic to draw a brick block
    ; we need to update index to go to the next megatile

  ; restore registers and return
  PLA 
  TYA
  PLA
  TAX 
  PLA 
  PLP 
  RTS 
.endproc

; LoadBackground:
;   LDA $2002             ; read PPU status to reset the high/low latch
;   LDA #$20
;   STA $2006             ; write the high byte of $2000 address
;   LDA #$00
;   STA $2006             ; write the low byte of $2000 address
;   LDX #$00              ; start out at 0

; LoadBackgroundLoop:
;   LDA background, x     ; load data from address (background + the value in x)
;   STA $2007             ; write to PPU
;   INX                   ; X = X + 1
;   CPX #$80              ; Compare X to hex $80, decimal 128 - copying 128 bytes
;   BNE LoadBackgroundLoop  ; Branch to LoadBackgroundLoop if compare was Not Equal to zero
;                         ; if compare was equal to 128, keep going down

; LoadAttribute:
;   LDA $2002             ; read PPU status to reset the high/low latch
;   LDA #$23
;   STA $2006             ; write the high byte of $23C0 address
;   LDA #$C0
;   STA $2006             ; write the low byte of $23C0 address
;   LDX #$00              ; start out at 0

; LoadAttributeLoop:
;   LDA attribute, x      ; load data from address (attribute + the value in x)
;   STA $2007             ; write to PPU
;   INX                   ; X = X + 1
;   CPX #$08              ; Compare X to hex $08, decimal 8 - copying 8 bytes
;   BNE LoadAttributeLoop

.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

.segment "RODATA"
palettes:
  .byte $0f, $0f, $0f, $0f
  .byte $0f, $0f, $0f, $0f
  .byte $0f, $0f, $0f, $0f
  .byte $0f, $0f, $0f, $0f

  .byte $0f ,$11, $21, $01
  .byte $0f, $19, $09, $29
  .byte $0f, $19, $09, $29
  .byte $0f, $19, $09, $29

stage1left:
  .byte %01010101, %01010101, %01010101, %01010101
  .byte %01111111, %11111100, %10000000, %00000000
  .byte %01111011, %11111100, %10001010, %10101010
  .byte %01111010, %10101000, %10001000, %00000010
  .byte %01000000,	%00001000, %10111010,	%10100110
  .byte %01101010,	%10001000, %11111100,	%00101110
  .byte %01000000,	%00001010, %10101010,	%10101110
  .byte %01001010,	%10101000, %11111111, %11111110
  .byte %01000000,	%00001000, %10101010,	%10101110
  .byte %01101010,	%10001000, %10000000,	%00111110
  .byte %01111111,	%11111000, %10111010,	%10100010
  .byte %01111010,	%10101000, %10111000,	%00000010
  .byte %01111111,	%11111100, %10111010,	%10100010
  .byte %00111111,	%11111100, %10111111,	%11110010
  .byte %01010101,	%01010101, %01010101,	%01010101

; sprites:
;   .byte $70, $04, $00, $80
;   .byte $70, $05, $00, $88
;   .byte $78, $14, $00, $80
;   .byte $78, $15, $00, $88

.segment "CHR"
.incbin "graphics.chr"
