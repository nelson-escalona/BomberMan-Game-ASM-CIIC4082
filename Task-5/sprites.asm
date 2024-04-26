.include "constants.inc"
.include "header.inc"

.segment "ZEROPAGE"

; ZERO PAGE FOR TASK-5
top_left_y:       .res 1
top_left_x:       .res 1

top_right_y:      .res 1
top_right_x:      .res 1

bot_left_y:       .res 1
bot_left_x:       .res 1

bot_right_y:      .res 1
bot_right_x:      .res 1

top_left_index:   .res 1
top_right_index:  .res 1
bot_left_index:   .res 1
bot_right_index:  .res 1

top_left_mindex:   .res 1
top_right_mindex:  .res 1
bot_left_mindex:   .res 1
bot_right_mindex:  .res 1

top_left_col:   .res 1
top_right_col:  .res 1
bot_left_col:   .res 1
bot_right_col:  .res 1

temp_byte:      .res 1
.exportzp temp_byte
.exportzp top_left_y, top_left_x, top_right_y, top_right_x
.exportzp bot_left_y, bot_left_x, bot_right_y, bot_right_x
.exportzp top_left_index, top_right_index, bot_left_index, bot_right_index
.exportzp top_left_mindex, top_right_mindex, bot_left_mindex, bot_right_mindex
.exportzp top_left_col, top_right_col, bot_left_col, bot_right_col

; ZERO PAGE FOR TASK-4
ppu_high:         .res 1
m_index:          .res 1
MYb:              .res 1
MXb:              .res 1
index:            .res 1
index_high:       .res 1
index_low:        .res 1
current_byte:     .res 1
current_mega:     .res 1
dec_mega:         .res 1
scroll:           .res 1
ppuctrl_settings: .res 1

; ZERO PAGE FOR TASK-3
player_x:         .res 1
player_y:         .res 1
player_dir:       .res 1
pad1:             .res 1
animation:        .res 2
offset:           .res 2
tick:             .res 2
sprite:           .res 2

.exportzp m_index, player_x, player_y, pad1, sprite

.segment "CODE"
.proc irq_handler
  RTI
.endproc

; ::::::: IMPORT FUNCTIONS:::
; :::::::::::::::::::::::::::
.import get_top_left
.import get_top_right
.import read_controller1


.proc nmi_handler
  LDA #$00
  STA OAMADDR
  LDA #$02
  STA OAMDMA

	; read controller
	JSR read_controller1

  ; update tiles *after* DMA transfer
	; and after reading controller state
	JSR update_player
  JSR draw_player

  LDA #$00
  STA $2005     ; PPUSCROLL HIGH?
  STA $2005     ; PPUSCROLL LOW?

  RTI
.endproc

.import reset_handler

.export main
.proc main
  ; LDA #239
  ; STA scroll
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

  JSR load_M_segment
  JSR load_M_segment2

vblankwait:       ; wait for another vblank before continuing
  BIT PPUSTATUS
  BPL vblankwait

  ;JSR load_M_segment
  ;JSR load_M_segment2

  LDA #%10010000  ; turn on NMIs, sprites use first pattern table
  ; STA ppuctrl_settings
  STA PPUCTRL
  LDA #%10011110  ; turn on screen
  STA PPUMASK

forever:
  JMP forever
.endproc


.proc update_player
  PHP  ; Start by saving registers,
  PHA  ; as usual.
  TXA
  PHA
  TYA
  PHA

  ; By default, we will assume that there is a button being pressed
  ; if this is not the case, it will be corrected in `done_checking`
  LDA #$01
  STA animation
   

  LDA pad1        ; Load button presses
  AND #BTN_LEFT   ; Filter out all but Left
  BEQ check_right ; If result is zero, left not pressed


  DEC player_x  ; If the branch is not taken, move player left
  LDX #$28        ; This is the first tile that looks left
  STX sprite  ; Store it in sprite :)
  JMP end_updt

check_right:
  LDA pad1
  AND #BTN_RIGHT
  BEQ check_up


  JSR get_top_right ; tell the line below to eat dick 😂
  ; INC player_x    ; nope lil bro, leave that to the subroutine


  LDX #$10        ; First Tile Looking Right       
  STX sprite  ; Yup, we store it 
  JMP end_updt

check_up:
  LDA pad1
  AND #BTN_UP
  BEQ check_down


  JSR get_top_left


  LDX #$04        ; First Tile Looking Up       
  STX sprite  ; Yup, we store it here too
  JMP end_updt

check_down:
  LDA pad1
  AND #BTN_DOWN
  BEQ done_checking


  INC player_y
  LDX #$1C        ; First Tile Looking Down       
  STX sprite  ; Yup, last one.
  JMP end_updt


; This label indicates there was no button pressed, for which we will
; just reset the offset and the tick! Also set `animation` to #$00
done_checking:
  LDA #$00
  STA offset
  STA tick
  STA animation

end_updt:
  PLA ; Done with updates, restore registers
  TAY ; and return to where we called this
  PLA
  TAX
  PLA
  PLP
  RTS
.endproc

.proc draw_player
  ; save registers
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  ; LDA #$0C      ; Testing offset
  ; STA offset    ; Seems to work fine!


  ; Draw based on the `sprite` determined by button presses.
  LDA sprite
  CLC
  ADC offset
  STA $0201

  LDA sprite
  CLC
  ADC offset
  CLC
  ADC #$01
  STA $0205

  LDA sprite
  CLC
  ADC offset
  CLC
  ADC #$02
  STA $0209


  LDA sprite
  CLC
  ADC offset
  CLC
  ADC #$03
  STA $020d

  ; write player ship tile attributes
  ; use palette 0
  LDA #$00
  STA $0202
  STA $0206
  STA $020a
  STA $020e

  ; store tile locations
  ; top left tile:
  LDA player_y
  STA $0200
  LDA player_x
  STA $0203

  ; top right tile (x + 8):
  LDA player_y
  STA $0204
  LDA player_x
  CLC
  ADC #$08
  STA $0207

  ; bottom left tile (y + 8):
  LDA player_y
  CLC
  ADC #$08
  STA $0208
  LDA player_x
  STA $020b

  ; bottom right tile (x + 8, y + 8)
  LDA player_y
  CLC
  ADC #$08
  STA $020c
  LDA player_x
  CLC
  ADC #$08
  STA $020f


  ; Use this section to check conditions.
  ;   - Update Tick
  ;   - Check Tick
  ;
  ;   - Update Tile/offset if necessary


  ; Check if we're animating or not! If not, end draw_update
  LDA animation
  CMP #$00
  BEQ end_draw

  ; First, Increase the Tick
  LDX tick
  INX
  STX tick


  ; The Tick is in X, so check if it has hit either 20 or 40 ticks.
  LDX tick
  CPX #$14    ; This is 20 Decimal
  BEQ move_sprite

  CPX #$28    ; 40
  BEQ move_sprite


  ; Now, we check if the sprite is greater than or equal to 60,
  ; in which case we'd reset the sprite to it's first frame
  CLC   ; Clear the Carry before the comparison we're about to make!
  CPX #$3C    ; This is 60 Decimal
  BEQ reset_sprite    ; Equal
  BCS reset_sprite    ; Greater


  ; If no comparison worked, go to end!
  JMP end_draw

  ; We have to move to the next sprite, so all we'd have to do is to 
  ; move the offset + 4! (number of tiles per sprite = 4)
  move_sprite:
    LDA offset
    CLC
    ADC #$04
    STA offset

    JMP end_draw    ; JMP to End to avoid going into any other labels

  ; In this case, we'd have to set the offset back to $00 and the tick as well!
  reset_sprite:
    LDA #$00
    STA offset
    STA tick



  end_draw:
  ; restore registers and return
  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS
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
    JSR draw_mega_index

    ; Increase m_index
    LDX m_index
    CLC
    INX 
    STX m_index

    ; Check if Mindex != 59 (last index)
    LDX m_index
    CPX #$3C
    BNE LoopMindex
    LDA #$00
    STA m_index

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

    JSR decode_mega


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
    BNE Iter_megatile   ; if X != 4, keep loopin!

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

.proc load_M_segment2
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
    JSR draw_mega_index2

    ; Increase m_index
    LDX m_index
    CLC
    INX 
    STX m_index

    ; Check if Mindex != 59 (last index)
    LDX m_index
    CPX #$3C
    BNE LoopMindex
    LDA #$00
    STA m_index

  PLA 
  TYA
  PLA
  TAX 
  PLA 
  PLP 
  RTS 
.endproc


.proc draw_mega_index2
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

    JSR decode_mega


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
    BNE Iter_megatile   ; if X != 4, keep loopin!

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

.proc decode_mega
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


stage1leftfr:
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

masks:
  .byte %11000000, %00110000, %00001100, %00000011

attribute_stage1_left:
  .byte %10000000, %10100000, %10100000, %11100000, %11010000, %11110000, %11110000, %11110000
  .byte %10001000, %01011001, %01011010, %11011110, %11011101, %11010101, %11110101, %01110101
  .byte %01001100, %01011111, %11011111, %11011101, %10101001, %11100101, %01110101, %01100110
  .byte %11001100, %01011111, %01011111, %11010101, %10101001, %11100101, %01110101, %01100110
  .byte %11001100, %01010000, %01010000, %00010101, %10100101, %10100101, %10100101, %01100110
  .byte %01000000, %01010000, %00010000, %00010001, %00010101, %00000101, %10000101, %01100110
  .byte %10001000, %01011010, %01011010, %00010001, %10011001, %00010101, %00000101, %01000100
  .byte %10001000, %10101010, %10101010, %00100010, %10011001, %10100101, %10100101, %01000100

.segment "CHR"
.incbin "graphics.chr"

; These are zeros to degub background map.
; .byte %00000000, %00000000, %00000000, %00000000
; ca65 src/backgrounds.asm
; ca65 src/scrolling.asm
; ld65 src/backgrounds.o src/scrolling.o -C nes.cfg -o scrolling.nes


;ld65 Task-5/sprites.o Task-5/reset.o Task-5/controllers.o Task-5/collisions.o -C nes.cfg -o Task-5/task-5.nes

.export stage1leftfr