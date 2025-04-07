[BITS 16]
[ORG 0x7C00]         ; El bootloader se carga en 0x7C00

start:
    cli             ; Deshabilita interrupciones

    ; Inicializar segmentos
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00  ; Configura el stack 

    sti             ; Habilita interrupciones

    ; Llamada a la BIOS para leer sectores 
    mov ah, 0x02    ; Función de lectura de sectores
    mov al, 4       ; Número de sectores a leer 
    mov ch, 0       ; Número de cilindro: 0
    mov cl, 2       ; Número de sector de inicio: 2 (ya que el sector 1 es este bootloader)
    mov dh, 0       ; Cabezal: 0
    mov dl, 0x80    ; Unidad: disco duro primario (0x80)
    mov bx, 0x8000  ; Dirección de memoria de carga del segundo stage
    int 0x13        ; Llamada a la BIOS para leer los sectores
    jc disk_error   ; Si hay error, salta a la rutina de error

    ; Transferir la ejecución al segundo stage cargado en 0x8000
    jmp 0x0000:0x8000

disk_error:
    ; En caso de error, se queda en un bucle infinito (o puedes implementar un mensaje)
    cli
    hlt
    jmp disk_error

; Rellenar hasta el offset 446 (inicio de la tabla de particiones)
times 446 - ($ - $$) db 0

; --- Tabla de Particiones ---
; Entrada 1: Partición booteable, con campos CHS configurados en 0.
Partition:
    db 0x80                ; Indicador de booteo: activa (0x80)
    db 0, 0, 0            ; CHS de inicio: 0, 0, 0 (dummy)
    db 0x83               ; Tipo de partición (ejemplo: Linux)
    db 0, 0, 0            ; CHS de fin: 0, 0, 0 (dummy)
    dd 0x00000800         ; LBA de inicio: 2048 (0x800 en hexadecimal)
    dd 0x00002000         ; Tamaño en sectores: 0x2000 (ajusta según necesites)

; Entradas 2, 3 y 4 vacías (48 bytes)
times 3 * 16 db 0

; Rellenar hasta 510 bytes (si hace falta)
times 510 - ($ - $$) db 0

; Firma booteable (2 bytes, en offset 510 y 511)
dw 0xAA55
