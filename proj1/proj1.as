;****************************************************************;
;                         1º PROJETO IAC                         ;
;                            GRUPO 100                           ;
;                      Mafalda Ferreira - 92513                  ;
;                                                                ;
;****************************************************************;


;=================================================================
; CONSTANTES
;-----------------------------------------------------------------

N               EQU     80 ; numero de posicoes do terreno de jogo
STACK_INIT      EQU     8000h	; localizacao inicial da pilha
ALTURA_MAX      EQU     4

;=================================================================
; Variaveis Globais
;-----------------------------------------------------------------
                ORIG    3000h
x               WORD    7 ; valor global usado em geracacto

                ORIG    4000h
vec             TAB     N ; vetor do terreno do jogo com N posicoes
                
;=================================================================
; Main: ponto de começo do programa
;-----------------------------------------------------------------                
                ORIG    0000h
Main:           MVI     R6, STACK_INIT
                
                JAL     comecajogo
Fim:            BR      Fim
                
;=================================================================
; comecajogo
;-----------------------------------------------------------------


comecajogo:     ; guarda na pilha o endereço R7 para a funcao inicial
                DEC     R6
                STOR    M[R6], R7
                
loop:           ; prepara os argumentos para chamar a funcao atualizajogo
                MVI     R1, vec
                MVI     R2, N
                JAL     atualizajogo
                
                ; continua o jogo infinitamente
                BR      loop
                
                ; caso o jogo termine, obtem o endereço de R7 guardado na pilha
                LOAD    R7, M[R6]
                INC     R6
                JMP     R7

;=================================================================
; atualizajogo: desloca todos os elementos do vetor para a esquerda
;               e preenche o da direita com um valor de geracacto
;               parametros:
;               1. endereco de memoria do vetor 
;               2. dimensao do vetor
;-----------------------------------------------------------------

atualizajogo:   MOV     R5, R1 ; copia o endereco do vetor para R5
                
                ; obtem o valor da posicao seguinte
                INC     R5
                LOAD    R4, M[R5]
                
                ; guarda o valor da posicao seguinte na posicao atual do vetor
                STOR    M[R1], R4
                INC     R1
                
                ; decrementa o numero de posicoes do vetor
                DEC     R2 
                
                ; volta ao inicio caso ainda nao tenham sido percorridas todas as posicoes
                CMP     R2, R0
                BR.P   atualizajogo
                
                ; armazena a label R7 na pilha
                DEC     R6
                STOR    M[R6], R7
                
                ; armazena a ultima posicao do vetor na pilha
                DEC     R1
                DEC     R6
                STOR    M[R6], R1
                
                ; obtem um valor aleatorio para o proximo cato (nulo ou nao)
                MVI     R1, ALTURA_MAX
                JAL     geracacto
                
                ; obtem da pilha a ultima posicao do vetor 
                ; e armazena o valor do novo cato
                LOAD    R1, M[R6]
                INC     R6
                STOR    M[R1], R3
                
                ; obtem da pilha o valor de R7
                LOAD    R7, M[R6]
                INC     R6
                
                JMP     R7

;=================================================================
; geracacto: gera um numero aleatorio
;            parameteros:
;            - 1. altura maxima (potencia de 2) (em R1)
;            retorno:
;            - 1. valor aleatorio gerado (em R3)
;-----------------------------------------------------------------

geracacto:      ; guarda na pilha o endereço em R7
                DEC     R6
                STOR    M[R6], R7
                
                ; operações iniciais
                MVI     R5, x ; obtem endereço de x
                LOAD    R2, M[R5] ; R2 <- x
                MVI     R4, 1
                AND     R3, R2, R4 ; bit = x & 1
                SHR     R2 ; x = x >> 1
                
                ; verifica se bit != 0
                CMP     R3, R0
                JAL.NZ   change_x_bit
                
                STOR    M[R5], R2 ; guarda o novo valor de x no respetivo endereço
                
                ; verifica se x < 29491
                MVI     R5, 8000h   ; verifica se o bit mais significativo
                AND     R4, R2, R5  ; é igual a 1, o que significa que
                CMP     R4, R5      ; x é negativo, logo, obrigatoriamente
                BR.Z    return_zero ; é menor que 29491
                
                MVI     R5, 29491  ; se x for positivo, verifica se é
                CMP     R2, R5     ; menor que 29491
                BR.N    return_zero
                
                DEC     R1 ; altura = altura - 1
                AND     R3, R2, R1 ; x & (altura - 1)
                INC     R3 ; (x & (altura - 1 )) + 1
                
                ; retira da pilha o endereço a colocar em R7
                LOAD    R7, M[R6]
                INC     R6
                
                JMP     R7

;=================================================================
; change_x_bit: altera potencialmente qualquer bit de x em R2
;-----------------------------------------------------------------

change_x_bit:   MVI     R4, B400h
                XOR     R2, R2, R4
                JMP     R7

;=================================================================
; return_zero: coloca em R3 o valor 0 e volta à função atualizajogo
;-----------------------------------------------------------------

return_zero:    MOV     R3, R0

                ; retira da pilha o endereço a colocar em R7
                LOAD    R7, M[R6]
                INC     R6
                
                JMP     R7
                
                
                
                