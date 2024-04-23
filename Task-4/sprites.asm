.include "constants.inc"
.include "header.inc"

.segment "ZEROPAGE"
ppu_high: .res 1

m_index: .res 1
MYb: .res 1
MXb: .res 1


index: .res 1
index_high: .res 1
index_low: .res 1


current_byte: .res 1

; For Iter_whatever i did
current_mask: .res 1
current_mega: .res 1

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

  LoopMindex:
    ; Here, we'll be getting the (X,Y) for the Mega Index
    ; from our m_index. This is what was done in the video
    ; in which the professor provides the following steps:
    ;       MYb = Mindex/4 (or Mindex>>2); 
    ;       MXb = Mindex%4 (or Mindex&&0x03)

    LDA m_index ; load the current M index into A
    LSR A       ; first shift right
    LSR A       ; second shift right
    STA MYb     ; store A into MYb
    LDA m_index
    AND #$03    ; mask out the first two bits (from right to left)
    STA MXb     ; store A into MXb



    ; Here we'll be doing the new operation to be able to
    ; store the low and high bytes to get the `INDEX`.
    ; The steps for these are as follows:
    ;
    ;     1. Highbit = (MYb >> 2) AND 00000011;
    ;            - Shift MYb twice to the right
    ;            - Mask MYb AND $03 or %00000011
    ;
    ;     2. Lowbit = (MXB << 3) + (MYb << 6)
    ;            - Shift MXb 3 times to the left
    ;            - Shift MYb 6 times to the left
    ;            - Add the two and STA Lowbit.
    
    ; 1. Shift MYb twice and Mask it
    LDA MYb
    LSR A
    LSR A
    AND #$03
    STA index_high

    ; 2.1 Shift MXb 3 times left.
    LDA MXb
    ASL A
    ASL A
    ASL A
    STA MXb

    ; 2.2 Shift MYb  6 times left.
    LDA MYb
    ASL A
    ASL A
    ASL A
    ASL A
    ASL A
    ASL A

    ; 2.3 Add the two and store it.
    ADC MXb
    STA index_low

    ; Where are we at right now? Well we currently have our
    ; INDEX for the Top-Left of the MINDEX. With this, we can
    ; proceed to commence drawing the Mega Tiles inside this
    ; MINDEX. 
    ;
    ; Thus, we will need to commence writing to PPUDATA, we'll
    ; JSR into a new Subroutine that should write onto all the
    ; the tiles within this Mega Index!
    JSR draw_mega_index

    ; Increase m_index
    LDX m_index
    INX 
    STX m_index

    ; Check if Mindex != 59 (last index)
    LDX m_index
    CPX #$3B
    BNE LoopMindex 

  PLA 
  TYA
  PLA
  TAX 
  PLA 
  PLP 
  RTS 
.endproc


.proc draw_mega_index
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  ; At this point, we're inside the Top-Left till/index
  ; in our Mega Index. Our objectives are the following:
  ;
  ;     1. Iterate through each mega tile in the MINDEX
  ;        it should be four (4) of them! 
  ;
  ;         - Get our byte from the nametable. This can be
  ;           done by using the MINDEX as an offset for the
  ;           nametable e.g. ```LDA nametable, MINDEX```
  ;
  ;         - Draw to: (INDEX, INDEX+1, INDEX+32, INDEX+33)
  ;           effectively drawing to all 4 tiles in that space
  ;           and creating a Mega Tile. We can use masking to
  ;           get the byte that actually goes to each of these.
  ;
  ;         - Once we draw to the entirety of that Megatile,
  ;           we go onto the next by doing INDEX += 2. This
  ;           gives us the Top Left index of the next Mega Tile.
  ;
  ;
  ;    2. Repeat that process four (4) times and end subroutine.
  

  ; Use `X` Register as our Counter, Initialize at #$00
  LDX #$00


  ; PREP: Before getting into the Loop Below, increase index_low
  ;       by +6 so that it starts at the last Mega Tile and we will
  ;       
  LDA index_low
  CLC
  ADC #$06
  STA index_low

  ; 1.1 Get byte from nametable and store it.
  ; NOTE : Might have to load m_index to Y so that
  ;        we can actually use it as an offset.
  LDY m_index
  LDA stage1left, Y
  STA current_byte

  Iter_megatile:

    ; The way we decide which background tile will our nametable
    ; use is by masking the byte we get from the nametable, let me
    ; explain...
    ;
    ; Supposed we get %00011110, then we'll have:
    ;
    ;   MEGATILE 1  : 00          MEGATILE 2  : 01
    ;   MEGATILE 3  : 11          MEGATILE 4  : 10
    ;
    ; Cool, then let's write our megatiles.
    ;
    ; NOTE : we write INDEX to PPUADDRESS, and we define PPUADDRESS
    ;        by writing index_high and then index_low to it. So when 
    ;        increasing the index, just increase index_low + 2.
    ;
    ; NOTE : We'll write the same shit to each index, because the indices
    ;        are just tiles, not Megatiles, they're all composed of the
    ;        same tile that would make up a Megatile




    ; PREP : Mask our curr_byte so we can get the curr_mega
    LDA current_byte
    AND #%00000011
    STA current_mega


    ; Write INDEX+0 to PPUADDRESS
    LDA index_high
    CLC 
    ADC #$20
    STA PPUADDR   ; Write the high byte
    LDY index_low
    STY PPUADDR
    ; Write Data to INDEX+0
    LDY current_mega
    STY PPUDATA


    ; Repeat for INDEX+1
    LDA index_high
    CLC 
    ADC #$20
    STA PPUADDR     ; Write the high byte
    LDY index_low   ; Increase index_low
    INY             ; and store in low bit
    STY PPUADDR
    ; Write Data to INDEX+1
    LDY current_mega
    STY PPUDATA


    ; Repeat for INDEX+32
    LDA index_high
    CLC 
    ADC #$20
    STA PPUADDR   ; Write the high byte
    LDA index_low
    CLC
    ADC #$20      ; Add 32! 
    STA PPUADDR   ; store it in low bit
    ; Write Data to INDEX+32
    LDY current_mega
    STY PPUDATA


    ; Repeat for INDEX+33
    LDA index_high
    CLC 
    ADC #$20
    STA PPUADDR   ; Write the high byte
    LDA index_low
    CLC
    ADC #$21      ; Add 33! 
    STA PPUADDR   ; store it in low bit
    ; Write Data to INDEX+33
    LDY current_mega
    STY PPUDATA





    ; Finished with all INDECES, decreasing index_low by 2!
    ; this is done so that we can move to the prev megatile
    LDA index_low
    CLC
    SBC #$020
    STA index_low

    ; Shift our curr_byte, as shown in the `MEGA_NAMETABLE` sheet.
    LDA current_byte
    LSR A
    LSR A
    STA current_byte

    ; Loop Condition, if X != 4, Loop
    INX                 ; X += 1
    CPX #$04            ; I forgot how the BEQ worke
    BNE Iter_megatile   ; if X != 4, keep loopin!


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
  .byte $0f, $10, $10, $10
  .byte $0f, $10, $10, $10
  .byte $0f, $11, $11, $11
  .byte $0f, $11, $11, $11

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

masks:
  .byte %11000000, %00110000, %00001100, %00000011

.segment "CHR"
.incbin "graphics.chr"


; ca65 src/backgrounds.asm
; ca65 src/scrolling.asm
; ld65 src/backgrounds.o src/scrolling.o -C nes.cfg -o scrolling.nes