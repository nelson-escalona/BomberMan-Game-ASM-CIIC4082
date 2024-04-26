.include "constants.inc"

.segment "ZEROPAGE"

col_megatile:   .res 1
col_mindex:     .res 1
col_index:      .res 1
temp_byte:      .res 1
temp_mask:      .res 1
temp_check:     .res 1
masked_byte:    .res 1
masked_tile:    .res 1


; Import the zero page stuff for collision detection, player_y and player_z
.importzp player_x, player_y
.importzp top_left_y, top_left_x, top_right_y, top_right_x
.importzp bot_left_y, bot_left_x, bot_right_y, bot_right_x
.importzp top_left_index, top_right_index, bot_left_index, bot_right_index
.importzp top_left_mindex, top_right_mindex, bot_left_mindex, bot_right_mindex
.importzp top_left_col, top_right_col, bot_left_col, bot_right_col



.segment "CODE"


;   Turn player_x and player_y into tile positions:::::::::
;   ::::::::refer to the document for this on the procedure
;                      ¯\_(ツ)_/¯ 
;   doc: https://docs.google.com/document/d/182yE6WjFQP4i3Bxazva5xEl3J7vwbtTJ5VUnQCnq8XY/edit?usp=sharing
.import stage1left
.export get_top_left
.proc get_top_left
  PHA
  TXA
  PHA
  PHP

    ; Decrease player_y. This is just because
    ; we're currently checking for top collisions
    ; but top_left can also be used for left collisions
    ; so it's best to remove it later
    DEC player_y

    ; First, divide X by // 64
    LDA player_x
    LSR
    LSR
    LSR
    LSR
    LSR
    LSR
    STA top_left_x

    ; Repeat for Y
    LDA player_y
    LSR
    LSR
    LSR
    LSR
    LSR
    LSR
    STA top_left_y

    ; Get the Mindex, which is Y*8 + X
    LDA top_left_y  ; Load Y to accumulator
    ASL 3           ; Multiply Y by 8 (shift left by 3)


    CLC             ; Clear Carry Flag 
    ADC top_left_x  ; Add with 
    STA top_left_mindex ; Store result in top_left_mindex


    ; Now do X//16 % 4 to get megatile offset (0...3)
    LDA player_x
    LSR 4
    AND #$04
    STA top_left_index

    ; Good, currently we have the following:
    ;       top_left_x      : X // 64
    ;       top_left_y      : Y // 64
    ;       top_left_mindex : 8TLx+TLy
    ;       top_left_index  : Megatile Offset

    ; Now we just have to get the Mindex from 
    ; the current stage and check if there is 
    ; a collision or not!

    LDY top_left_mindex
    LDA stage1left, Y
    STA temp_byte

    ; We have the byte with the Mindex, now
    ; it's time to work with the offset!
    LDY top_left_index      ; get the offset
    LDA masks, Y            ; get mask for offset
    STA temp_mask

    LDA temp_byte           ; this is our byte, yea.
    AND temp_mask
    STA masked_byte         ; save it so we can then 
                            ; compare it

    LDA #%01010101          ; Full of stones
    AND temp_mask           ; Masked it
    STA masked_tile         ; save masked stones
    
    LDX masked_byte
    CPX masked_tile         ; compare it to stones
    BEQ detect_top          ; collision detected



    LDA #%10101010          ; Full of BRICKS
    AND temp_mask           ; Masked it
    STA masked_tile         ; saved masked BRICKS

    LDX masked_byte
    CPX masked_tile         ; compare it to BRICKS
    BEQ detect_top          ; collision detected

    JMP no_col_tl


    detect_top:
        ; set up the TL collision to #$01
        LDA #$01
        STA top_left_col
        INC player_y        ; set Y to original position
        JMP end_tl

    no_col_tl:
        ; set up the TL collision to #$00
        LDA #$00
        STA top_left_col


    end_tl:

  PLP
  PLA
  TAX
  PLA
  RTS
.endproc


.segment "RODATA"
masks:
  .byte %11000000, %00110000, %00001100, %00000011
