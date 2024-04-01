.include "constants.inc"
.include "header.inc"

.segment "ZEROPAGE"
player_x: .res 1
player_y: .res 1
player_dir: .res 1
scroll: .res 1
ppuctrl_settings: .res 1
pad1: .res 1
first_tile: .res 4
animation: .res 1
tick: .byte $00
.exportzp player_x, player_y, pad1
; Don't have to export first_tile, animation, tick cus im using them here

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
	LDA #$00



	; read controller
	JSR read_controller1

  ; update tiles *after* DMA transfer
	; and after reading controller state
	JSR update_player
  JSR draw_player

  RTI
.endproc

.import reset_handler
.import draw_starfield
.import draw_objects

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
	STA ppuctrl_settings
  STA PPUCTRL
  LDA #%00011110  ; turn on screen
  STA PPUMASK

forever:
  JMP forever
.endproc

; 
; How can I handle the changes?

;   For now, update_player only moves coordinates, it doesn't really
;   do anything else. Similarly, the draw_player subroutine only
;   renders a static sprite of the ship, not useful either.

;   In our case, we need the following:

;     - Move the character (done by default)
;     - Change  Sprite to display direction.
;     - Animate Sprite based on direction (only if moving)


;   So, we already know we'd have to heavily modify both subroutines,
;   where could we start, what are some ideas?

;     - The update_player could help by changing the sprite 
;       to the first one that indicates direction for the button pressed.
;       Let's refer to this first tile as the first_tile.

;         For example, Tile $04 is the First Tile for the Up-Direction,
;         with $05,$06,$07 following it to complete the Sprite. If there
;         were an animation, we'd need to iterate over the next 8 Tiles 
;         ( Next 2 Sprites) and then return to $04. 

;         If there is no animation (No Buttons Pressed), we'd iterate
;         over the same set of tiles.

;     - Get draw_player to draw animations, with ticks included and whatnot.
;       This can be done by making draw_player iterate over the next 11 tiles
;       from the first_tile (12 Tiles Total, 3 Sprites) and repeating that.

;     - If there is NO animation, we'd have draw_player to only draw the last
;       sprite that it was on, skipping any procedure to animate.

;   NOTES:

;     - Since we might refer to first_tile quite often, it has been called
;       in the Zero Page :).

;     - A "boolean" called `animation` has also been turned on. This will
;       have the values 0 or 1 to indicate whether a Button has been pressed
;       or not.

;     - Also created a `tick` in the zero page to slow down animation.

; 

.proc update_player
  PHP  ; Start by saving registers,
  PHA  ; as usual.
  TXA
  PHA
  TYA
  PHA

  ; By default, assume we're animating, if we aren't it will
  ; be corrected on the `done_checking` label.
  LDX #$01
  STX animation

  LDA pad1        ; Load button presses
  AND #BTN_LEFT   ; Filter out all but Left
  BEQ check_right ; If result is zero, left not pressed

  DEC player_x  ; If the branch is not taken, move player left
  LDX #$28        ; This is the first tile that looks left
  STX first_tile  ; Store it in first tile :)
  JMP end


check_right:
  LDA pad1
  AND #BTN_RIGHT
  BEQ check_up

  INC player_x
  LDX #$10        ; First Tile Looking Right       
  STX first_tile  ; Yup, we store it 
  JMP end 


check_up:
  LDA pad1
  AND #BTN_UP
  BEQ check_down

  DEC player_y
  LDX #$04        ; First Tile Looking Up       
  STX first_tile  ; Yup, we store it here too
  JMP end 


check_down:
;   LDA pad1
;   AND #BTN_DOWN
;   BEQ done_checking

  INC player_y
  LDX #$1C        ; First Tile Looking Down       
  STX first_tile  ; Yup, last one.
  JMP end 


done_checking:
  ; We will only get here if no button was pressed at all, otherwise
  ; they would jup to the label below, end. All that we'll do here
  ; is to tell our program that we're not animating cus nothing was pressed.
  LDX #$00
  STX animation

  ; Also reset the tick to 0
  LDX #$00
  STX tick


end:

  PLA ; Done with updates, restore registers
  TAY ; and return to where we called this
  PLA
  TAX
  PLA
  PLP
  RTS
.endproc


; I believe that this will just keep calling on itself (NMI)
; forever so there's no need to make any self-calls.
.proc draw_player
  ; save registers
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  ; Start rendering sprite!
  ; by having Y as an offset, we should be able to
  ; animate the sprite... not working though.
  LDA first_tile, Y      
  STA $0201

  LDA first_tile, Y
  CLC 
  ADC #$01
  STA $0205

  LDA first_tile, Y
  CLC 
  ADC #$02
  STA $0209


  LDA first_tile, Y
  CLC 
  ADC #$03
  STA $020d
  ; Done rendering the sprite!


  ; Here, return first_tile to original value.
  ; if it has to be altered (move to next), 
  ; then that will be done below.

  ; Actually, I don't think that this has to be done
  ; the code above only alters the accumulator!


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


  ; All the ticking and stuff can be done here.

  ;   What should I do first? I say, create the conditional
  ;   for animation


  ; if it's 0, then we don't animate and jump to end of subroutine
;   LDX animation
;   CPX #$00
;   BEQ end_draw
;   Otherwise, do all the animating stuff here!

  
  ; Increase the Tick + 1
  LDX tick
  INX
  STX tick



  ; Check if Tick == 20 (Time to move to 2nd sprite of animation)
  LDX tick
  CPX #$14          ; This is 20 Decimal.
  BEQ move_sprite   ; if tick == 20, move sprite

  ; Check if Tick == 40 (Time to move to 3rd sprite of animation)
  LDX tick
  CPX #$28          ; This is 40 Decimal.
  BEQ move_sprite   ; if tick == 40, move sprite

  ; Check if Tick == 60 (Time to reset the animation!)
  LDX tick
  CPX #$3C      ; This is 60 Decimal.
  BEQ reset_sprite


  ; If no comparison works, jump to end
  JMP end_draw

  move_sprite:
    ; Increase Y by 4
    INY
    INY
    INY
    INY
    JMP end_draw

  reset_sprite:

    ; Reset Y
    LDY #$00

    ; Reset tick
    LDA #$00
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

.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

.segment "RODATA"
palettes:
.byte $0f, $12, $23, $27
.byte $0f, $2b, $3c, $39
.byte $0f, $0c, $07, $13
.byte $0f, $19, $09, $29

.byte $0f, $2d, $10, $15
.byte $0f, $19, $09, $29
.byte $0f, $19, $09, $29
.byte $0f, $19, $09, $29

; Have to change the .chr to the proper one!
.segment "CHR"
.incbin "all_tiles.chr"
