[BITS 64]

section .data
    ; Strings XORées avec 0x41
    title db "test", 0 ^ 0x41
    message db "OUI", 0 ^ 0x41
    user32_dll db 0x34, 0x32, 0x24, 0x33, 0x72, 0x73, 0x6f, 0x25, 0x2d, 0x2d, 0 ^ 0x41
    msgbox_func db 0x0c, 0x24, 0x32, 0x32, 0x20, 0x26, 0x24, 0x03, 0x2e, 0x39, 0x00, 0 ^ 0x41
    loadlib_func db 0x0d, 0x2e, 0x20, 0x25, 0x0d, 0x28, 0x23, 0x33, 0x20, 0x33, 0x38, 0x00, 0 ^ 0x41
	
	saved_rax dq 0
    saved_rbx dq 0
    saved_rcx dq 0
    saved_rdx dq 0
    saved_rbp dq 0
    saved_rsp dq 0
    saved_rsi dq 0
    saved_rdi dq 0
    saved_r8  dq 0
    saved_r9  dq 0
    saved_r10 dq 0
    saved_r11 dq 0
    saved_r12 dq 0
    saved_r13 dq 0
    saved_r14 dq 0
    saved_r15 dq 0

section .text
global start
start:

	mov [rel saved_rax], rax
    mov [rel saved_rbx], rbx
    mov [rel saved_rcx], rcx
    mov [rel saved_rdx], rdx
    mov [rel saved_rbp], rbp
    mov [rel saved_rsp], rsp
    mov [rel saved_rsi], rsi
    mov [rel saved_rdi], rdi
    mov [rel saved_r8], r8
    mov [rel saved_r9], r9
    mov [rel saved_r10], r10
    mov [rel saved_r11], r11
    mov [rel saved_r12], r12
    mov [rel saved_r13], r13
    mov [rel saved_r14], r14
    mov [rel saved_r15], r15
    ; GetProcAddress est dans RSI/R12
	
	mov rax, rsi            
	sub rax, 0x1B200 ; Aligner sur une page mémoire (0x1000)
	mov r12, rax
	mov r10, 0x41

	lea rdx, [rel loadlib_func]
	push rdx                    ; Sauvegarder l'adresse originale
	mov rcx, 13                ; Longueur de "LoadLibraryA" + null byte
	decode_loop_1:
		xor byte [rdx], r10b
		inc rdx
		dec rcx
		jnz decode_loop_1

	mov rcx, r12               ; Base kernel32
	pop rdx                    ; Récupérer l'adresse du début de la chaîne
	call rsi                   ; GetProcAddress
    
    ; Maintenant LoadLibraryA est dans RAX
    mov r13, rax                ; Sauver LoadLibraryA
	mov r10, 0x41
	lea rcx, [rel user32_dll]
    push rcx                    ; Sauvegarder l'adresse originale
	mov rdx, 11                ; Longueur de "LoadLibraryA" + null byte
	decode_loop_2:
		xor byte [rcx], r10b
		inc rcx
		dec rdx
		jnz decode_loop_2

	pop rcx                    ; Récupérer l'adresse du début de la chaîne
    call r13                    ; Charger user32.dll
    
    mov r13, rax                ; Handle user32.dll
	mov r10, 0x41
	lea rdx, [rel msgbox_func]
    push rdx                    ; Sauvegarder l'adresse originale
	mov rcx, 13                ; Longueur de "LoadLibraryA" + null byte
	decode_loop_3:
		xor byte [rdx], r10b
		inc rdx
		dec rcx
		jnz decode_loop_3

	mov rcx, r13               ; Base user32
	pop rdx                    ; Récupérer l'adresse du début de la chaîne
    call rsi                    ; GetProcAddress pour MessageBoxA
	
	
	push rbp                    ; Sauvegarder le frame pointer
    mov rbp, rsp               ; Nouveau frame
    and rsp, -16               ; Aligner RSP sur 16 bytes
    
    sub rsp, 32
    xor rcx, rcx
    lea rdx, [rel message]
    lea r8, [rel title]
    xor r9, r9
    call rax                    ; MessageBoxA
    mov rsp, rbp               ; Restaurer la pile
    pop rbp
	
	
	mov rax, [rel saved_rax]
    mov rbx, [rel saved_rbx]
    mov rcx, [rel saved_rcx]
    mov rdx, [rel saved_rdx]
    mov rbp, [rel saved_rbp]
    mov rsp, [rel saved_rsp]
    mov rsi, [rel saved_rsi]
    mov rdi, [rel saved_rdi]
    mov r8,  [rel saved_r8]
    mov r9,  [rel saved_r9]
    mov r10, [rel saved_r10]
    mov r11, [rel saved_r11]
    mov r12, [rel saved_r12]
    mov r13, [rel saved_r13]
    mov r14, [rel saved_r14]
    mov r15, [rel saved_r15]

	db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00  ;
	db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00  ;