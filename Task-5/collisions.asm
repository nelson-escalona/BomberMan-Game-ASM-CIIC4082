.include "constants.inc"

.segment "ZEROPAGE"

temp_x:         .res 1
temp_y:         .res 1
col_megatile:   .res 1
col_mindex:     .res 1
col_index:      .res 1
temp_mask:      .res 1
temp_check:     .res 1
masked_byte:    .res 1
masked_tile:    .res 1



; Import the zero page stuff for collision detection, player_y and player_z
.importzp player_x, player_y, temp_byte
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
.import stage1leftfr
.export get_top_left
.proc get_top_left


    ; Decrease player_y. This is just because
    ; we're currently checking for top collisions
    ; but top_left can also be used for left collisions
    ; so it's best to remove it later
    DEC player_y

    ; Increase X by just 1 or 2 so that we can have 
    ; some space to pass by, causing the subroutine
    ; to detect one megatile to the left, and not the
    ; one to our left which would impede passing
    LDA player_x
    CLC
    ADC #$02
    STA temp_x


    ; First, divide X by // 64
    LDA temp_x
    LSR A
    LSR A
    LSR A
    LSR A
    LSR A
    LSR A
    STA top_left_x

    ; Next, divide Y // 16
    LDA player_y
    LSR A
    LSR A
    LSR A
    LSR A
    STA top_left_y

    ; Get the Mindex, which is Y*4 + X
    LDA top_left_y  ; Load Y to accumulator
    ASL A           ; Multiply Y by 8 (shift left by 3)
    ASL A
    STA top_left_y
    

    LDA top_left_y
    CLC             ; Clear Carry Flag 
    ADC top_left_x  ; Add with 4Y + X
    STA top_left_mindex ; Store result in top_left_mindex


    ; Now do X//16 % 4 to get megatile offset (0...3)
    LDA temp_x
    LSR A
    LSR A
    LSR A
    LSR A
    STA top_left_index      ; Store X//16 

    LDA top_left_index      ; Load X//16
    AND #$03                ; Apply % 4
    STA top_left_index      ; Save it

    ; Good, currently we have the following:
    ;       top_left_x      : X // 64
    ;       top_left_y      : Y // 64
    ;       top_left_mindex : 8TLx+TLy
    ;       top_left_index  : Megatile Offset

    ; Now we just have to get the Mindex from 
    ; the current stage and check if there is 
    ; a collision or not!

    LDY top_left_mindex
    LDA stage1leftfr, Y
    STA temp_byte

    ; ::::::::::::::::::::::::::::::::::::::::::::
    ;  MANUAL DEBUGGING, GOOD TIL HERE
    ; ::::::::::::::::::::::::::::::::::::::::::::


    ; What is our objective here? First, we should get
    ; the 2 bits for the megatile in which we're stepping
    ; in, this can be done with the help of `masks`.

    ; If our Offset = 0, the our mask will be 11 00 00 00
    ; indicating that we only care about the first megatile
    ; in which we're stepping on. We already get our entire
    ; 8-bit word from the 3 lines above, assume we're at
    ; Mindex 59, we'd get 01010101.

    ; If we mask this value with our mask, we'll get
    ;   01 00 00 00, which is accurate, because we 
    ;   only care about the first bit here.

    ; we can then generate a word of stones 01 01 01 01
    ; and also mask it, giving us 01 00 00 00
    ; we'd then compare these and check if it collided


    ; We have the byte with the Mindex, now
    ; it's time to work with the offset!
    LDY top_left_index      ; get the offset
    LDA masks, Y            ; get mask for offset
    STA temp_mask

    LDA temp_byte           ; this is our byte, yea.
    AND temp_mask           ; mask it to 11 00 00 00 (if offset = 0)
    STA masked_byte         ; save it so we can then 


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

        INC player_y
        JMP end_tl

    no_col_tl:
        ; set up the TL collision to #$00
        LDA #$00
        STA top_left_col


    end_tl:


  RTS
.endproc


.export get_top_right
.proc get_top_right

    ; I'll use this to check right-side collisions
    ; in that case, we'll increase Player X by one
    INC player_x


    ; First, we have to increase player_x by 16 
    ; since we're checking the top right ¯\_(ツ)_/¯
    LDA player_x
    CLC
    ADC #$10        ; Add 16!
    STA temp_x

    ; Now, divide X by // 64
    LDA temp_x
    LSR A
    LSR A
    LSR A
    LSR A
    LSR A
    LSR A
    STA top_right_x

    ; Next, divide Y // 16
    LDA player_y
    LSR A
    LSR A
    LSR A
    LSR A
    STA top_right_y

    ; Get the Mindex, which is Y*4 + X
    LDA top_right_y  ; Load Y to accumulator
    ASL A            ; Multiply Y by 8 (shift left by 3)
    ASL A
    STA top_right_y
    

    LDA top_right_y
    CLC                     ; Clear Carry Flag 
    ADC top_right_x         ; Add with 4Y + X
    STA top_right_mindex    ; Store result in top_right_mindex


    ; Now do X//16 % 3 to get megatile offset (0...3)
    LDA temp_x
    LSR A
    LSR A
    LSR A
    LSR A
    STA top_right_index      ; Store X//16 

    LDA top_right_index      ; Load X//16
    AND #$03                 ; Mask % 0...3
    STA top_right_index      ; Save it


    LDY top_right_mindex
    LDA stage1leftfr, Y
    STA temp_byte



    ; We have the byte with the Mindex, now
    ; it's time to work with the offset!
    LDY top_right_index      ; get the offset
    LDA masks, Y            ; get mask for offset
    STA temp_mask

    LDA temp_byte           ; this is our byte, yea.
    AND temp_mask           ; mask it to 11 00 00 00 (if offset = 0)
    STA masked_byte         ; save it so we can then 


    LDA #%01010101          ; Full of stones
    AND temp_mask           ; Masked it
    STA masked_tile         ; save masked stones
    
    LDX masked_byte
    CPX masked_tile         ; compare it to stones
    BEQ detect_top_right    ; collision detected


    LDA #%10101010          ; Full of BRICKS
    AND temp_mask           ; Masked it
    STA masked_tile         ; saved masked BRICKS

    LDX masked_byte
    CPX masked_tile         ; compare it to BRICKS
    BEQ detect_top_right    ; collision detected

    JMP no_col_tr


    detect_top_right:
        ; set up the TL collision to #$01
        LDA #$01
        STA top_right_col
        DEC player_x
        JMP end_tr

    no_col_tr:
        ; set up the TL collision to #$00
        LDA #$00
        STA top_right_col


    end_tr:


  RTS
.endproc




.export get_bot_left
.proc get_bot_left

    ; Going to use it for left-side collisions
    ; for such, we will be decreasing X-1
    DEC player_x

    ; We have to increase player_y by 15 
    ; since we're checking the bottom left ¯\_(ツ)_/¯
    ; NOTE: 15 so that we have some space 
    ; to pass, like we did for TL
    LDA player_y
    CLC
    ADC #$0F        ; Add 16!
    STA temp_y

    ; Now, divide X by // 64
    LDA player_x
    LSR A
    LSR A
    LSR A
    LSR A
    LSR A
    LSR A
    STA bot_left_x

    ; Next, divide Y // 16
    LDA temp_y
    LSR A
    LSR A
    LSR A
    LSR A
    STA bot_left_y

    ; Get the Mindex, which is Y*4 + X
    LDA bot_left_y  ; Load Y to accumulator
    ASL A            ; Multiply Y by 8 (shift left by 3)
    ASL A
    STA bot_left_y
    

    LDA bot_left_y
    CLC                     ; Clear Carry Flag 
    ADC bot_left_x         ; Add with 4Y + X
    STA bot_left_mindex    ; Store result in bot_left_mindex


    ; Now do X//16 % 3 to get megatile offset (0...3)
    LDA player_x
    LSR A
    LSR A
    LSR A
    LSR A
    STA bot_left_index      ; Store X//16 

    LDA bot_left_index      ; Load X//16
    AND #$03                 ; Mask % 0...3
    STA bot_left_index      ; Save it


    LDY bot_left_mindex
    LDA stage1leftfr, Y
    STA temp_byte



    ; We have the byte with the Mindex, now
    ; it's time to work with the offset!
    LDY bot_left_index      ; get the offset
    LDA masks, Y            ; get mask for offset
    STA temp_mask

    LDA temp_byte           ; this is our byte, yea.
    AND temp_mask           ; mask it to 11 00 00 00 (if offset = 0)
    STA masked_byte         ; save it so we can then 


    LDA #%01010101          ; Full of stones
    AND temp_mask           ; Masked it
    STA masked_tile         ; save masked stones
    
    LDX masked_byte
    CPX masked_tile         ; compare it to stones
    BEQ detect_bot_left    ; collision detected


    LDA #%10101010          ; Full of BRICKS
    AND temp_mask           ; Masked it
    STA masked_tile         ; saved masked BRICKS

    LDX masked_byte
    CPX masked_tile         ; compare it to BRICKS
    BEQ detect_bot_left    ; collision detected

    JMP no_col_BL


    detect_bot_left:
        ; set up the TL collision to #$01
        LDA #$01
        STA bot_left_col
        INC player_x

        JMP end_BL

    no_col_BL:
        ; set up the TL collision to #$00
        LDA #$00
        STA bot_left_col


    end_BL:


  RTS
.endproc

.export get_bot_right
.proc get_bot_right

    ; Going to use it for down-side collisions
    ; for such, we will be INC player
    INC player_y

    ; Bottom Right Corner has to increase both
    ; X and Y. I'll increase both by 15.
    LDA player_y
    CLC
    ADC #$0F        ; Add 15!
    STA temp_y

    LDA player_x
    CLC
    ADC #$0F        ; Add 15!
    STA temp_x


    ; Now, divide X by // 64
    LDA temp_x
    LSR A
    LSR A
    LSR A
    LSR A
    LSR A
    LSR A
    STA bot_right_x

    ; Next, divide Y // 16
    LDA temp_y
    LSR A
    LSR A
    LSR A
    LSR A
    STA bot_right_y

    ; Get the Mindex, which is Y*4 + X
    LDA bot_right_y  ; Load Y to accumulator
    ASL A            ; Multiply Y by 8 (shift left by 3)
    ASL A
    STA bot_right_y
    

    LDA bot_right_y
    CLC                     ; Clear Carry Flag 
    ADC bot_right_x         ; Add with 4Y + X
    STA bot_right_mindex    ; Store result in bot_right_mindex


    ; Now do X//16 % 3 to get megatile offset (0...3)
    LDA temp_x
    LSR A
    LSR A
    LSR A
    LSR A
    STA bot_right_index      ; Store X//16 

    LDA bot_right_index      ; Load X//16
    AND #$03                 ; Mask % 0...3
    STA bot_right_index      ; Save it


    LDY bot_right_mindex
    LDA stage1leftfr, Y
    STA temp_byte



    ; We have the byte with the Mindex, now
    ; it's time to work with the offset!
    LDY bot_right_index      ; get the offset
    LDA masks, Y            ; get mask for offset
    STA temp_mask

    LDA temp_byte           ; this is our byte, yea.
    AND temp_mask           ; mask it to 11 00 00 00 (if offset = 0)
    STA masked_byte         ; save it so we can then 


    LDA #%01010101          ; Full of stones
    AND temp_mask           ; Masked it
    STA masked_tile         ; save masked stones
    
    LDX masked_byte
    CPX masked_tile         ; compare it to stones
    BEQ detect_bot_right    ; collision detected


    LDA #%10101010          ; Full of BRICKS
    AND temp_mask           ; Masked it
    STA masked_tile         ; saved masked BRICKS

    LDX masked_byte
    CPX masked_tile         ; compare it to BRICKS
    BEQ detect_bot_right    ; collision detected

    JMP no_col_BR


    detect_bot_right:
        ; set up the TL collision to #$01
        LDA #$01
        STA bot_right_col
        DEC player_y

        JMP end_BR

    no_col_BR:
        ; set up the TL collision to #$00
        LDA #$00
        STA bot_right_col


    end_BR:


  RTS
.endproc

.segment "RODATA"
masks:
  .byte %11000000, %00110000, %00001100, %00000011
