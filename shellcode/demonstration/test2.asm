[BITS 64]
global _start

_start:
    ; Get our current address as reference
    call get_eip
get_eip:
    pop rcx
    and rcx, 0xFFFFFFFFF0000000  ; Align to possible DLL region
    mov rdx, 0x7FFFFFFF0000      ; Upper limit

scan_memory:
    push rcx
    push rdx
    
    ; Check MZ signature
    mov ax, word [rcx]
    cmp ax, 0x5A4D
    jne next_page
    
    mov ebx, [rcx + 0x3C]      ; e_lfanew
    add rbx, rcx
    mov eax, [rbx]
    cmp eax, 0x4550           ; 'PE\0\0'
    jne next_page
    
    mov ebx, [rbx + 0x88]     ; Export Directory RVA
    test ebx, ebx
    jz next_page
    add rbx, rcx              ; VA de la table d'export

    ; Sauvegarde base address
    push rcx
    
    ; Setup pour la recherche
    mov r8d, [rbx + 0x20]     ; AddressOfNames RVA
    add r8, rcx               ; AddressOfNames VA
    mov r9d, [rbx + 0x24]     ; AddressOfNameOrdinals RVA
    add r9, rcx               ; AddressOfNameOrdinals VA
    mov r10d, [rbx + 0x1C]    ; AddressOfFunctions RVA
    add r10, rcx              ; AddressOfFunctions VA
    mov r15d, [rbx + 0x18]    ; NumberOfNames
    
    xor rdx, rdx              ; Counter
    mov r12d, 0xdb2d49b0      ; Hash de la fonction recherchée

hash_loop:
    mov r11d, [r8 + rdx*4]    ; Get name RVA
    add r11, rcx              ; Get name VA
    
    push rdx
    push rdi
    
    xor edi, edi              ; Hash accumulator
hash_next_char:
    movzx r13d, byte [r11]    ; Get next char
    test r13b, r13b
    jz hash_done
    ror edi, 0x0D            ; ROR 13
    add edi, r13d            ; Add char to hash
    inc r11
    jmp hash_next_char

hash_done:
    cmp edi, r12d
    pop rdi
    pop rdx
    je found_function
    
    inc edx
    cmp edx, r15d            ; Compare avec NumberOfNames
    jb hash_loop
    
    pop rcx                  ; Restore base si pas trouvé
    jmp next_page

found_function:
    pop rax                  ; Base address dans RAX
    movzx edx, word [r9 + rdx*2]  ; Get ordinal
    mov edx, [r10 + rdx*4]        ; Get function RVA
    add rax, rdx                  ; RAX = adresse finale
    int 3                         ; Break pour vérifier

next_page:
    pop rdx
    pop rcx
    add rcx, 0x1000          ; Next page
    cmp rcx, rdx
    jb scan_memory
