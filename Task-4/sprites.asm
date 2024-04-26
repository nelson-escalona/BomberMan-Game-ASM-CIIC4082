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
dec_mega: .res 1
scroll: .res 1
ppuctrl_settings: .res 1
pad1: .res 1
background_flag: .res 1
checker: .res 1
.exportzp m_index, pad1

.segment "CODE"
.proc irq_handler
  RTI
.endproc

.import read_controller1

.proc nmi_handler
  LDA #$00
  STA OAMADDR
  LDA #$02
  STA OAMDMA

  LDX background_flag

  JSR read_controller1
  JSR check_for_background_change

  ; update tiles *after* DMA transfer

  LDA scroll
  CMP #$00
  BNE set_scroll_positions

  LDA ppuctrl_settings
  EOR #%00000001
  STA ppuctrl_settings
  STA PPUCTRL
  LDA #00
  STA scroll

set_scroll_positions:
  INC scroll
  LDA scroll
  STA PPUSCROLL
  LDA #$00
  STA PPUSCROLL

  ; LDA #$00
  ; STA $2005
  ; STA $2005

  RTI
.endproc

.import reset_handler

.export main
.proc main
  LDA #255
  STA scroll
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

  ; LDA background_flag
  ; CMP #$01
  ; BEQ load_stage_2

  ; load_stage_1:
  ;   LDA #%10000110
  ;   STA PPUMASK
    JSR load_M_segment_stage1_left
    JSR load_M_segment_stage1_right
    ;JMP vblankwait
  
  ; load_stage_2:
  ;   LDA #%10000110
  ;   STA PPUMASK
  ;   JSR load_M_segment_stage2_left
  ;   JSR load_M_segment_stage2_right

vblankwait:       ; wait for another vblank before continuing
  BIT PPUSTATUS
  BPL vblankwait

  ;JSR load_M_segment
  ;JSR load_M_segment2

  LDA #%10010001  ; turn on NMIs, sprites use first pattern table
  STA ppuctrl_settings
  STA PPUCTRL
  LDA #%10011110  ; turn on screen
  STA PPUMASK

forever:
  LDA background_flag
  CMP #$01
  BEQ load_stage_2

  JMP forever
  
  load_stage_2:
    LDA PPUSTATUS
    LDA #%00000000
    STA PPUCTRL
    STA PPUMASK
    JSR load_M_segment_stage2_left
    JSR load_M_segment_stage2_right
    LDA #$00
    STA background_flag
    LDA #$00
    STA scroll
    JMP vblankwait

  JMP forever
.endproc

.proc load_M_segment_stage1_left
  ; save registers
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  LoopMindex_stage1_left:
    ; Here, we'll be getting the (X,Y) for the Mega Index
    ; from our m_index. This is what was done in the video
    ; in which the professor provides the following steps:
    ;       MYb = Mindex/4 (or Mindex>>2); 
    ;       MXb = Mindex%4 (or Mindex&&0x03)

    LDA m_index ; load the current M index into A
    CLC
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
    CLC
    LSR A
    LSR A
    AND #$03
    STA index_high

    ; 2.1 Shift MXb 3 times left.
    LDA MXb
    CLC
    ASL A
    ASL A
    ASL A
    STA MXb

    ; 2.2 Shift MYb  6 times left.
    LDA MYb
    CLC
    ASL A
    ASL A
    ASL A
    ASL A
    ASL A
    ASL A

    ; 2.3 Add the two and store it.
    CLC
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
    JSR draw_mega_index_stage1_left

    ; Increase m_index
    LDX m_index
    CLC
    INX 
    STX m_index

    ; Check if Mindex != 59 (last index)
    LDX m_index
    CPX #$3C
    BNE LoopMindex_stage1_left
    LDA #$00
    STA m_index
  
  LoadAttributes_stage1_left:
    LDA PPUSTATUS
    LDA #$23
    STA PPUADDR
    LDA #$C0
    STA PPUADDR
    LDX #$00
  
  Load_Attributes_Loop_stage1_left:
    LDA attribute_stage1_left, X
    STA PPUDATA
    INX
    CPX #$40
    BNE Load_Attributes_Loop_stage1_left
  
  PLA 
  TYA
  PLA
  TAX 
  PLA 
  PLP 
  RTS 
.endproc

.proc draw_mega_index_stage1_left
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
  ; LDA index_low
  ; CLC
  ; ADC #%00000110
  ; STA index_low

  ; 1.1 Get byte from nametable and store it.
  ; NOTE : Might have to load m_index to Y so that
  ;        we can actually use it as an offset.
  LDY m_index
  LDA stage1left, Y
  STA current_byte

  Iter_megatile_stage1_left:

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
    ; NOTE : We start at the 4th mega tile. CASE: MINDEX = 48
    LDA current_byte  ; = 01111111
    AND #%00000011    ; = 00000011
    ; LSR A
    ; LSR A
    ; LSR A
    ; LSR A
    ; LSR A
    ; LSR A
    STA current_mega  ; = 00000011

    ;;;;;;;;;;; GOOD UP TIL NOW


    ; Here we'll do some sort of decoding to determine what tile
    ; it should be... for example
    ;
    ;   00 = Black BG = Any big number, say $70
    ;   01 = Stone = $34
    ;   10 = Brick = $38
    ;   11 = Bushes = $40

    JSR decode_mega_stage1


    ; Write INDEX+0 to PPUADDRESS
    LDA index_high
    CLC 
    ADC #$20
    STA PPUADDR   ; Write the high byte
    LDY index_low
    STY PPUADDR   ; Write the low byte
    ; Write Data to INDEX+0  | Offset = 0
    LDY dec_mega
    STY PPUDATA


    ; Repeat for INDEX+1
    LDA index_high
    CLC 
    ADC #$20
    STA PPUADDR     ; Write the high byte
    LDY index_low   ; Increase index_low
    CLC
    INY             ; and store in low bit
    STY PPUADDR
    ; Write Data to INDEX+1  |  Offset = 1
    LDA dec_mega
    CLC
    ADC #$01
    STA PPUDATA


    ; Repeat for INDEX+32
    LDA index_high
    CLC 
    ADC #$20
    STA PPUADDR   ; Write the high byte
    LDA index_low
    CLC
    ADC #32      ; Add 32! 
    STA PPUADDR   ; store it in low bit
    ; Write Data to INDEX+32  |  Offset = 2
    LDA dec_mega
    CLC
    ADC #$02
    STA PPUDATA


    ; Repeat for INDEX+33  
    LDA index_high
    CLC 
    ADC #$20
    STA PPUADDR   ; Write the high byte
    LDA index_low
    CLC
    ADC #33      ; Add 33! 
    STA PPUADDR   ; store it in low bit
    ; Write Data to INDEX+33  |  Offset = 3
    LDA dec_mega
    CLC
    ADC #$03
    STA PPUDATA





    ; Finished with all INDECES, decreasing index_low by 2!
    ; this is done so that we can move to the prev megatile
    LDA index_low
    CLC
    ADC #$02
    STA index_low

    ; Shift our curr_byte, as shown in the `MEGA_NAMETABLE` sheet.
    LDA current_byte
    CLC
    LSR A
    LSR A
    STA current_byte

    ; Loop Condition, if X != 4, Loop
    CLC
    INX                 ; X += 1
    CPX #$04            ; I forgot how the BEQ worke
    BNE Iter_megatile_stage1_left   ; if X != 4, keep loopin!

  ; Reset X just in case
  LDX #$00

  PLA 
  TYA
  PLA
  TAX 
  PLA 
  PLP 
  RTS 
.endproc

.proc load_M_segment_stage1_right
  ; save registers
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  LoopMindex_stage1_right:
    ; Here, we'll be getting the (X,Y) for the Mega Index
    ; from our m_index. This is what was done in the video
    ; in which the professor provides the following steps:
    ;       MYb = Mindex/4 (or Mindex>>2); 
    ;       MXb = Mindex%4 (or Mindex&&0x03)

    LDA m_index ; load the current M index into A
    CLC
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
    CLC
    LSR A
    LSR A
    AND #$03
    STA index_high

    ; 2.1 Shift MXb 3 times left.
    LDA MXb
    CLC
    ASL A
    ASL A
    ASL A
    STA MXb

    ; 2.2 Shift MYb  6 times left.
    LDA MYb
    CLC
    ASL A
    ASL A
    ASL A
    ASL A
    ASL A
    ASL A

    ; 2.3 Add the two and store it.
    CLC
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
    JSR draw_mega_index_stage1_right

    ; Increase m_index
    LDX m_index
    CLC
    INX 
    STX m_index

    ; Check if Mindex != 59 (last index)
    LDX m_index
    CPX #$3C
    BNE LoopMindex_stage1_right
    LDA #$00
    STA m_index

  LoadAttributes_stage1_right:
    LDA PPUSTATUS
    LDA #$27
    STA PPUADDR
    LDA #$C0
    STA PPUADDR
    LDX #$00
  
  Load_Attributes_Loop_stage1_right:
    LDA attribute_stage1_right, X
    STA PPUDATA
    INX
    CPX #$40
    BNE Load_Attributes_Loop_stage1_right

  PLA 
  TYA
  PLA
  TAX 
  PLA 
  PLP 
  RTS 
.endproc

.proc draw_mega_index_stage1_right
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
  ; LDA index_low
  ; CLC
  ; ADC #%00000110
  ; STA index_low

  ; 1.1 Get byte from nametable and store it.
  ; NOTE : Might have to load m_index to Y so that
  ;        we can actually use it as an offset.
  LDY m_index
  LDA stage1right, Y
  STA current_byte

  Iter_megatile_stage1_right:

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
    ; NOTE : We start at the 4th mega tile. CASE: MINDEX = 48
    LDA current_byte  ; = 01111111
    AND #%00000011    ; = 00000011
    ; LSR A
    ; LSR A
    ; LSR A
    ; LSR A
    ; LSR A
    ; LSR A
    STA current_mega  ; = 00000011

    ;;;;;;;;;;; GOOD UP TIL NOW


    ; Here we'll do some sort of decoding to determine what tile
    ; it should be... for example
    ;
    ;   00 = Black BG = Any big number, say $70
    ;   01 = Stone = $34
    ;   10 = Brick = $38
    ;   11 = Bushes = $40

    JSR decode_mega_stage1


    ; Write INDEX+0 to PPUADDRESS
    LDA index_high
    CLC 
    ADC #$24
    STA PPUADDR   ; Write the high byte
    LDY index_low
    STY PPUADDR   ; Write the low byte
    ; Write Data to INDEX+0  | Offset = 0
    LDY dec_mega
    STY PPUDATA


    ; Repeat for INDEX+1
    LDA index_high
    CLC 
    ADC #$24
    STA PPUADDR     ; Write the high byte
    LDY index_low   ; Increase index_low
    CLC
    INY             ; and store in low bit
    STY PPUADDR
    ; Write Data to INDEX+1  |  Offset = 1
    LDA dec_mega
    CLC
    ADC #$01
    STA PPUDATA


    ; Repeat for INDEX+32
    LDA index_high
    CLC 
    ADC #$24
    STA PPUADDR   ; Write the high byte
    LDA index_low
    CLC
    ADC #32      ; Add 32! 
    STA PPUADDR   ; store it in low bit
    ; Write Data to INDEX+32  |  Offset = 2
    LDA dec_mega
    CLC
    ADC #$02
    STA PPUDATA


    ; Repeat for INDEX+33  
    LDA index_high
    CLC 
    ADC #$24
    STA PPUADDR   ; Write the high byte
    LDA index_low
    CLC
    ADC #33      ; Add 33! 
    STA PPUADDR   ; store it in low bit
    ; Write Data to INDEX+33  |  Offset = 3
    LDA dec_mega
    CLC
    ADC #$03
    STA PPUDATA





    ; Finished with all INDECES, decreasing index_low by 2!
    ; this is done so that we can move to the prev megatile
    LDA index_low
    CLC
    ADC #$02
    STA index_low

    ; Shift our curr_byte, as shown in the `MEGA_NAMETABLE` sheet.
    LDA current_byte
    CLC
    LSR A
    LSR A
    STA current_byte

    ; Loop Condition, if X != 4, Loop
    CLC
    INX                 ; X += 1
    CPX #$04            ; I forgot how the BEQ worke
    BNE Iter_megatile_stage1_right   ; if X != 4, keep loopin!

  ; Reset X just in case
  LDX #$00

  PLA 
  TYA
  PLA
  TAX 
  PLA 
  PLP 
  RTS 
.endproc

.proc load_M_segment_stage2_left
  ; save registers
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  LoopMindex_stage2_left:
    ; Here, we'll be getting the (X,Y) for the Mega Index
    ; from our m_index. This is what was done in the video
    ; in which the professor provides the following steps:
    ;       MYb = Mindex/4 (or Mindex>>2); 
    ;       MXb = Mindex%4 (or Mindex&&0x03)

    LDA m_index ; load the current M index into A
    CLC
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
    CLC
    LSR A
    LSR A
    AND #$03
    STA index_high

    ; 2.1 Shift MXb 3 times left.
    LDA MXb
    CLC
    ASL A
    ASL A
    ASL A
    STA MXb

    ; 2.2 Shift MYb  6 times left.
    LDA MYb
    CLC
    ASL A
    ASL A
    ASL A
    ASL A
    ASL A
    ASL A

    ; 2.3 Add the two and store it.
    CLC
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
    JSR draw_mega_index_stage2_left

    ; Increase m_index
    LDX m_index
    CLC
    INX 
    STX m_index

    ; Check if Mindex != 59 (last index)
    LDX m_index
    CPX #$3C
    BNE LoopMindex_stage2_left
    LDA #$00
    STA m_index
  
  LoadAttributes_stage2_left:
    LDA PPUSTATUS
    LDA #$23
    STA PPUADDR
    LDA #$C0
    STA PPUADDR
    LDX #$00
  
  Load_Attributes_Loop_stage2_left:
    LDA attribute_stage2_left, X
    STA PPUDATA
    INX
    CPX #$40
    BNE Load_Attributes_Loop_stage2_left
  
  PLA 
  TYA
  PLA
  TAX 
  PLA 
  PLP 
  RTS 
.endproc

.proc draw_mega_index_stage2_left
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
  ; LDA index_low
  ; CLC
  ; ADC #%00000110
  ; STA index_low

  ; 1.1 Get byte from nametable and store it.
  ; NOTE : Might have to load m_index to Y so that
  ;        we can actually use it as an offset.
  LDY m_index
  LDA stage2left, Y
  STA current_byte

  Iter_megatile_stage2_left:

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
    ; NOTE : We start at the 4th mega tile. CASE: MINDEX = 48
    LDA current_byte  ; = 01111111
    AND #%00000011    ; = 00000011
    ; LSR A
    ; LSR A
    ; LSR A
    ; LSR A
    ; LSR A
    ; LSR A
    STA current_mega  ; = 00000011

    ;;;;;;;;;;; GOOD UP TIL NOW


    ; Here we'll do some sort of decoding to determine what tile
    ; it should be... for example
    ;
    ;   00 = Black BG = Any big number, say $70
    ;   01 = Stone = $34
    ;   10 = Brick = $38
    ;   11 = Bushes = $40

    JSR decode_mega_stage2


    ; Write INDEX+0 to PPUADDRESS
    LDA index_high
    CLC 
    ADC #$20
    STA PPUADDR   ; Write the high byte
    LDY index_low
    STY PPUADDR   ; Write the low byte
    ; Write Data to INDEX+0  | Offset = 0
    LDY dec_mega
    STY PPUDATA


    ; Repeat for INDEX+1
    LDA index_high
    CLC 
    ADC #$20
    STA PPUADDR     ; Write the high byte
    LDY index_low   ; Increase index_low
    CLC
    INY             ; and store in low bit
    STY PPUADDR
    ; Write Data to INDEX+1  |  Offset = 1
    LDA dec_mega
    CLC
    ADC #$01
    STA PPUDATA


    ; Repeat for INDEX+32
    LDA index_high
    CLC 
    ADC #$20
    STA PPUADDR   ; Write the high byte
    LDA index_low
    CLC
    ADC #32      ; Add 32! 
    STA PPUADDR   ; store it in low bit
    ; Write Data to INDEX+32  |  Offset = 2
    LDA dec_mega
    CLC
    ADC #$02
    STA PPUDATA


    ; Repeat for INDEX+33  
    LDA index_high
    CLC 
    ADC #$20
    STA PPUADDR   ; Write the high byte
    LDA index_low
    CLC
    ADC #33      ; Add 33! 
    STA PPUADDR   ; store it in low bit
    ; Write Data to INDEX+33  |  Offset = 3
    LDA dec_mega
    CLC
    ADC #$03
    STA PPUDATA





    ; Finished with all INDECES, decreasing index_low by 2!
    ; this is done so that we can move to the prev megatile
    LDA index_low
    CLC
    ADC #$02
    STA index_low

    ; Shift our curr_byte, as shown in the `MEGA_NAMETABLE` sheet.
    LDA current_byte
    CLC
    LSR A
    LSR A
    STA current_byte

    ; Loop Condition, if X != 4, Loop
    CLC
    INX                 ; X += 1
    CPX #$04            ; I forgot how the BEQ worke
    BNE Iter_megatile_stage2_left   ; if X != 4, keep loopin!

  ; Reset X just in case
  LDX #$00

  PLA 
  TYA
  PLA
  TAX 
  PLA 
  PLP 
  RTS 
.endproc

.proc load_M_segment_stage2_right
  ; save registers
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  LoopMindex_stage2_right:
    ; Here, we'll be getting the (X,Y) for the Mega Index
    ; from our m_index. This is what was done in the video
    ; in which the professor provides the following steps:
    ;       MYb = Mindex/4 (or Mindex>>2); 
    ;       MXb = Mindex%4 (or Mindex&&0x03)

    LDA m_index ; load the current M index into A
    CLC
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
    CLC
    LSR A
    LSR A
    AND #$03
    STA index_high

    ; 2.1 Shift MXb 3 times left.
    LDA MXb
    CLC
    ASL A
    ASL A
    ASL A
    STA MXb

    ; 2.2 Shift MYb  6 times left.
    LDA MYb
    CLC
    ASL A
    ASL A
    ASL A
    ASL A
    ASL A
    ASL A

    ; 2.3 Add the two and store it.
    CLC
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
    JSR draw_mega_index_stage2_right

    ; Increase m_index
    LDX m_index
    CLC
    INX 
    STX m_index

    ; Check if Mindex != 59 (last index)
    LDX m_index
    CPX #$3C
    BNE LoopMindex_stage2_right
    LDA #$00
    STA m_index

  LoadAttributes_stage2_right:
    LDA PPUSTATUS
    LDA #$27
    STA PPUADDR
    LDA #$C0
    STA PPUADDR
    LDX #$00
  
  Load_Attributes_Loop_stage2_right:
    LDA attribute_stage2_right, X
    STA PPUDATA
    INX
    CPX #$40
    BNE Load_Attributes_Loop_stage2_right

  PLA 
  TYA
  PLA
  TAX 
  PLA 
  PLP 
  RTS 
.endproc

.proc draw_mega_index_stage2_right
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
  ; LDA index_low
  ; CLC
  ; ADC #%00000110
  ; STA index_low

  ; 1.1 Get byte from nametable and store it.
  ; NOTE : Might have to load m_index to Y so that
  ;        we can actually use it as an offset.
  LDY m_index
  LDA stage2right, Y
  STA current_byte

  Iter_megatile_stage2_right:

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
    ; NOTE : We start at the 4th mega tile. CASE: MINDEX = 48
    LDA current_byte  ; = 01111111
    AND #%00000011    ; = 00000011
    ; LSR A
    ; LSR A
    ; LSR A
    ; LSR A
    ; LSR A
    ; LSR A
    STA current_mega  ; = 00000011

    ;;;;;;;;;;; GOOD UP TIL NOW


    ; Here we'll do some sort of decoding to determine what tile
    ; it should be... for example
    ;
    ;   00 = Black BG = Any big number, say $70
    ;   01 = Stone = $34
    ;   10 = Brick = $38
    ;   11 = Bushes = $40

    JSR decode_mega_stage2


    ; Write INDEX+0 to PPUADDRESS
    LDA index_high
    CLC 
    ADC #$24
    STA PPUADDR   ; Write the high byte
    LDY index_low
    STY PPUADDR   ; Write the low byte
    ; Write Data to INDEX+0  | Offset = 0
    LDY dec_mega
    STY PPUDATA


    ; Repeat for INDEX+1
    LDA index_high
    CLC 
    ADC #$24
    STA PPUADDR     ; Write the high byte
    LDY index_low   ; Increase index_low
    CLC
    INY             ; and store in low bit
    STY PPUADDR
    ; Write Data to INDEX+1  |  Offset = 1
    LDA dec_mega
    CLC
    ADC #$01
    STA PPUDATA


    ; Repeat for INDEX+32
    LDA index_high
    CLC 
    ADC #$24
    STA PPUADDR   ; Write the high byte
    LDA index_low
    CLC
    ADC #32      ; Add 32! 
    STA PPUADDR   ; store it in low bit
    ; Write Data to INDEX+32  |  Offset = 2
    LDA dec_mega
    CLC
    ADC #$02
    STA PPUDATA


    ; Repeat for INDEX+33  
    LDA index_high
    CLC 
    ADC #$24
    STA PPUADDR   ; Write the high byte
    LDA index_low
    CLC
    ADC #33      ; Add 33! 
    STA PPUADDR   ; store it in low bit
    ; Write Data to INDEX+33  |  Offset = 3
    LDA dec_mega
    CLC
    ADC #$03
    STA PPUDATA





    ; Finished with all INDECES, decreasing index_low by 2!
    ; this is done so that we can move to the prev megatile
    LDA index_low
    CLC
    ADC #$02
    STA index_low

    ; Shift our curr_byte, as shown in the `MEGA_NAMETABLE` sheet.
    LDA current_byte
    CLC
    LSR A
    LSR A
    STA current_byte

    ; Loop Condition, if X != 4, Loop
    CLC
    INX                 ; X += 1
    CPX #$04            ; I forgot how the BEQ worke
    BNE Iter_megatile_stage2_right   ; if X != 4, keep loopin!

  ; Reset X just in case
  LDX #$00

  PLA 
  TYA
  PLA
  TAX 
  PLA 
  PLP 
  RTS 
.endproc

.proc decode_mega_stage1
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA
  ; There are 4 possible codes : 00, 01, 10, 11

  LDA current_mega
  CMP #%00000000
  BEQ is_bg

  CMP #%00000001
  BEQ is_stone

  CMP #%00000010
  BEQ is_brick

  CMP #%00000011
  BEQ is_bush

  JMP done_dec

  is_bg:         ; Black BG
    LDA #$70
    STA dec_mega
    JMP done_dec

  is_stone:      ; Stone
    LDA #$34
    STA dec_mega
    JMP done_dec

  is_brick:      ; Brick
    LDA #$38
    STA dec_mega
    JMP done_dec

  is_bush:      ; Bush
    LDA #$40
    STA dec_mega

  done_dec:
  
  PLA 
  TYA
  PLA
  TAX 
  PLA 
  PLP 
  RTS 
.endproc

.proc decode_mega_stage2
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA
  ; There are 4 possible codes : 00, 01, 10, 11

  LDA current_mega
  CMP #%00000000
  BEQ is_bg2

  CMP #%00000001
  BEQ is_stone2

  CMP #%00000010
  BEQ is_brick2

  CMP #%00000011
  BEQ is_bush2

  JMP done_dec2

  is_bg2:         ; Black BG
    LDA #$70
    STA dec_mega
    JMP done_dec2

  is_stone2:      ; Stone
    LDA #$44
    STA dec_mega
    JMP done_dec2

  is_brick2:      ; Brick
    LDA #$48
    STA dec_mega
    JMP done_dec2

  is_bush2:      ; Bush
    LDA #$50
    STA dec_mega

  done_dec2:
  
  PLA 
  TYA
  PLA
  TAX 
  PLA 
  PLP 
  RTS 
.endproc

.proc check_for_background_change
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  LDA pad1
  AND #BTN_A
  BEQ finish_checking

  LDA #$01
  STA background_flag

  finish_checking:

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
  .byte $0f, $00, $10, $30 ;stone
  .byte $0f, $05, $16, $37 ;brick
  .byte $0f, $0B, $1A, $29 ;bush
  .byte $0f, $0f, $0f, $0f 

  .byte $0f ,$11, $21, $01
  .byte $0f, $19, $09, $29
  .byte $0f, $19, $09, $29
  .byte $0f, $19, $09, $29

stage1left:
  ; This is the flipped/inverted map
  .byte %01010101, %01010101, %01010101, %01010101
  .byte %11111101, %11111111, %00000010, %00000000
  .byte %11101101, %00111111, %10100010, %10101010
  .byte %10101101, %00101010, %00100010, %10000000
  .byte %00000001, %00100000, %10101110, %10111010
  .byte %10101001, %00100010, %00111111, %10111000
  .byte %00000001, %10100000, %10101010, %10111010
  .byte %10100001, %00101010, %11111111, %10111111
  .byte %00000001, %00100000, %10101010, %10111010
  .byte %10101001, %00100010, %00000010, %10111100
  .byte %11111101, %00101111, %10101110, %10001010
  .byte %10101101, %00101010, %00101110, %10000000
  .byte %11111101, %00111111, %10101110, %10001010
  .byte %11111100, %00111111, %11111110, %10001111
  .byte %01010101, %01010101, %01010101, %01010101
  ; This is the actual map
  ; .byte %01111111, %11111100, %10000000, %00000000
  ; .byte %01111011, %11111100, %10001010, %10101010
  ; .byte %01111010, %10101000, %10001000, %00000010
  ; .byte %01000000,	%00001000, %10111010,	%10100110
  ; .byte %01101010,	%10001000, %11111100,	%00101110
  ; .byte %01000000,	%00001010, %10101010,	%10101110
  ; .byte %01001010,	%10101000, %11111111, %11111110
  ; .byte %01000000,	%00001000, %10101010,	%10101110
  ; .byte %01101010,	%10001000, %10000000,	%00111110
  ; .byte %01111111,	%11111000, %10111010,	%10100010
  ; .byte %01111010,	%10101000, %10111000,	%00000010
  ; .byte %01111111,	%11111100, %10111010,	%10100010
  ; .byte %00111111,	%11111100, %10111111,	%11110010
  ; .byte %01010101,	%01010101, %01010101,	%01010101

stage1right:
  ; This is the flipped/inverted map
  .byte %01010101, %01010101, %01010101, %01010101
  .byte %10000000, %10111111, %10101000, %01101010
  .byte %10001000, %10111111, %00000000, %01000000
  .byte %10001000, %10001010, %10100010, %01001010
  .byte %00001000, %10000000, %00101111, %01000000
  .byte %10101000, %10101010, %10101111, %01101010
  .byte %10001000, %10000000, %11111111, %01111111
  .byte %10001000, %10001000, %10101110, %00111110
  .byte %10001000, %11001000, %11111111, %01111110
  .byte %10001000, %10101000, %10101010, %01111110
  .byte %10111000, %00001011, %00000000, %01111110
  .byte %11111000, %10001111, %00101010, %01111110
  .byte %10101000, %10001010, %11111111, %01101010
  .byte %00000000, %10000000, %11101111, %01111111
  .byte %01010101, %01010101, %01010101, %01010101
  ; This is the actual map
  ; .byte %01010101, %01010101, %01010101, %01010101
  ; .byte %00000010, %11111110, %00101010, %10101001
  ; .byte %00100010, %11111110, %00000000, %00000001
  ; .byte %00100010, %10100010, %10001010, %10100001
  ; .byte %00100000, %00000010, %11111000, %00000001
  ; .byte %00101010, %10101010, %11111010, %10101001
  ; .byte %00100010, %00000010, %11111111, %11111101
  ; .byte %00100010, %00100010, %10111010, %10111100
  ; .byte %00100010, %00100011, %11111111, %10111101
  ; .byte %00100010, %00101010, %10101010, %10111101
  ; .byte %00101110, %11100000, %00000000, %10111101
  ; .byte %00101111, %11110010, %10101000, %10111101
  ; .byte %00101010, %10100010, %11111111, %10101001
  ; .byte %00000000, %00000010, %11111011, %11111101
  ; .byte %01010101, %01010101, %01010101, %01010101

stage2left:
  .byte %01010101, %01010101, %01010101, %01010101
  .byte %11111101, %10111111, %11111111, %10111111
  .byte %10101101, %10111010, %10101011, %10111010
  .byte %00100001, %10110000, %00000111, %10001000
  .byte %00100001, %10101010, %10001011, %10001010
  .byte %00100001, %10110000, %10001011, %10001011
  .byte %10100001, %11110010, %10000011, %10001011
  .byte %00000000, %10110000, %10101010, %10001011
  .byte %00100001, %11110000, %10111111, %10001011
  .byte %00100001, %10101010, %10101010, %00001111
  .byte %00100001, %11000000, %10111111, %10001111
  .byte %10100001, %10101010, %10111011, %10001010
  .byte %00100001, %11000000, %11111011, %10001011
  .byte %00000001, %11000000, %11111011, %10001011
  .byte %01010101, %01010101, %01010101, %01010101

stage2right:
  .byte %01010101, %01010101, %01010101, %01010101
  .byte %10000000, %00000011, %11110000, %01111111
  .byte %10001000, %10101011, %10111010, %01101010
  .byte %10001000, %00111111, %10111000, %00001111
  .byte %10001000, %10101010, %10111000, %01001111
  .byte %00001000, %10111111, %10111000, %01001010
  .byte %10101000, %10111010, %11111000, %01001111
  .byte %00000000, %10111111, %10101000, %01001010
  .byte %10101000, %10101010, %11111111, %01001110
  .byte %11111000, %00000000, %11111011, %01001110
  .byte %10111000, %10101010, %10111011, %01101010
  .byte %11111000, %10000000, %10111011, %01111111
  .byte %10101000, %10001010, %10111011, %01101011
  .byte %00000000, %10000000, %11111111, %01111111
  .byte %01010101, %01010101, %01010101, %01010101

masks:
  .byte %11000000, %00110000, %00001100, %00000011

attribute_stage1_left:
  .byte %10000000, %10100000, %10100000, %11100000, %11010000, %11110000, %11110000, %11110000
  .byte %10001000, %01011001, %01011010, %11011110, %11011101, %11010101, %11110101, %01110101
  .byte %01001100, %01011111, %11011111, %11011101, %10101001, %11100101, %01110101, %01100110
  .byte %11001100, %01011111, %01011111, %11010101, %10100101, %10100101, %10100101, %01100110
  .byte %01001100, %01010000, %01010000, %00010101, %10010101, %10100101, %10100101, %01100110
  .byte %10001000, %01011010, %01011010, %00010001, %10011001, %00010101, %00000101, %01000100
  .byte %10001000, %10101010, %10101010, %00100010, %10011001, %10100101, %10100101, %01000100
  .byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000

attribute_stage1_right:
  .byte %00000000, %01000000, %10100000, %01100000, %01000000, %01010000, %01010000, %00010000
  .byte %01000100, %01000100, %01011010, %01000110, %00010000, %01010000, %01010000, %00000000
  .byte %01000100, %01010000, %01010000, %01010100, %10101010, %01010001, %01010000, %00010000
  .byte %01000100, %01000100, %01000000, %01000100, %10011010, %01011010, %10011010, %00100010
  .byte %01000100, %01000100, %01000100, %01011000, %01011010, %01011010, %10011001, %00100010
  .byte %01000100, %10100110, %10100110, %01000000, %01010000, %00010000, %10011001, %00100010
  .byte %00000100, %00000101, %00000101, %01000100, %10101010, %10011010, %10100101, %00100001
  .byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000

attribute_stage2_left:
  .byte %10000000, %10100000, %10100000, %01100000, %10100000, %10100000, %10100000, %01100000
  .byte %00001000, %00010101, %00000101, %01100110, %01100110, %00000101, %01000101, %01000110
  .byte %00000000, %00010001, %00000101, %01100101, %01100110, %01000100, %01100101, %01000100
  .byte %00000000, %00000101, %00000001, %01101010, %01010010, %01010100, %01100110, %01000100
  .byte %00000000, %00010001, %01010000, %01011010, %01011010, %01010110, %10100110, %00000100
  .byte %00000000, %01010001, %01010000, %01011000, %01101010, %01100110, %01011010, %01000100
  .byte %00000000, %00000001, %00000000, %10001000, %01100110, %10101010, %01100110, %01000100
  .byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000

attribute_stage2_right:
  .byte %00000000, %01000000, %00100000, %00000000, %00000000, %10100000, %10100000, %00100000
  .byte %01000100, %01000100, %10100110, %00100101, %01000101, %01100110, %10100101, %00000001
  .byte %01000100, %00000100, %10100101, %01100101, %01000100, %01100110, %01011010, %00000000
  .byte %00000100, %00000101, %10100101, %01100110, %01000100, %01011010, %01011010, %00000000
  .byte %01000100, %10100101, %00000101, %00000101, %01101010, %10101010, %10011001, %00000000
  .byte %01000100, %10100110, %00000101, %01000101, %01100110, %01100110, %10100101, %00100001
  .byte %00000100, %00000101, %00000101, %01000100, %10100110, %10100110, %10100110, %00100001
  .byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000

.segment "CHR"
.incbin "graphics.chr"

; These are zeros to degub background map.
; .byte %00000000, %00000000, %00000000, %00000000
; ca65 src/backgrounds.asm
; ca65 src/scrolling.asm
; ld65 src/backgrounds.o src/scrolling.o -C nes.cfg -o scrolling.nes