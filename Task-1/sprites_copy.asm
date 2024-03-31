.include "constants.inc"
.include "header.inc"

.segment "ZEROPAGE"
sprite1_x: .res 1
sprite1_y: .res 1
sprite1_tile: .res 1
sprite2_x: .res 1
sprite2_y: .res 1
sprite2_tile: .res 1
sprite3_x: .res 1
sprite3_y: .res 1
sprite3_tile: .res 1
sprite4_x: .res 1
sprite4_y: .res 1
sprite4_tile: .res 1
sprite5_x: .res 1
sprite5_y: .res 1
sprite5_tile: .res 1
sprite6_x: .res 1
sprite6_y: .res 1
sprite6_tile: .res 1
sprite7_x: .res 1
sprite7_y: .res 1
sprite7_tile: .res 1
sprite8_x: .res 1
sprite8_y: .res 1
sprite8_tile: .res 1
sprite9_x: .res 1
sprite9_y: .res 1
sprite9_tile: .res 1
sprite10_x: .res 1
sprite10_y: .res 1
sprite10_tile: .res 1
sprite11_x: .res 1
sprite11_y: .res 1
sprite11_tile: .res 1
sprite12_x: .res 1
sprite12_y: .res 1
sprite12_tile: .res 1
.exportzp sprite1_x, sprite1_y, sprite1_tile, sprite2_x, sprite2_y, sprite2_tile, sprite3_x, sprite3_y, sprite3_tile, sprite4_x, sprite4_y, sprite4_tile, sprite5_x, sprite5_y, sprite5_tile, sprite6_x, sprite6_y, sprite6_tile, sprite7_x, sprite7_y, sprite7_tile, sprite8_x, sprite8_y, sprite8_tile, sprite9_x, sprite9_y, sprite9_tile, sprite10_x, sprite10_y, sprite10_tile, sprite11_x, sprite11_y, sprite11_tile, sprite12_x, sprite12_y, sprite12_tile

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
  JSR draw_sprite2
  JSR draw_sprite3
  JSR draw_sprite4
  JSR draw_sprite5
  JSR draw_sprite6
  JSR draw_sprite7
  JSR draw_sprite8
  JSR draw_sprite9
  JSR draw_sprite10
  JSR draw_sprite11
  JSR draw_sprite12

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

.proc draw_sprite5
  ; save registers
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA
  
  ; write player ship tile numbers
  LDA sprite5_tile
  STA $0241
  CLC
  ADC #$01
  STA $0245
  CLC
  ADC #$01
  STA $0249
  CLC
  ADC #$01
  STA $024d

  ; write player ship tile atributes
  ; use palette 0
  LDA #$00
  STA $0242
  STA $0246
  STA $024a
  STA $024e

  ; store tile locations
  ; top left tile:
  LDA sprite5_y
  STA $0240
  LDA sprite5_x
  STA $0243
  ; top right tile (x + 8):
  LDA sprite5_y
  STA $0244
  LDA sprite5_x
  CLC
  ADC #$08
  STA $0247

  ; bottom left tile (y + 8):
  LDA sprite5_y
  CLC
  ADC #$08
  STA $0248
  LDA sprite5_x
  STA $024b

  ; bottom right tile (x + 8, y + 8)
  LDA sprite5_y
  CLC
  ADC #$08
  STA $024c
  LDA sprite5_x
  CLC
  ADC #$08
  STA $024f

  ; restore registers and return
  PLA 
  TYA
  PLA
  TAX 
  PLA 
  PLP 
  RTS 
.endproc

.proc draw_sprite6
  ; save registers
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA
  
  ; write player ship tile numbers
  LDA sprite6_tile
  STA $0251
  CLC
  ADC #$01
  STA $0255
  CLC
  ADC #$01
  STA $0259
  CLC
  ADC #$01
  STA $025d

  ; write player ship tile atributes
  ; use palette 0
  LDA #$00
  STA $0252
  STA $0256
  STA $025a
  STA $025e

  ; store tile locations
  ; top left tile:
  LDA sprite6_y
  STA $0250
  LDA sprite6_x
  STA $0253
  ; top right tile (x + 8):
  LDA sprite6_y
  STA $0254
  LDA sprite6_x
  CLC
  ADC #$08
  STA $0257

  ; bottom left tile (y + 8):
  LDA sprite6_y
  CLC
  ADC #$08
  STA $0258
  LDA sprite6_x
  STA $025b

  ; bottom right tile (x + 8, y + 8)
  LDA sprite6_y
  CLC
  ADC #$08
  STA $025c
  LDA sprite6_x
  CLC
  ADC #$08
  STA $025f

  ; restore registers and return
  PLA 
  TYA
  PLA
  TAX 
  PLA 
  PLP 
  RTS 
.endproc

.proc draw_sprite7
  ; save registers
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA
  
  ; write player ship tile numbers
  LDA sprite7_tile
  STA $0261
  CLC
  ADC #$01
  STA $0265
  CLC
  ADC #$01
  STA $0269
  CLC
  ADC #$01
  STA $026d

  ; write player ship tile atributes
  ; use palette 0
  LDA #$00
  STA $0262
  STA $0266
  STA $026a
  STA $026e

  ; store tile locations
  ; top left tile:
  LDA sprite7_y
  STA $0260
  LDA sprite7_x
  STA $0263
  ; top right tile (x + 8):
  LDA sprite7_y
  STA $0264
  LDA sprite7_x
  CLC
  ADC #$08
  STA $0257

  ; bottom left tile (y + 8):
  LDA sprite7_y
  CLC
  ADC #$08
  STA $0268
  LDA sprite7_x
  STA $026b

  ; bottom right tile (x + 8, y + 8)
  LDA sprite7_y
  CLC
  ADC #$08
  STA $026c
  LDA sprite7_x
  CLC
  ADC #$08
  STA $025f

  ; restore registers and return
  PLA 
  TYA
  PLA
  TAX 
  PLA 
  PLP 
  RTS 
.endproc

.proc draw_sprite8
  ; save registers
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA
  
  ; write player ship tile numbers
  LDA sprite8_tile
  STA $0271
  CLC
  ADC #$01
  STA $0275
  CLC
  ADC #$01
  STA $0279
  CLC
  ADC #$01
  STA $027d

  ; write player ship tile atributes
  ; use palette 0
  LDA #$00
  STA $0272
  STA $0276
  STA $027a
  STA $027e

  ; store tile locations
  ; top left tile:
  LDA sprite8_y
  STA $0270
  LDA sprite8_x
  STA $0273
  ; top right tile (x + 8):
  LDA sprite8_y
  STA $0274
  LDA sprite8_x
  CLC
  ADC #$08
  STA $0277

  ; bottom left tile (y + 8):
  LDA sprite8_y
  CLC
  ADC #$08
  STA $0278
  LDA sprite8_x
  STA $027b

  ; bottom right tile (x + 8, y + 8)
  LDA sprite8_y
  CLC
  ADC #$08
  STA $027c
  LDA sprite8_x
  CLC
  ADC #$08
  STA $027f

  ; restore registers and return
  PLA 
  TYA
  PLA
  TAX 
  PLA 
  PLP 
  RTS 
.endproc

.proc draw_sprite9
  ; save registers
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA
  
  ; write player ship tile numbers
  LDA sprite9_tile
  STA $0281
  CLC
  ADC #$01
  STA $0285
  CLC
  ADC #$01
  STA $0289
  CLC
  ADC #$01
  STA $028d

  ; write player ship tile atributes
  ; use palette 0
  LDA #$00
  STA $0282
  STA $0286
  STA $028a
  STA $028e

  ; store tile locations
  ; top left tile:
  LDA sprite9_y
  STA $0280
  LDA sprite9_x
  STA $0283
  ; top right tile (x + 8):
  LDA sprite9_y
  STA $0284
  LDA sprite9_x
  CLC
  ADC #$08
  STA $0287

  ; bottom left tile (y + 8):
  LDA sprite9_y
  CLC
  ADC #$08
  STA $0288
  LDA sprite9_x
  STA $028b

  ; bottom right tile (x + 8, y + 8)
  LDA sprite9_y
  CLC
  ADC #$08
  STA $028c
  LDA sprite9_x
  CLC
  ADC #$08
  STA $028f

  ; restore registers and return
  PLA 
  TYA
  PLA
  TAX 
  PLA 
  PLP 
  RTS 
.endproc

.proc draw_sprite10
  ; save registers
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA
  
  ; write player ship tile numbers
  LDA sprite10_tile
  STA $0291
  CLC
  ADC #$01
  STA $0295
  CLC
  ADC #$01
  STA $0299
  CLC
  ADC #$01
  STA $029d

  ; write player ship tile atributes
  ; use palette 0
  LDA #$00
  STA $0292
  STA $0296
  STA $029a
  STA $029e

  ; store tile locations
  ; top left tile:
  LDA sprite10_y
  STA $0290
  LDA sprite10_x
  STA $0293
  ; top right tile (x + 8):
  LDA sprite10_y
  STA $0294
  LDA sprite10_x
  CLC
  ADC #$08
  STA $0297

  ; bottom left tile (y + 8):
  LDA sprite10_y
  CLC
  ADC #$08
  STA $0298
  LDA sprite10_x
  STA $029b

  ; bottom right tile (x + 8, y + 8)
  LDA sprite10_y
  CLC
  ADC #$08
  STA $029c
  LDA sprite10_x
  CLC
  ADC #$08
  STA $029f

  ; restore registers and return
  PLA 
  TYA
  PLA
  TAX 
  PLA 
  PLP 
  RTS 
.endproc

.proc draw_sprite11
  ; save registers
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA
  
  ; write player ship tile numbers
  LDA sprite11_tile
  STA $02a1
  CLC
  ADC #$01
  STA $02a5
  CLC
  ADC #$01
  STA $02a9
  CLC
  ADC #$01
  STA $02ad

  ; write player ship tile atributes
  ; use palette 0
  LDA #$00
  STA $02a2
  STA $02a6
  STA $02aa
  STA $02ae

  ; store tile locations
  ; top left tile:
  LDA sprite11_y
  STA $02a0
  LDA sprite11_x
  STA $02a3
  ; top right tile (x + 8):
  LDA sprite11_y
  STA $02a4
  LDA sprite11_x
  CLC
  ADC #$08
  STA $02a7

  ; bottom left tile (y + 8):
  LDA sprite11_y
  CLC
  ADC #$08
  STA $02a8
  LDA sprite11_x
  STA $02ab

  ; bottom right tile (x + 8, y + 8)
  LDA sprite11_y
  CLC
  ADC #$08
  STA $02ac
  LDA sprite11_x
  CLC
  ADC #$08
  STA $02af

  ; restore registers and return
  PLA 
  TYA
  PLA
  TAX 
  PLA 
  PLP 
  RTS 
.endproc

.proc draw_sprite12
  ; save registers
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA
  
  ; write player ship tile numbers
  LDA sprite12_tile
  STA $02b1
  CLC
  ADC #$01
  STA $02b5
  CLC
  ADC #$01
  STA $02b9
  CLC
  ADC #$01
  STA $02bd

  ; write player ship tile atributes
  ; use palette 0
  LDA #$00
  STA $02b2
  STA $02b6
  STA $02ba
  STA $02be

  ; store tile locations
  ; top left tile:
  LDA sprite12_y
  STA $02b0
  LDA sprite12_x
  STA $02b3
  ; top right tile (x + 8):
  LDA sprite12_y
  STA $02b4
  LDA sprite12_x
  CLC
  ADC #$08
  STA $02a7

  ; bottom left tile (y + 8):
  LDA sprite12_y
  CLC
  ADC #$08
  STA $02b8
  LDA sprite12_x
  STA $02bb

  ; bottom right tile (x + 8, y + 8)
  LDA sprite12_y
  CLC
  ADC #$08
  STA $02bc
  LDA sprite12_x
  CLC
  ADC #$08
  STA $02bf

  ; restore registers and return
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
