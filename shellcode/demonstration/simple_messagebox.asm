[BITS 64]
section .data
    title db "Test", 0
    message db "Click OK", 0
    user32_dll db "user32.dll", 0
    msgbox_func db "MessageBoxA", 0

section .text
    ; Trouver user32.dll
    xor rdx, rdx
    mov rax, gs:[rdx + 0x60]    
    mov rax, [rax + 0x18]       
    mov rsi, [rax + 0x20]       

find_user32:
    mov rbx, [rsi + 0x20]      
    mov rax, [rsi + 0x50]      
    mov rsi, [rsi]             
    
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

    ; Trouver MessageBoxA
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
    db 0x00, 0x00, 0x00, 0x00, 0x00  ;