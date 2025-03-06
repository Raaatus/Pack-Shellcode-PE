[BITS 64]

section .data
    title db "Test", 0
    message db "Click OK", 0
    user32_dll db "user32.dll", 0
    msgbox_func db "MessageBoxA", 0
    loadlib_func db "LoadLibraryA", 0
	
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
	
	mov rax, rsi            ; Charger une adresse de retour de la stack (dans kernel32 normalement)
	sub rax, 0x1B200 ; Aligner sur une page mémoire (0x1000)
	
	mov r12, rax
	
    mov rcx, rax               
    lea rdx, [rel loadlib_func]
    call rsi                    ; Utiliser RSI pour GetProcAddress
    
    ; Maintenant LoadLibraryA est dans RAX
    mov r13, rax                ; Sauver LoadLibraryA
    lea rcx, [rel user32_dll]   ; Paramètre pour LoadLibraryA
    call r13                    ; Charger user32.dll
    
    mov rcx, rax                ; Handle user32.dll
    lea rdx, [rel msgbox_func]
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