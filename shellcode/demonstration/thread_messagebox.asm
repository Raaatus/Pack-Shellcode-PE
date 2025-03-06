[BITS 64]
section .data
    title db "Test", 0
    message db "Click OK", 0
    msgbox_func db "MessageBoxA", 0
    thread_handle dq 0
	saved_user32 dq 0  ; Pour sauvegarder l'adresse de user32.dll
	
	rien_saved_rbx dq 56
	
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
	
	peb_saved_rax dq 0
    peb_saved_rbx dq 0
    peb_saved_rcx dq 0
    peb_saved_r8  dq 0
    peb_saved_r9  dq 0
    peb_saved_r10 dq 0
	peb_saved_r11 dq 0
	

section .text
    global _start

_start:
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
	
    xor rdx, rdx
    mov rax, gs:[rdx + 0x60]    ; PEB
    mov rax, [rax + 0x18]       ; LDR
    mov rsi, [rax + 0x20]       ; First module
 
    jmp find_user32

message_box_thread:
	
    mov rax, rcx      ; RCX contient l'adresse correcte de user32.dll
    mov rbx, rax      ; Copier dans RBX aussi
    xor rdx, rdx      ; Réinitialiser RDX à 0

    mov ebx, [rax + 0x3C]      
    add rbx, rax               
    mov ebx, [rbx + 0x88]      
    add rbx, rax               
    mov ecx, [rbx + 0x18]      
    mov r8d, [rbx + 0x20]      
    add r8, rax                
    mov r9d, [rbx + 0x24]      
    add r9, rax                
    mov r10d, [rbx + 0x1C]     
    add r10, rax 
	
	
	xor rdx, rdx
	

	find_msgbox:
		mov r11d, [r8 + rdx*4]  
		add r11, rax            
		
		cmp byte [r11], 'M'
		jne next_msgbox
		cmp byte [r11+1], 'e'
		jne next_msgbox
		cmp byte [r11+2], 's'
		jne next_msgbox
		cmp byte [r11+3], 's'
		jne next_msgbox
		cmp byte [r11+4], 'a'
		jne next_msgbox
		cmp byte [r11+5], 'g'
		jne next_msgbox
		cmp byte [r11+6], 'e'
		jne next_msgbox
		cmp byte [r11+7], 'B'
		jne next_msgbox
		cmp byte [r11+8], 'o'
		jne next_msgbox
		cmp byte [r11+9], 'x'
		jne next_msgbox
		cmp byte [r11+10], 'A'
		je found_msgbox

	next_msgbox:
		inc rdx
		cmp rdx, rcx           
		jb find_msgbox

	found_msgbox:
		movzx edx, word [r9 + rdx*2]
		mov edx, [r10 + rdx*4]
		add rax, rdx
		

		; Before MessageBoxA call
		sub rsp, 40  ; Align stack for x64 calling convention

		; Your MessageBoxA call
		xor rcx, rcx               
		lea rdx, [rel message]     
		lea r8, [rel title]        
		mov r9d, 0                 
		call rax

		; After MessageBoxA call
		add rsp, 40  ; Restore stack

		ret   
find_user32:           
    mov rbx, [rsi + 0x20]       ; DLL base address
    mov rax, [rsi + 0x50]       ; Unicode string DLL name
    mov rsi, [rsi]              ; Next module 
    test rax, rax
    jz find_user32
    
    cmp word [rax], 'U'
    jne find_user32
    cmp word [rax + 2], 'S'
    jne find_user32
    cmp word [rax + 4], 'E'
    jne find_user32
    cmp word [rax + 6], 'R'
    jne find_user32
	

	mov [rel saved_user32], rbx  ; Save user32 base
	    
	
	
    jmp find_kernel32
		
find_kernel32:
    xor rdx, rdx
    mov rax, gs:[rdx + 0x60]    
    mov rax, [rax + 0x18]       
    mov rsi, [rax + 0x20]       

next_mod:
    mov rbx, [rsi + 0x20]      
    mov rax, [rsi + 0x50]      
    mov rsi, [rsi]             
    
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
    mov ebx, [rax + 0x3C]      
    add rbx, rax               
    mov ebx, [rbx + 0x88]      
    add rbx, rax               
    mov ecx, [rbx + 0x18]      
    mov r8d, [rbx + 0x20]      
    add r8, rax                
    mov r9d, [rbx + 0x24]      
    add r9, rax                
    mov r10d, [rbx + 0x1C]     
    add r10, rax

    xor rdx, rdx 
	

find_createthread:
    mov r11d, [r8 + rdx*4]  
    add r11, rax            
    
    cmp byte [r11], 'C'
    jne next_createthread
    cmp byte [r11+1], 'r'
    jne next_createthread
    cmp byte [r11+2], 'e'
    jne next_createthread
    cmp byte [r11+3], 'a'
    jne next_createthread
    cmp byte [r11+4], 't'
    jne next_createthread
    cmp byte [r11+5], 'e'
    jne next_createthread
    cmp byte [r11+6], 'T'
    jne next_createthread
    cmp byte [r11+7], 'h'
    jne next_createthread
    cmp byte [r11+8], 'r'
    jne next_createthread
    cmp byte [r11+9], 'e'
    jne next_createthread
    cmp byte [r11+10], 'a'
    jne next_createthread
    cmp byte [r11+11], 'd'
    je found_createthread

next_createthread:
    inc rdx
    cmp rdx, rcx           
    jb find_createthread

found_createthread:
    movzx edx, word [r9 + rdx*2]
    mov edx, [r10 + rdx*4]
    add rax, rdx

    ; Appeler CreateThread
    sub rsp, 48
    xor rcx, rcx               ; lpThreadAttributes
    xor rdx, rdx               ; dwStackSize
    lea r8, [rel message_box_thread] ; lpStartAddress
    mov r9, [rel saved_user32]  ; lpParameter = adresse user32.dll
    push 0                     ; dwCreationFlags
    push qword [rel thread_handle] ; lpThreadId
    call rax
    add rsp, 48
	
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
	db 0x00, 0x00, 0x00, 0x00, 0x00  ;