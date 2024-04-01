.include "constants.inc"
.include "header.inc"

.segment "ZEROPAGE"
player_x: .res 1
player_y: .res 1
player_dir: .res 1
scroll: .res 1
ppuctrl_settings: .res 1
pad1: .res 1

; These are the new ones I've added to animate and whatnot
animation: .res 2
offset: .res 2
tick: .res 3
sprite: .res 8
.exportzp player_x, player_y, pad1

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

	LDA scroll
	CMP #$00 ; did we scroll to the end of a nametable?
	BNE set_scroll_positions
	; if yes,
	; Update base nametable
	LDA ppuctrl_settings
	EOR #%00000010 ; flip bit 1 to its opposite
	STA ppuctrl_settings
	STA PPUCTRL
	LDA #240
	STA scroll

set_scroll_positions:
	LDA #$00 ; X scroll first
	STA PPUSCROLL
	DEC scroll
	LDA scroll ; then Y scroll
	STA PPUSCROLL

  RTI
.endproc

.import reset_handler
.import draw_starfield
.import draw_objects

.export main
.proc main
	LDA #239	 ; Y is only 240 lines tall!
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

; The update_player subroutine will now also take care of letting
; the draw_player subroutine know what sprite should it draw and 
; if it should animate it.

; This will be done by changing the `sprite` here, the `sprite` 
; is the first tile for each direction and animation. For example,
; $04 is the first tile looking upwards.

; Steps:
;   1. Modify update_player to change the `sprite` depending on direction
;
;   2. For now, always animate, afterwards, add the `animation` condition
;      so that we only animate if there is a button being pressed.


.proc update_player
  PHP  ; Start by saving registers,
  PHA  ; as usual.
  TXA
  PHA
  TYA
  PHA

  LDA pad1        ; Load button presses
  AND #BTN_LEFT   ; Filter out all but Left
  BEQ check_right ; If result is zero, left not pressed


  DEC player_x  ; If the branch is not taken, move player left
  LDX #$28        ; This is the first tile that looks left
  STX sprite  ; Store it in sprite :)

check_right:
  LDA pad1
  AND #BTN_RIGHT
  BEQ check_up


  INC player_x
  LDX #$10        ; First Tile Looking Right       
  STX sprite  ; Yup, we store it 

check_up:
  LDA pad1
  AND #BTN_UP
  BEQ check_down


  DEC player_y
  LDX #$04        ; First Tile Looking Up       
  STX sprite  ; Yup, we store it here too

check_down:
  LDA pad1
  AND #BTN_DOWN
  BEQ done_checking


  INC player_y
  LDX #$1C        ; First Tile Looking Down       
  STX sprite  ; Yup, last one.

done_checking:
  PLA ; Done with updates, restore registers
  TAY ; and return to where we called this
  PLA
  TAX
  PLA
  PLP
  RTS
.endproc


; The draw_player subroutine must also be update so that it's more
; dynamic. We want it to render whatever is in `sprite` which could
; change depending on the button being pressed.

; Steps:
;   1. Modify the subroutine so that it draws tiles based on the `sprite`.
;
;   2. Create, Update and Check the `Tick` so that we can animate.
;
;   3. Apply the same with the `offset`, so that we can animate the following
;      tiles after `sprite` to form the animation.
;
;   4. Make sure to reset these when the animation is completed, I plan for this
;   to take 20 ticks per sprite. Once we animate all ticks, return to original sprite
;   which would be done by setting the offset to 0.
;
;   5. Set the conditional `animation` to decide whether we'll animate or not.

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


  ; First, Increase the Tick
  LDX tick
  INX
  STX tick


  ; The Tick is in X, so check if it has hit either 20 or 40 ticks.
  LDX tick
  CPX #$14    ; This is 20 Decimal I think
  BEQ move_sprite

  CPX #$28
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

; Change this to our CHR
.segment "CHR"
.incbin "all_tiles.chr"
