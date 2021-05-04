;****************************************************************;
;                         2º PROJETO IAC                         ;
;                            GRUPO 100                           ;
;                      Mafalda Ferreira - 92513                  ;
;                                                                ;
;****************************************************************;


;=================================================================
; CONSTANTS
;-----------------------------------------------------------------

N               EQU     80 ; number of positions in the terrain vector
STACK_INIT      EQU     8000h	; initial stack address
MAX_HEIGHT      EQU     4

; cursor positions for diferent objects
DEFAULT_CURSOR  EQU     A000h ; dinossaur default position ([4, 4])
DINO_JMP_CURSOR EQU     9A00h ; dinossaur address position when jumping
DINO_CURSOR     EQU     A300h ; dinossaur default address position in text window
GAMEOVER_CURSOR EQU     0523h ; game over address position in text window
GROUND_CURSOR   EQU     A400h ; ground adress position in text window

; game status
START           EQU     1
END             EQU     0

; Text window
TERM_WRITE      EQU     FFFEh
TERM_CURSOR     EQU     FFFCh
TERM_COLOR      EQU     FFFBh

; 7 segment display
DISP7_D0        EQU     FFF0h
DISP7_D1        EQU     FFF1h
DISP7_D2        EQU     FFF2h
DISP7_D3        EQU     FFF3h
DISP7_D4        EQU     FFEEh
DISP7_D5        EQU     FFEFh

; timer
TIMER_CONTROL   EQU     FFF7h ; <- counting interval
TIMER_COUNTER   EQU     FFF6h ; <- counting ON/OFF
TIMER_SETSTART  EQU     1
TIMERCOUNT_INIT EQU     1

; interruptions
INT_MASK        EQU     FFFAh
INT_MASK_VAL    EQU     8009h ; 1000 0000 0000 1001 b (time + keyup + keyzero)

;=================================================================
; Program global variables
;-----------------------------------------------------------------
                ORIG    3000h
x               WORD    7 ; global variable

; game status and objects
game_status     WORD    END ; indicates status of the game (START or END)
ground          STR     '-', 0 ; character that represents the ground
dino            STR     'd', 0 ; character that represents a dinossaur
cactus          STR     '#', 0 ; character that represents a cactus
gameover        STR     'GAME OVER', 0
jumping         WORD    0 ; indicates if dinossaur is jumping
jumping_moment  WORD    0 ; indicates the moment of the jump (0, 1, 2, 3 or 4)
jump_next       WORD    0 ; indicates if next jump is enabled

; timer interruptions
points          WORD    0 ; points that represent time elapsed
timer_countval  WORD    TIMERCOUNT_INIT ; states the current counting period
timer_tick      WORD    0 ; indicates the number of unattended time ticks

                ORIG    4000h
vec             TAB     N ; vector of game terrain with N positions
                
;=================================================================
; main: main point of the program
;-----------------------------------------------------------------                
                ORIG    0000h
main:           MVI     R6, STACK_INIT
                
                ; interrupt mask
                MVI     R1,INT_MASK
                MVI     R2,INT_MASK_VAL
                STOR    M[R1],R2
                ENI     ; enable interruptions
                
                MVI     R1, TERM_WRITE
                MVI     R2, TERM_CURSOR
                MVI     R3, GROUND_CURSOR
                STOR    M[R2], R3
                
                MVI     R2, N
generate_ground:MVI     R3, ground
                LOAD    R3, M[R3]
                STOR    M[R1], R3
                
                DEC     R2
                BR.NZ   generate_ground
                
wait_game:      ; wait for key zero to be enabled
                MVI     R4, game_status
                LOAD    R1, M[R4]
                CMP     R1, R0
                BR.Z    wait_game

                ; Clean "game over" in text window
                MVI     R1, TERM_WRITE
                MVI     R2, TERM_CURSOR
                MVI     R3, GAMEOVER_CURSOR
                STOR    M[R2], R3
                STOR    M[R1], R0
                STOR    M[R1], R0
                STOR    M[R1], R0
                STOR    M[R1], R0
                STOR    M[R1], R0
                STOR    M[R1], R0
                STOR    M[R1], R0
                STOR    M[R1], R0
                STOR    M[R1], R0

                MVI     R1, TERM_WRITE
                MVI     R2, MAX_HEIGHT
                DEC     R2
                
                ; reset cursor to default position
                MVI     R4, TERM_CURSOR
                MVI     R5, DEFAULT_CURSOR
                STOR    M[R4], R5

                ; Runs prepare clean until all (MAX_HEIGHT) main lines were cleaned
                ; line 1 to MAX_HEIGHT = cactus, space, dinossaur not jumping
prepare_clean:  ; Save R2 context
                DEC     R6
                STOR    M[R6], R2
                
                MVI     R2, N
                JAL     clean_window
                
                ; Restore R2 context
                LOAD    R2, M[R6]
                INC     R6
                
                DEC     R2
                JAL.NZ  prepare_clean
                
                ; Create dinossaur
                ; set position
                MVI     R2, TERM_CURSOR
                MVI     R4, DINO_CURSOR
                STOR    M[R2], R4
                ; write dinossaur to text window
                MVI     R4, dino
                LOAD    R5, M[R4]
                STOR    M[R1], R5
                
                JAL     start_game
end:            BR      end

;=================================================================
; clean_window: clean all text window positions of a specific line
;               parameters:
;                 R1 <- address to write to text window
;                 R2 <- number of positions in the vector
;-----------------------------------------------------------------

clean_window:   STOR    M[R1], R0
                DEC     R2
                BR.NZ   clean_window

                JMP     R7
                
;=================================================================
; start_game: starts game and keeps on going until it's game over
;-----------------------------------------------------------------


start_game:     ; reset points
                MVI     R1, points
                STOR    M[R1], R0
                
                ; sets global variable to 7
                MVI     R1, x
                MVI     R2, 7
                STOR    M[R1], R2
                
                ; reset jumping variables
                MVI     R1, jumping
                STOR    M[R1], R0
                MVI     R1, jumping_moment
                STOR    M[R1], R0
                MVI     R1, jump_next
                STOR    M[R1], R0
                
                MVI     R1, vec
                MVI     R2, N
clean_vec:      ; sets position value to zero
                STOR    M[R1], R0
                INC     R1
                
                DEC     R2
                CMP     R2, R0
                BR.P    clean_vec
                
                ; set timer
                MVI     R2, TIMERCOUNT_INIT
                MVI     R1, TIMER_COUNTER
                STOR    M[R1], R2 ; 1 * 100 ms = 0,1 s
                MVI     R1, timer_tick ; clear all timer ticks
                STOR    M[R1], R0
                MVI     R1, TIMER_CONTROL
                MVI     R2, TIMER_SETSTART
                STOR    M[R1], R2 ; start timer
                
loop:           ; wait for timer event
                MVI     R2, timer_tick
                LOAD    R1, M[R2]
                CMP     R1, R0
                BR.Z    loop
                
                ; decrease timer tick
                DSI     ; critical region
                LOAD    R1,M[R2]
                DEC     R1
                STOR    M[R2],R1
                ENI
                
                ; increase points (= time elapsed)
                MVI     R1, points
                LOAD    R2, M[R1]
                INC     R2
                STOR    M[R1], R2
                
                ; show points on display 0
                MVI     R3, fh
                AND     R3, R2, R3
                MVI     R1, DISP7_D0
                STOR    M[R1], R3
                
                ; show points on display 1
                SHR     R2
                SHR     R2
                SHR     R2
                SHR     R2
                MVI     R3, fh
                AND     R3, R2,R3
                MVI     R1, DISP7_D1
                STOR    M[R1], R3
                
                ; show points on display 2
                SHR     R2
                SHR     R2
                SHR     R2
                SHR     R2
                MVI     R3, fh
                AND     R3, R2, R3
                MVI     R1, DISP7_D2
                STOR    M[R1], R3
                
                ; show points on display 3
                SHR     R2
                SHR     R2
                SHR     R2
                SHR     R2
                MVI     R3, fh
                AND     R3, R2, R3
                MVI     R1, DISP7_D3
                STOR    M[R1], R3
                
                ; show points on display 4
                SHR     R2
                SHR     R2
                SHR     R2
                SHR     R2
                MVI     R3, fh
                AND     R3, R2, R3
                MVI     R1, DISP7_D4
                STOR    M[R1], R3
                
                ; show points on display 5
                SHR     R2
                SHR     R2
                SHR     R2
                SHR     R2
                MVI     R3, fh
                AND     R3, R2, R3
                MVI     R1, DISP7_D5
                STOR    M[R1], R3
                
                JAL     update_jumping_variables
                
                ; prepara os argumentos para chamar a funcao atualizajogo
                MVI     R1, vec
                MVI     R2, N
                JAL     update_game
                
                ; continues game infinitely until game over is called
                BR      loop

;=================================================================
; update_jumping_variables: update jumping variables
;-----------------------------------------------------------------
update_jumping_variables:
                MVI     R5, jumping
                LOAD    R2, M[R5]
                CMP     R2, R0
                BR.NZ   increase_jumping_moment
                
                MVI     R4, jump_next
                LOAD    R2, M[R4]
                CMP     R2, R0
                
                ; ignores if dino is not jumping and there's no next jump
                JMP.Z   R7
                
                ; sets fresh jump
                MVI     R1, 1
                STOR    M[R5], R1
                STOR    M[R4], R0
                MVI     R1, jumping_moment ; set new moment (0)
                STOR    M[R1], R0

increase_jumping_moment:
                ; increase jumping moment
                MVI     R1, jumping_moment
                LOAD    R2, M[R1]
                INC     R2
                
                ; resets jump if 5rd (out of bounds) moment was reached
                MVI     R4, 5
                CMP     R2, R4
                BR.Z    reset_jump
                
                ; stores new moment
                STOR    M[R1], R2
                
                JMP     R7
                
reset_jump:     ; sets jumping_moment and jumping to zero
                STOR    M[R1], R0
                STOR    M[R5], R0
                
                JMP     R7

;=================================================================
; update_line: update all text window positions of a specific
;              line according to the new values in the vector
;              parameters:
;                R1 <- vector address
;                R2 <- vector dimension
;                STACK <- current height
;-----------------------------------------------------------------

update_line:    LOAD    R5, M[R1]
                CMP     R5, R0
                BR.P    process_cactus
                
                MVI     R4, TERM_WRITE
                STOR    M[R4], R0
                
                INC     R1
                DEC     R2
                BR.NZ   update_line
                
                JMP     R7
                
process_cactus: LOAD    R4, M[R6] ; get height value without removing from stack
                CMP     R4, R5 ; current height - cactus value
                BR.NP   write_cactus
                MVI     R5, TERM_WRITE
                STOR    M[R5], R0
                
                INC     R1
                DEC     R2
                BR.NZ   update_line
                
                JMP     R7
                
write_cactus:   MVI     R5, cactus
                LOAD    R4, M[R5]
                MVI     R5, TERM_WRITE
                STOR    M[R5], R4
                
                INC     R1
                DEC     R2
                BR.NZ   update_line
                
                JMP     R7

;=================================================================
; update_game:  shift all elements of the vector to the left and 
;               fills the last value with a random number
;               Parameters
;                 R1 <- vector address 
;                 R2 <- vector dimension
;-----------------------------------------------------------------

update_game:    MOV     R5, R1 ; copy vector address
                
                ; gets value of next position
                INC     R5
                LOAD    R4, M[R5]
                
                ; saves value of the next position in the current position
                STOR    M[R1], R4
                INC     R1
                
                ; decrements number of positions
                DEC     R2 
                
                ; calls update game there's still positions to update
                CMP     R2, R0
                BR.P    update_game
                
                ; saves R7
                DEC     R6
                STOR    M[R6], R7
                
                ; saves last position
                DEC     R1
                DEC     R6
                STOR    M[R6], R1
                
                ; gets a random number
                MVI     R1, MAX_HEIGHT
                JAL     generate_cactus
                
                ; gets from stack the last position in the vector
                ; and saves the new cactus value
                LOAD    R1, M[R6]
                INC     R6
                STOR    M[R1], R3
                
                ; reset cursor position
                MVI     R1, TERM_CURSOR
                MVI     R2, DEFAULT_CURSOR
                STOR    M[R1], R2
                
                MVI     R2, MAX_HEIGHT
prepare_update: ; Save height value
                DEC     R6
                STOR    M[R6], R2
                
                MVI     R1, vec
                MVI     R2, N
                
                JAL     update_line
                
                ; Restore height value
                LOAD    R2, M[R6]
                INC     R6
                
                DEC     R2
                JAL.NZ  prepare_update
                
                ; Clean dinossaur if jumping
                MVI     R1, TERM_WRITE
                MVI     R2, TERM_CURSOR
                MVI     R4, DINO_JMP_CURSOR
                STOR    M[R2], R4
                STOR    M[R1], R0
                
                ; Check if dino is jumping and writes it in text window
                MVI     R4, jumping
                LOAD    R5, M[R4]
                CMP     R5, R0
                JAL.Z   set_dino
                JAL.NZ  set_jumping_dino
                
                ; Write dino in text terminal
                MVI     R4, dino
                LOAD    R5, M[R4]
                STOR    M[R1], R5
                
                ; Save R7
                LOAD    R7, M[R6]
                INC     R6
                
                ; Check if game is over
                ; game is over if there's a cactus and dino is not jumping
                MVI     R1, vec
                LOAD    R2, M[R1]
                CMP     R2, R0
                BR.NZ   check_if_jumping
                JMP     R7

check_if_jumping:
                MVI     R1, jumping
                LOAD    R2, M[R1]
                CMP     R2, R0
                BR.Z    process_gameover
                JMP     R7

process_gameover:      
                MVI     R1, TERM_WRITE
                MVI     R2, TERM_CURSOR
                MVI     R4, GAMEOVER_CURSOR
                STOR    M[R2], R4
                MVI     R4, gameover
                LOAD    R5, M[R4]
                
write_gameover: STOR    M[R1], R5
                INC     R4
                LOAD    R5, M[R4]
                CMP     R5, R0
                BR.NZ   write_gameover
                
                ; restore R7
                LOAD    R7, M[R6]
                INC     R6
                
                ; change game status
                MVI     R1, game_status
                MVI     R2, END
                STOR    M[R1], R2
                
                JAL     wait_game

;=================================================================
; set_dino: Sets terminal cursor for dino not jumping
;           Parameters:
;             R1 <- address of text window
;             R2 <- address of terminal cursor
;-----------------------------------------------------------------

set_dino:       ; set dino cursor
                MVI     R4, DINO_CURSOR
                STOR    M[R2], R4
                
                JMP     R7
                

;=================================================================
; set_jumping_dino: Sets terminal cursor for dino jumping
;                   Parameters:
;                     R1 <- address of text window
;                     R2 <- address of terminal cursor
;-----------------------------------------------------------------

set_jumping_dino:     
                ; set dino cursor
                MVI     R4, DINO_JMP_CURSOR
                STOR    M[R2], R4
                
                JMP     R7

;=================================================================
; generate_cactus: Generate a random number for a cactus (can be 0)
;                  Parameters:
;                    R1 <- max height
;                  Return:
;                    R3 <- Random number
;-----------------------------------------------------------------

generate_cactus:; saves R7
                DEC     R6
                STOR    M[R6], R7
                
                ; initial operations
                MVI     R5, x ; x address
                LOAD    R2, M[R5] ; x value
                MVI     R4, 1
                AND     R3, R2, R4 ; bit = x & 1
                SHR     R2 ; x = x >> 1
                
                ; check if bit != 0
                CMP     R3, R0
                JAL.NZ   change_x_bit
                
                STOR    M[R5], R2 ; saves new value of x to its address
                
                ; check if x < 29491
                MVI     R5, 8000h   ; check if most significant bit is
                AND     R4, R2, R5  ; equals to 1, which means that
                CMP     R4, R5      ; x is < 0 <=> x < 29491
                BR.Z    return_zero
                
                MVI     R5, 29491  ; if x > 0, checks if x < 29491
                CMP     R2, R5
                BR.N    return_zero
                
                DEC     R1 ; height = height - 1
                AND     R3, R2, R1 ; x & (height - 1)
                INC     R3 ; (x & (height - 1 )) + 1
                
                ; gets R7
                LOAD    R7, M[R6]
                INC     R6
                
                JMP     R7

change_x_bit:   MVI     R4, B400h
                XOR     R2, R2, R4
                JMP     R7

return_zero:    MOV     R3, R0

                ; gets R7
                LOAD    R7, M[R6]
                INC     R6
                
                JMP     R7

;*****************************************************************
; AUXILIARY INTERRUPT SERVICE ROUTINES
;*****************************************************************
aux_timer_isr:  ; Save context
                DEC     R6
                STOR    M[R6],R1
                DEC     R6
                STOR    M[R6],R2
                ; restart timer
                MVI     R1, timer_countval
                LOAD    R2, M[R1]
                MVI     R1, TIMER_COUNTER
                STOR    M[R1], R2          ; set timer to count value
                MVI     R1, TIMER_CONTROL
                MVI     R2, TIMER_SETSTART
                STOR    M[R1], R2          ; start timer
                ; increments timer flag
                MVI     R2, timer_tick
                LOAD    R1, M[R2]
                INC     R1
                STOR    M[R2], R1
                ; restore context
                LOAD    R2, M[R6]
                INC     R6
                LOAD    R1, M[R6]
                INC     R6
                JMP     R7
                
set_next_jump:  MVI     R1, jump_next
                MVI     R2, 1
                STOR    M[R1], R2
                JMP     R7

;*****************************************************************
; INTERRUPT SERVICE ROUTINES
;*****************************************************************
                
; INTERRUPTION 0
                ORIG    7F00h
keyzero:        ; Save context
                DEC     R6
                STOR    M[R6], R1
                DEC     R6
                STOR    M[R6], R2
                
                ; change game status
                MVI     R1, game_status
                MVI     R2, START
                STOR    M[R1], R2
                
                ; Restore context
                LOAD    R2, M[R6]
                INC     R6
                LOAD    R1, M[R6]
                INC     R6
                
                RTI
                
; INTERRUPTION 3
                ORIG    7F30h
keyup:          ; Save context
                DEC     R6
                STOR    M[R6], R7
                DEC     R6
                STOR    M[R6], R1
                DEC     R6
                STOR    M[R6], R2
                
                ; Check if dinossaur is currently not jumping
                MVI     R1, jumping
                LOAD    R2, M[R1]
                CMP     R2, R0
                JAL.Z    set_next_jump
                
                ; Restore context
                LOAD    R2, M[R6]
                INC     R6
                LOAD    R1, M[R6]
                INC     R6
                LOAD    R7, M[R6]
                INC     R6
                RTI
                
; INTERRUPTION 15
                ORIG    7FF0h
timer_isr:      ; Save context
                DEC     R6
                STOR    M[R6],R7

                JAL     aux_timer_isr
                
                ; Restore context
                LOAD    R7,M[R6]
                INC     R6
                RTI
                
                