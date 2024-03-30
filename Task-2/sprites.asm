.include "constants.inc"
.include "header.inc"

.segment "ZEROPAGE"
sprite1_x: .res 1
sprite1_y: .res 1
sprite1_tile: .res 1
sprite1_counter: .res 1
sprite1_timer: .res 1
sprite2_x: .res 1
sprite2_y: .res 1
sprite2_tile: .res 1
sprite2_counter: .res 1
sprite2_timer: .res 1
sprite3_x: .res 1
sprite3_y: .res 1
sprite3_tile: .res 1
sprite3_counter: .res 1
sprite3_timer: .res 1
sprite4_x: .res 1
sprite4_y: .res 1
sprite4_tile: .res 1
sprite4_counter: .res 1
sprite4_timer: .res 1
.exportzp sprite1_x, sprite1_y, sprite1_tile, sprite1_counter, sprite1_timer, sprite2_x, sprite2_y, sprite2_tile, sprite2_counter, sprite2_timer, sprite3_x, sprite3_y, sprite3_tile, sprite3_counter, sprite3_timer, sprite4_x, sprite4_y, sprite4_tile, sprite4_counter, sprite4_timer

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
  JSR draw_sprite1
  JSR update_sprite1
  JSR draw_sprite2
  JSR update_sprite2
  JSR draw_sprite3
  JSR update_sprite3
  JSR draw_sprite4
  JSR update_sprite4

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

  LDA #%10010000  ; turn on NMIs, sprites use first pattern table
  STA PPUCTRL
  LDA #%10011110  ; turn on screen
  STA PPUMASK

forever:
  JMP forever
.endproc

.proc draw_sprite1
  ; save registers
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA
  
  ; write player ship tile numbers
  LDA sprite1_tile
  STA $0201
  CLC
  ADC #$01
  STA $0205
  CLC
  ADC #$01
  STA $0209
  CLC
  ADC #$01
  STA $020d

  ; write player ship tile atributes
  ; use palette 0
  LDA #$00
  STA $0202
  STA $0206
  STA $020a
  STA $020e

  ; store tile locations
  ; top left tile:
  LDA sprite1_y
  STA $0200
  LDA sprite1_x
  STA $0203
  ; top right tile (x + 8):
  LDA sprite1_y
  STA $0204
  LDA sprite1_x
  CLC
  ADC #$08
  STA $0207

  ; bottom left tile (y + 8):
  LDA sprite1_y
  CLC
  ADC #$08
  STA $0208
  LDA sprite1_x
  STA $020b

  ; bottom right tile (x + 8, y + 8)
  LDA sprite1_y
  CLC
  ADC #$08
  STA $020c
  LDA sprite1_x
  CLC
  ADC #$08
  STA $020f

  ; restore registers and return
  PLA 
  TYA
  PLA
  TAX 
  PLA 
  PLP 
  RTS 
.endproc

.proc update_sprite1
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  LDX sprite1_timer
  INX
  CPX #$0a
  STX sprite1_timer
  BNE end

  LDX #$00
  STX sprite1_timer
  LDA sprite1_tile
  CLC
  ADC #$04
  STA sprite1_tile
  LDX sprite1_counter
  INX
  CPX #$03
  STX sprite1_counter
  BNE end
  LDX #$00
  STX sprite1_counter
  LDA #$04
  STA sprite1_tile

end:
  PLA 
  TYA
  PLA
  TAX 
  PLA 
  PLP
  RTS
.endproc

.proc draw_sprite2
  ; save registers
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA
  
  ; write player ship tile numbers
  LDA sprite2_tile
  STA $0211
  CLC
  ADC #$01
  STA $0215
  CLC
  ADC #$01
  STA $0219
  CLC
  ADC #$01
  STA $021d

  ; write player ship tile atributes
  ; use palette 0
  LDA #$00
  STA $0212
  STA $0216
  STA $021a
  STA $021e

  ; store tile locations
  ; top left tile:
  LDA sprite2_y
  STA $0210
  LDA sprite2_x
  STA $0213
  ; top right tile (x + 8):
  LDA sprite2_y
  STA $0214
  LDA sprite2_x
  CLC
  ADC #$08
  STA $0217

  ; bottom left tile (y + 8):
  LDA sprite2_y
  CLC
  ADC #$08
  STA $0218
  LDA sprite2_x
  STA $021b

  ; bottom right tile (x + 8, y + 8)
  LDA sprite2_y
  CLC
  ADC #$08
  STA $021c
  LDA sprite2_x
  CLC
  ADC #$08
  STA $021f

  ; restore registers and return
  PLA 
  TYA
  PLA
  TAX 
  PLA 
  PLP 
  RTS 
.endproc

.proc update_sprite2
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  LDX sprite2_timer
  INX
  CPX #$0a
  STX sprite2_timer
  BNE end

  LDX #$00
  STX sprite2_timer
  LDA sprite2_tile
  CLC
  ADC #$04
  STA sprite2_tile
  LDX sprite2_counter
  INX
  CPX #$03
  STX sprite2_counter
  BNE end
  LDX #$00
  STX sprite2_counter
  LDA #$10
  STA sprite2_tile

end:
  PLA 
  TYA
  PLA
  TAX 
  PLA 
  PLP
  RTS
.endproc

.proc draw_sprite3
  ; save registers
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA
  
  ; write player ship tile numbers
  LDA sprite3_tile
  STA $0221
  CLC
  ADC #$01
  STA $0225
  CLC
  ADC #$01
  STA $0229
  CLC
  ADC #$01
  STA $022d

  ; write player ship tile atributes
  ; use palette 0
  LDA #$00
  STA $0222
  STA $0226
  STA $022a
  STA $022e

  ; store tile locations
  ; top left tile:
  LDA sprite3_y
  STA $0220
  LDA sprite3_x
  STA $0223
  ; top right tile (x + 8):
  LDA sprite3_y
  STA $0224
  LDA sprite3_x
  CLC
  ADC #$08
  STA $0227

  ; bottom left tile (y + 8):
  LDA sprite3_y
  CLC
  ADC #$08
  STA $0228
  LDA sprite3_x
  STA $022b

  ; bottom right tile (x + 8, y + 8)
  LDA sprite3_y
  CLC
  ADC #$08
  STA $022c
  LDA sprite3_x
  CLC
  ADC #$08
  STA $022f

  ; restore registers and return
  PLA 
  TYA
  PLA
  TAX 
  PLA 
  PLP 
  RTS 
.endproc

.proc update_sprite3
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  LDX sprite3_timer
  INX
  CPX #$0a
  STX sprite3_timer
  BNE end

  LDX #$00
  STX sprite3_timer
  LDA sprite3_tile
  CLC
  ADC #$04
  STA sprite3_tile
  LDX sprite3_counter
  INX
  CPX #$03
  STX sprite3_counter
  BNE end
  LDX #$00
  STX sprite3_counter
  LDA #$1c
  STA sprite3_tile

end:
  PLA 
  TYA
  PLA
  TAX 
  PLA 
  PLP
  RTS
.endproc

.proc draw_sprite4
  ; save registers
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA
  
  ; write player ship tile numbers
  LDA sprite4_tile
  STA $0231
  CLC
  ADC #$01
  STA $0235
  CLC
  ADC #$01
  STA $0239
  CLC
  ADC #$01
  STA $023d

  ; write player ship tile atributes
  ; use palette 0
  LDA #$00
  STA $0232
  STA $0236
  STA $023a
  STA $023e

  ; store tile locations
  ; top left tile:
  LDA sprite4_y
  STA $0230
  LDA sprite4_x
  STA $0233
  ; top right tile (x + 8):
  LDA sprite4_y
  STA $0234
  LDA sprite4_x
  CLC
  ADC #$08
  STA $0237

  ; bottom left tile (y + 8):
  LDA sprite4_y
  CLC
  ADC #$08
  STA $0238
  LDA sprite4_x
  STA $023b

  ; bottom right tile (x + 8, y + 8)
  LDA sprite4_y
  CLC
  ADC #$08
  STA $023c
  LDA sprite4_x
  CLC
  ADC #$08
  STA $023f

  ; restore registers and return
  PLA 
  TYA
  PLA
  TAX 
  PLA 
  PLP 
  RTS 
.endproc

.proc update_sprite4
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  LDX sprite4_timer
  INX
  CPX #$0a
  STX sprite4_timer
  BNE end

  LDX #$00
  STX sprite4_timer
  LDA sprite4_tile
  CLC
  ADC #$04
  STA sprite4_tile
  LDX sprite4_counter
  INX
  CPX #$03
  STX sprite4_counter
  BNE end
  LDX #$00
  STX sprite4_counter
  LDA #$28
  STA sprite4_tile

end:
  PLA 
  TYA
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
  .byte $0f, $0f, $0f, $0f
  .byte $0f, $0f, $0f, $0f
  .byte $0f, $0f, $0f, $0f
  .byte $0f, $0f, $0f, $0f

  .byte $0f ,$11, $21, $01
  .byte $0f, $19, $09, $29
  .byte $0f, $19, $09, $29
  .byte $0f, $19, $09, $29

; sprites:
;   .byte $70, $04, $00, $80
;   .byte $70, $05, $00, $88
;   .byte $78, $14, $00, $80
;   .byte $78, $15, $00, $88

.segment "CHR"
.incbin "graphics.chr"
