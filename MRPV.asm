[BITS 16]
[ORG 0x8000]            ; El segundo stage se carga en 0x8000

;-------------------------------------------------
; INICIO: Inicialización de segmentos y pila
;-------------------------------------------------
start:
    cli                     ; Deshabilita interrupciones para evitar conflictos durante la inicialización
    xor ax, ax              ; Limpia el registro AX (pone 0)
    mov ds, ax              ; Establece DS=0 para que las referencias de offset sean coherentes con ORG 0x8000
    mov es, ax              ; Establece ES=0 (para operaciones de segmentación)
    mov ss, ax              ; Establece SS=0 (segmento de pila)
    mov sp, 0x9000          ; Inicializa la pila en una dirección segura (se puede ajustar según necesidad)
    sti                     ; Vuelve a habilitar las interrupciones

    ; Inicialización de variables
    mov byte [score], 0     ; Inicializa la puntuación a 0

    mov dx, welcome_msg     
    call print_string       

main_loop:
    ;-------------------------------------------------
    ; Limpieza de variables (letras y punteros a palabras)
    ;-------------------------------------------------
    mov byte [rand_letters1], 0   
    mov byte [rand_letters2], 0   
    mov byte [rand_letters3], 0   
    mov byte [rand_letters4], 0   

    mov word [rand_phonetic1], 0  
    mov word [rand_phonetic2], 0  
    mov word [rand_phonetic3], 0  
    mov word [rand_phonetic4], 0 

    ;-------------------------------------------------
    ; Generar letras aleatorias y obtener el puntero
    ; a la palabra fonética correspondiente
    ; Se llama a la rutina encargada de generar una letra aleatoria
    ; La rutina guarda la letra en al, esta se guarda en la variable de la letra correspondiente
    ; Luego a partir de esa letra se obtiene la palabra llamando a la rutina correspondiente
    ; Por ultimo se guarda el puntero de la palabra en la variable correspondiente 
    ;-------------------------------------------------
    call generate_random_letter   
    mov [rand_letters1], al        
    call get_phonetic_word         
    mov [rand_phonetic1], si       
    call delay                   

    call generate_random_letter   
    mov [rand_letters2], al        
    call get_phonetic_word         
    mov [rand_phonetic2], si       
    call delay                   

    call generate_random_letter   
    mov [rand_letters3], al        
    call get_phonetic_word         
    mov [rand_phonetic3], si       
    call delay                   

    call generate_random_letter   
    mov [rand_letters4], al        
    call get_phonetic_word         
    mov [rand_phonetic4], si       

    ;-------------------------------------------------
    ; Mostrar las 4 letras generadas
    ;-------------------------------------------------
    mov al, [rand_letters1]   
    call print_char           
    mov al, [rand_letters2]   
    call print_char           
    mov al, [rand_letters3]   
    call print_char           
    mov al, [rand_letters4]   
    call print_char           

    call print_newline        

    ;-------------------------------------------------
    ; Verificación de la entrada del usuario para cada palabra
    ; Para cada palabra que ingresa el usuario su puntero se carga en SI
    ; Luego se llama a la rutina que se encarga de verificar la entrada del usuario
    ;-------------------------------------------------
    mov si, [rand_phonetic1]  
    call verify_user_input    
    mov si, [rand_phonetic2]  
    call verify_user_input    
    mov si, [rand_phonetic3]  
    call verify_user_input    
    mov si, [rand_phonetic4]  
    call verify_user_input    

    ;-------------------------------------------------
    ; Mostrar la puntuación acumulada
    ;-------------------------------------------------
    mov dx, score_msg         
    call print_string         

    call convert_score        ; Convierte la puntuación a una cadena decimal y la almacena en la variable score_buf

    mov dx, score_buf         
    call print_string         
    call print_newline        

    mov dx, separador         
    call print_string         
    call print_newline        

    jmp main_loop             ; Reinicia el ciclo principal 

;-------------------------------------------------
; Rutina: verify_user_input
; Compara la cadena ingresada con la palabra correcta.
;-------------------------------------------------
verify_user_input:
    call clear_user_input     ; Limpia el buffer de entrada
    call read_user_input      ; Lee la entrada del usuario desde el teclado
    call print_newline

    mov di, user_input + 2    ; Apunta DI al comienzo de la cadena ingresada (omitiendo el primer byte de longitud)
    call compare_strings      ; Subrutina que compara la cadena ingresada con la cadena correcta
    cmp ax, 1                 ; Verifica el resultado de la comparación
    je .correct               ; Si son iguales, salta a .correct

    mov dx, incorrect_msg    ; Carga el mensaje "Incorrecto" en DX
    call print_string        ; Imprime "Incorrecto"
    call print_newline       
    jmp .done_verify         ; Salta al final de la verificación

.correct:
    inc byte [score]         ; Incrementa la puntuación en 1
    mov dx, correct_msg      ; Carga el mensaje "Correcto" en DX
    call print_string        ; Imprime "Correcto"
    call print_newline       ; Salto de línea

.done_verify:
    ret                      

;-------------------------------------------------
; Rutina: clear_user_input
; Limpia el buffer de entrada
;-------------------------------------------------
clear_user_input:
    mov byte [user_input+1], 0  ; Resetea el contador de caracteres leídos a 0
    mov di, user_input+2        ; Apunta DI al inicio del área donde se almacena la entrada
    mov cx, 10                  ; Define el máximo de 10 caracteres para limpiar
.clear_loop:
    mov byte [di], 0            ; Limpia un byte del buffer (pone 0)
    inc di                    ; Avanza al siguiente byte
    loop .clear_loop          ; Repite hasta limpiar 10 bytes
    ret                       ; Retorna

;-------------------------------------------------
; Rutina: read_user_input
; Lee una línea desde el teclado
; y la almacena en user_input+2. Termina al presionar ENTER (0Dh).
;-------------------------------------------------
read_user_input:
    mov di, user_input+2       ; Apunta al buffer donde se almacenará la cadena ingresada
    mov cx, 10                 ; Define el máximo de 10 caracteres a leer
    xor bx, bx                 ; Inicializa el contador de caracteres leídos (BX=0)
.read_loop:
    mov ah, 0                  ; Función 0 de BIOS para esperar tecla
    int 16h                    ; Llama a la BIOS para leer una tecla (resultado en AL)
    cmp al, 0Dh                ; Comprueba si la tecla es ENTER (código 0Dh)
    je .finish_input          ; Si es ENTER, termina la lectura
    ; Imprimir el carácter (eco)
    mov ah, 0x0E              ; Función 0x0E de BIOS para mostrar carácter en modo teletipo
    int 10h                   ; Llama a la BIOS para imprimir el carácter
    ; Almacenar el carácter en el buffer
    mov [di], al              ; Guarda el carácter en la posición apuntada por DI
    inc di                    ; Incrementa el puntero del buffer
    inc bx                    ; Incrementa el contador de caracteres leídos
    cmp bx, cx                ; Compara el contador con el máximo permitido (10)
    jae .finish_input         ; Si se alcanzó el máximo, termina la lectura
    jmp .read_loop            ; Repite la lectura

.finish_input:
    mov [user_input+1], bl    ; Guarda el número total de caracteres leídos en el segundo byte del buffer
    mov byte [di], 0          ; Termina la cadena con 0 (carácter nulo)
    ret                       ; Retorna

;-------------------------------------------------
; Rutina: compare_strings
; Compara dos cadenas terminadas.
; DS:SI apunta a la cadena correcta; DS:DI a la cadena ingresada.
; Retorna AX=1 si son iguales, AX=0 si no.
;-------------------------------------------------
compare_strings:
.compare_loop:
    mov al, [si]             ; Carga el siguiente carácter de la cadena correcta
    mov bl, [di]             ; Carga el siguiente carácter de la cadena ingresada
    cmp al, bl               ; Compara ambos caracteres
    jne .not_equal           ; Si no coinciden, salta a .not_equal
    cmp al, 0                ; Si se encuentra el final de la cadena (carácter nulo)
    je .equal               ; Termina y confirma que ambas cadenas son iguales
    inc si                  ; Avanza al siguiente carácter de la cadena correcta
    inc di                  ; Avanza al siguiente carácter de la cadena ingresada
    jmp .compare_loop       ; Repite el proceso
.not_equal:
    xor ax, ax              ; Establece AX=0 (cadenas diferentes)
    ret                     ; Retorna
.equal:
    mov ax, 1               ; Establece AX=1 (cadenas iguales)
    ret                     ; Retorna

;-------------------------------------------------
; Rutina: print_string
; Imprime una cadena terminada.
; Se espera que DX apunte a la cadena.
;-------------------------------------------------
print_string:
    push dx                 ; Guarda el registro DX (para preservarlo)
    mov si, dx              ; Usa SI para recorrer la cadena apuntada por DX
.print_loop:
    mov al, [si]            ; Carga el siguiente carácter
    cmp al, 0               ; Comprueba si es el final de la cadena (nulo)
    je .done_print         ; Si es el final, salta a terminar
    mov ah, 0x0E            ; Función 0x0E de BIOS para imprimir un carácter
    int 10h                 ; Llama a la BIOS para imprimir el carácter
    inc si                  ; Avanza al siguiente carácter
    jmp .print_loop         ; Repite el proceso
.done_print:
    pop dx                  ; Restaura DX
    ret                     ; Retorna

;-------------------------------------------------
; Rutina: print_char
; Imprime el carácter que se encuentra en AL usando BIOS
;-------------------------------------------------
print_char:
    mov ah, 0x0E            ; Función 0x0E de BIOS para imprimir el carácter en AL
    int 10h                 ; Llama a la BIOS para mostrar el carácter
    ret                     ; Retorna

;-------------------------------------------------
; Rutina: print_newline
; Imprime CR+LF usando BIOS
;-------------------------------------------------
print_newline:
    mov ah, 0x0E            ; Configura la función de impresión de teletipo
    mov al, 0x0D            ; CR (Carriage Return)
    int 0x10                ; Imprime CR
    mov al, 0x0A            ; LF (Line Feed)
    int 0x10                ; Imprime LF
    ret                     

;-------------------------------------------------
; Rutina: generate_random_letter
; Usa int 1Ah para obtener ticks y genera una letra aleatoria
; a partir de la cadena "letters".
;-------------------------------------------------
generate_random_letter:
    
    mov ax, [seed]          ; Carga la semilla actual en AX
    mov bx, 25173           ; Constante multiplicativa
    mul bx                  ; Multiplica seed por 25173 (resultado en DX:AX; se usa solo AX)
    add ax, 13849           ; Suma la constante 13849 al resultado
    mov [seed], ax          ; Guarda la nueva semilla en memoria

    ; Obtener un índice entre 0 y 25 (para 26 letras)
    xor dx, dx              ; Limpia DX para la división
    mov bx, 26              ; Número de letras en el alfabeto (26)
    div bx                  ; Divide AX entre 26; residuo en DX (índice entre 0 y 25)
    
    ; Seleccionar la letra según el índice obtenido
    mov si, dx              ; Guarda el índice en SI (aunque no se usa en la selección)
    mov al, [letters + si]  ; Carga la letra correspondiente desde la cadena "letters"
    ret                     ; Retorna con la letra en AL

;-------------------------------------------------
; Rutina: delay
;-------------------------------------------------
delay:
    mov cx, 200             ; Establece el contador externo del retardo
.delay_outer:
    mov dx, 65535           ; Establece el contador interno del retardo
.delay_inner:
    dec dx                  ; Decrementa el contador interno
    jnz .delay_inner        ; Mientras DX no sea cero, continúa el bucle interno
    loop .delay_outer       ; Decrementa CX y repite el bucle externo si no llega a cero
    ret                     ; Retorna

;-------------------------------------------------
; Rutina: get_phonetic_word
; Convierte la letra aleatoria en índice (0..25) y obtiene
; el puntero a la palabra fonética correspondiente desde phonetic_table.
;-------------------------------------------------
get_phonetic_word:
    sub al, 'a'             ; Convierte la letra en minúscula a un índice (por ejemplo, 'a' -> 0)
    mov bl, al              ; Mueve el índice a BL
    shl bx, 1               ; Multiplica el índice por 2 (cada puntero ocupa 2 bytes)
    mov si, [phonetic_table + bx]  ; Obtiene el puntero a la palabra fonética correspondiente
    ret                     ; Retorna con el puntero en SI

;-------------------------------------------------
; Rutina: convert_score
; Convierte el valor en [score] (0..255) a una cadena decimal.
; Almacena la cadena en score_buf.
;-------------------------------------------------
convert_score:
    mov al, [score]         ; Carga la puntuación (valor entre 0 y 255) en AL
    cmp al, 10              ; Comprueba si la puntuación es menor que 10 (un dígito)
    jb .single_digit        ; Si es menor, salta a la conversión de un solo dígito

    xor ah, ah              ; Limpia AH para la división
    mov bl, 10              ; Divisor para separar decenas y unidades
    div bl                  ; Divide AL entre 10; AL tendrá la parte de las decenas y AH las unidades
    add al, '0'             ; Convierte la decena a carácter ASCII
    mov [score_buf], al     ; Guarda la decena en el buffer de puntuación
    mov al, ah              ; Pasa la unidad a AL
    add al, '0'             ; Convierte la unidad a carácter ASCII
    mov [score_buf+1], al   ; Guarda la unidad en el buffer
    mov byte [score_buf+2], 0  ; Termina la cadena con un carácter nulo
    ret                     ; Retorna

.single_digit:
    add al, '0'             ; Convierte el dígito único a ASCII
    mov [score_buf], al     ; Guarda el dígito en el buffer
    mov byte [score_buf+1], 0  ; Termina la cadena con un carácter nulo
    ret                     ; Retorna

;-------------------------------------------------
; SECCIÓN DE DATOS
;-------------------------------------------------
section .data
welcome_msg db "Deletrea foneticamente: ", 0  
letters     db "abcdefghijklmnopqrstuvwxyz", 0 

; Tabla de punteros a palabras fonéticas correspondientes a cada letra del alfabeto
phonetic_table dw alpha,    bravo,   charlie, delta,  echo,    foxtrot, \
                   golf,     hotel,   india,   juliett, \
                   kilo,     lima,    mike,    november, oscar,   papa,    \
                   quebec,   romeo,   sierra,  tango,   \
                   uniform,  victor,  whiskey, xray,    yankee,  zulu

alpha    db "alpha", 0      
bravo    db "bravo", 0      
charlie  db "charlie", 0    
delta    db "delta", 0      
echo     db "echo", 0       
foxtrot  db "foxtrot", 0    
golf     db "golf", 0       
hotel    db "hotel", 0      
india    db "india", 0      
juliett  db "juliett", 0    
kilo     db "kilo", 0       
lima     db "lima", 0       
mike     db "mike", 0       
november db "november", 0   
oscar    db "oscar", 0      
papa     db "papa", 0       
quebec   db "quebec", 0     
romeo    db "romeo", 0      
sierra   db "sierra", 0     
tango    db "tango", 0      
uniform  db "uniform", 0    
victor   db "victor", 0     
whiskey  db "whiskey", 0    
xray     db "xray", 0       
yankee   db "yankee", 0     
zulu     db "zulu", 0       

correct_msg   db "Correcto", 0   
incorrect_msg db "Incorrecto", 0 
score_msg     db "Puntuacion: ", 0 
separador     db "------------", 0 
seed          dw 0x1234          ; Semilla inicial para el generador aleatorio

;-------------------------------------------------
; SECCIÓN DE BSS
;-------------------------------------------------
section .bss
rand_letters1  resb 1   
rand_letters2  resb 1   
rand_letters3  resb 1   
rand_letters4  resb 1   
        
; Buffer para entrada de usuario
; Primer byte: longitud máxima, segundo byte: cantidad leída, luego 10 bytes para caracteres.
user_input     resb 12  ; Reserva 12 bytes para el buffer de entrada del usuario

rand_phonetic1 resw 1  
rand_phonetic2 resw 1  
rand_phonetic3 resw 1  
rand_phonetic4 resw 1  

score          resb 1  ; Reserva 1 byte para almacenar la puntuación acumulada
score_buf      resb 4  ; Reserva 4 bytes para almacenar la puntuación convertida a cadena
