.include "constants.inc"

.segment "ZEROPAGE"

temp_x :        .res 1
temp_y:         .res 1
mod:            .res 1

; Import the zero page stuff for collision detection, player_y and player_z
.importzp player_x, player_y
.importzp top_left_y, top_left_x, top_right_y, top_right_x
.importzp bot_left_y, bot_left_x, bot_right_y, bot_right_x
.importzp top_left_index, top_right_index, bot_left_index, bot_right_index


.segment "CODE"


;   Turn player_x and player_y into tile positions:::::::::
;   ::::::::refer to the document for this on the procedure
;                      ¯\_(ツ)_/¯ 
;   doc: https://docs.google.com/document/d/182yE6WjFQP4i3Bxazva5xEl3J7vwbtTJ5VUnQCnq8XY/edit?usp=sharing
.export get_tile_position
.proc get_tile_position
  PHA
  TXA
  PHA
  PHP


    ; GET TOP LEFT ::::::: 
    ; ::::::::::: POSITONS
    LDA player_x
    LSR             ; Three Logical Shift Right
    LSR             ; allows us to divide by 2^3
    LSR
    STA top_left_x


    LDA player_y
    LSR             ; Just doing the same shit
    LSR             ; but for player_y
    LSR
    STA top_left_y

    ; The whole point here is to initialize
    ; top_left_x and top_left_y really. I can
    ; leave the whole tile shit to the collisions

    ; I can actually just use it to get ALL positions
    ; way easier brah. At least get their Index yknow



    ; ::::::: GET TOP RIGHT
    ; POSITIONS!!! ::::::::

    ; To get X:
    ;   - temp   = player_x + 16
    ;   - mod    = (temp) % 16
    ;   - X      = temp + bool(mod) [bool = 0 or 1]
    LDA player_x
    CLC
    ADC #$10        ; Add +16 since we're to the right
    AND #%00010000  ; mod % 16
    CMP #$00        ; check if it's 0
    BNE plus_one    ; if not 0, add one

    ; If it's 0, don't add anything, just
    LDX top_left_x
    INX
    STX top_right_x

    JMP next_step

    no_add:
        LDA top_left_x
        CLC
        ADC #02
        STA top_right_x

    next_step:
    
    ; Now we've got to calculate top_right_y, but that's
    ; just the same as top_left_y soooo
    LDA top_left_y      ; copy
    STA top_right_y     ; paste-ish

    ; Now we've got to compute the index, that's it.
    ; problem is... we have to do the low and high bit bs
    ; I'll do the same thing we did w/ MYb MXb before.
    



  PLP
  PLA
  TAX
  PLA
  RTS
.endproc


; Check if there is a collision above. For this we will use
;       - top_left_x   &   top_left_y
;       - top_right_x  &   top_right_y
.export check_up
.proc check_up
  PHA
  TXA
  PHA
  PHP

    ; We will always have top


  PLP
  PLA
  TAX
  PLA
  RTS
.endproc



.export check_up
.proc check_up
  PHA
  TXA
  PHA
  PHP

  PLP
  PLA
  TAX
  PLA
  RTS
.endproc



.export check_down
.proc check_down
  PHA
  TXA
  PHA
  PHP

  PLP
  PLA
  TAX
  PLA
  RTS
.endproc



.export check_left
.proc check_left
  PHA
  TXA
  PHA
  PHP

  PLP
  PLA
  TAX
  PLA
  RTS
.endproc



.export check_right
.proc check_right
  PHA
  TXA
  PHA
  PHP

  PLP
  PLA
  TAX
  PLA
  RTS
.endproc