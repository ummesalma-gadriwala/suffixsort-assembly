; Umme Salma Gadriwala
; 40002431

; Gets a string of length 1 to 30 via command-line argument
; Passes string on to the program
; String stored as a byte array, terminated by 0 in memory

%include "asm_io.inc"
segment .data

; initialize variables here
fmt1: db "%s", 10, 0
; error strings
NumOfArg: db 'Incorrect number of arguments.',0
Len: db 'Length of string must be between 1 and 30',0
ImproperLetters: db 'Only use characters 0, 1 and 2 in your string',0
SortedSuffix: db 'sorted suffixes:' 

segment .bss
N: resd 1
X: resb 31
y: resd 31

; for subroutine
retSuf: resd 2

segment .text
	global asm_main
	extern printf
	extern strlen

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sufcmp:
; ebp+16: Z
; ebp+12: i
; ebp+8: j
	enter 0,0
	pusha
	
	mov eax, dword[ebp+12]	; eax: i
	mov ebx, dword[ebp+8]	; ebx: j
	mov ecx, dword[ebp+16]  ; ecx: Z

	LOOPS:
		cmp byte[ecx+eax], 0
		je RETMINUS

		cmp byte[ecx+ebx],0
		je RETPLUS

		mov dl, byte[ecx+ebx]
		cmp byte[ecx+eax], dl
		jl RETMINUS
		jg RETPLUS
		
		inc eax
		inc ebx
		jmp LOOPS

	RETPLUS:
		mov dword[retSuf], 1
		jmp ENDS

	RETMINUS:
		mov dword[retSuf], -1
		jmp ENDS		

ENDS:
	popa
	leave
	ret
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

asm_main:
	enter 0,0
	pusha
; 1st arg: program name - sufsort
; 2nd arg: string

; Number of arguments check
	mov eax, dword [ebp+8]	 ; eax holds argc - arg count
	cmp eax, 2
	jne NumberOfArgument


	mov eax, dword [ebp+12]   ; eax holds address of 1st arg
	add eax, 4		  ; eax holds address of 2nd arg
	mov ebx, dword [eax]	  ; ebx holds 2nd arg, which is a pointer to the string

; Length of string check
; begin by finding length of string
; then compare with 30
; jump if greater than

; and improper letters check
; compare each byte to 0 then 1 then 2
; jump if not equal
	
	mov ecx, 0 	; set counter: ecx to 0
	mov edx, ebx	; mov the string to edx
	Count:
		cmp byte[edx], '2'
		je ByteOkay
		jne TryAgain
	TryAgain:
		cmp byte[edx], '1'
		je ByteOkay
		jne OnceMore
	OnceMore:
		cmp byte[edx], '0'
		je ByteOkay
		jne CharCheck
	ByteOkay:
		inc ecx
		inc edx
		cmp ecx, 30
		jg StrLen
		cmp byte[edx], 0
		jnz Count

	mov [N], ecx    ; store length of input string in memory


	mov eax, dword [ebp+12]
	add eax, 4		; eax holds address of 2nd arg
	mov ebx, dword [eax]
	
; Copy string into memory
; Stored in a byte array, X terminated by 0

	mov eax, X
	Loop:
		mov cl, byte[ebx]
		mov byte[eax], cl
		inc eax
		inc ebx
		cmp byte[ebx], 0
		jne Loop
	inc eax
	mov byte[eax], 0
	mov eax, X
	call print_string
	call print_nl
	mov eax, SortedSuffix
	call print_string
	call print_nl

; array y: suffix indices for the string
; y holding: 0, 1, 2, ..., N-1

	mov eax, y
	mov ebx, 0
	mov edx, [N]
	LoopY:
		mov dword [eax], ebx
		add eax, 4
		inc ebx
		dec edx
		cmp edx, 0
		jne LoopY

; sorting array y using bubble sort and comparing i with j
; by comparing Z[i..N-1] and Z[j..N-1] using the subroutine
; sufcmp (Z,i,j)

	mov edx, [N]			; edx: i
	Loop1:     ; from N to 0
             mov ebx, edx
	     mov ecx, dword 1		; ecx: j
	     Loop2:	    		; from 1 to edx: i
		  mov eax, X		; eax: address of X
		  push eax

		  mov esi, y		; esi: y
		  mov eax, ecx		; eax: ecx: j
		  dec eax		; eax = eax - 1: j-1
		  imul eax, 4		; eax = eax * 4
                  add eax, esi		; eax: y[j-1] - address
		  mov edi, dword[eax]	; edi: integer at y[j-1]
                  push edi	
		  
		  mov edi, ecx		; edi: ecx: j
		  imul edi, 4		; edi = j * 4
                  add esi, edi		; esi: y[j] - address
		  mov edi, dword[esi]	; edi: integer at y[j]
                  push edi
		
		  call sufcmp	
		  add esp, 12

		  cmp dword[retSuf], dword 0
                  jg SWAP
		  jmp nSWAP

		  SWAP:
			 mov esi, [y + 4 * ecx]
       			 mov eax, ecx
       			 dec eax	
       			 mov edi, [y + 4*eax]
       			 mov [y + 4*ecx], edi
       			 mov [y + 4*eax], esi
       			 jmp nSWAP

	 	 nSWAP:	
			 inc ecx
			 cmp ecx, ebx
			 jne Loop2	
       dec edx
       cmp edx, dword 1
       jne Loop1  


; display sorted suffixes
	mov esi, dword 0	; esi: counter
	mov edi, dword [N]

	PrintLoop:
		mov ebx, y
		mov edx, dword [ebx+4*esi]
       		mov eax, X
		add eax, edx	; Z[y[i]] address
		call print_string
		call print_nl
		inc esi
		cmp esi, edi
		jne PrintLoop

	jmp END

; error handling
NumberOfArgument:  mov eax, NumOfArg
		   call print_string
		   call print_nl	; prints new line
		   jmp END

StrLen: 	   mov eax, Len
                   call print_string
                   call print_nl        ; prints new line
		   jmp END

CharCheck:	   mov eax, ImproperLetters
                   call print_string
                   call print_nl        ; prints new line
                   jmp END

END:	call read_char
	popa
	leave
	ret
