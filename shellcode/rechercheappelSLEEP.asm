[BITS 64]
global _start

_start:

    xor rdx, rdx
    mov rax, gs:[rdx + 0x60]    ; PEB
    mov rax, [rax + 0x18]       ; LDR
    mov rsi, [rax + 0x20]       ; First module

next_mod:
    mov rbx, [rsi + 0x20]       ; DLL base address
    mov rax, [rsi + 0x50]       ; Unicode string DLL name
    mov rsi, [rsi]              ; Next module
    
    test rax, rax
    jz next_mod
    
    cmp word [rax], 'K'
    jne next_mod
    cmp word [rax + 2], 'E'
    jne next_mod
    cmp word [rax + 4], 'R'
    jne next_mod
    cmp word [rax + 6], 'N'
    jne next_mod
    
    mov rax, rbx  

	mov ebx, [rax + 0x3C]       ; e_lfanew offset
	add rbx, rax                ; PE Header
	mov ebx, [rbx + 0x88]       ; Export Directory RVA
	add rbx, rax                ; Export Directory VA

	; Maintenant on peut accéder aux tables d'export
	mov ecx, [rbx + 0x18]       ; NumberOfNames
	mov r8d, [rbx + 0x20]       ; AddressOfNames RVA
	add r8, rax                 ; AddressOfNames VA
	mov r9d, [rbx + 0x24]       ; AddressOfNameOrdinals RVA
	add r9, rax                 ; AddressOfNameOrdinals VA
	mov r10d, [rbx + 0x1C]      ; AddressOfFunctions RVA
	add r10, rax                ; AddressOfFunctions VA
    
    
	xor rdx, rdx                ; Notre compteur de boucle

find_sleep:
    mov r11d, [r8 + rdx*4]  
    add r11, rax            
    
    cmp byte [r11], 'S'
    jne next_func
    cmp byte [r11+1], 'l'
    jne next_func
    cmp byte [r11+2], 'e'
    jne next_func
    cmp byte [r11+3], 'e'
    jne next_func
    cmp byte [r11+4], 'p'
    je found_sleep
    
next_func:
    inc rdx
    cmp rdx, rcx           
    jb find_sleep 
    
found_sleep:
    movzx edx, word [r9 + rdx*2]  ; Obtenir l'ordinal
    mov edx, [r10 + rdx*4]        ; Obtenir le RVA de la fonction
    add rax, rdx                   ; Convertir en VA - RAX contient maintenant l'adresse de Sleep
	
	mov rcx, 5000    ; 5000 ms = 5 secondes
	call rax         ; Appel de Sleep