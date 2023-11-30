INCLUDELIB C:\Irvine\Irvine32.lib
INCLUDE C:\Irvine\Irvine32.inc

.data
	; ------------- GAME CONFIG -----------------
	rows           EQU 15
	columns        EQU 44
	screen2D       BYTE rows*columns dup(32), 0

	pJmpTime       EQU 10
	pStateTime     EQU 5

	; -------------------------------------------

	newLine        BYTE 0dh
	carriageReturn BYTE 0ah

	screenBoundary BYTE "========================================",0dh

	char1          BYTE "  O  ", 0dh,
                        " /|\ ", 0dh,
                        "/ 1 \", 0dh,
                        " / \ ", 0dh,
                        "/   \"

	char2          BYTE "  O  ", 0dh,
                        " /|\ ", 0dh,
                        "/ 2 \", 0dh,
                        " / \ ", 0dh,
                        "/   \"

	char1su        BYTE "  O    /", 0dh,
                        " /|\  / ", 0dh,
                        "/ 1 \/  ", 0dh,
                        " / \    ", 0dh,
                        "/   \   "

	char2su        BYTE "\    O  ", 0dh,
                        " \  /|\ ", 0dh,
                        "  \/ 2 \", 0dh,
                        "    / \ ", 0dh,
                        "   /   \"

	p1PosX      DWORD 12
	p1PosY      DWORD 7

	p2PosX      DWORD 22
	p2PosY      DWORD 7
	
	p1jmp       DWORD 0
	p2jmp       DWORD 0

	p1StateTime DWORD 0
	p1State     DWORD 0

	p2StateTime DWORD 0
	p2State     DWORD 0


.code

; Put String into the screen
PutAtScreen PROC
	; x position of screen
	; y position of screen
	; size of string
	; offset of string

	LOCAL x: DWORD, y: DWORD
	; moving parameters into x and y
	MOV eax, [ebp + 20]
	MOV x, eax
	MOV eax, [ebp + 16]
	MOV y, eax

	; moving length of string into ecx
	MOV ecx, [ebp + 12]

	; moving offset of array
	MOV edx, [ebp + 8]
	; iterator for array
	MOV ebx, 0

	LoopStart:
		PUSH ecx
		PUSH edx
		; calculating point of screen
		MOV eax, y
		MOV ecx, columns
		MUL ecx
		ADD eax, x

		POP edx

		; if it is 0dh then move to next line
		mov cl, 0dh
		CMP [edx + ebx], cl
		JE newLineCame
		
		; moving character into screen2D
		MOV cl, [edx + ebx]
		MOV screen2D[eax], cl
		
		INC x
		INC ebx

		POP ecx
		LOOP LoopStart
		JMP endprocedure
	newLineCame:
		INC y
		MOV eax, [ebp + 20]
		MOV x, eax
		INC ebx

		POP ecx
		LOOP LoopStart

	endprocedure:
	ret 16

PutAtScreen ENDP

InitializeScreen PROC
	; settings screen2D all values to 32 
	MOV eax, rows
	MOV ebx, columns
	MUL ebx
	MOV ecx, eax

	LoopS:
		MOV screen2D[ecx - 1], 32
		LOOP LoopS

	MOV eax, 0
	MOV ecx, rows
	
	LoopStart:
		; putting '|' on start and end of screen boundary
		MOV screen2D[eax], '|'
		ADD eax, columns-3
		MOV screen2D[eax], '|'
		INC eax

		; putting new line character at the end of line
		MOV screen2D[eax], 0dh      
		INC eax
		MOV screen2D[eax], 0ah
		INC eax
		LOOP LoopStart

	; displaying upper boundary
	push 1
	push 0
	push sizeof screenBoundary
	push offset screenBoundary
	Call PutAtScreen
	
	; displaying lower boundary
	push 1
	push rows-1
	push sizeof screenBoundary
	push offset screenBoundary
	CALL PutAtScreen

	ret

InitializeScreen ENDP



DislayScreen PROC

	MOV edx, OFFSET screen2D
	CALL WriteString
	ret

DislayScreen ENDP

jmpPlayers PROC
	; dec from p1jmp if it is not zero
	CMP p1jmp, 0
	JG p1jump
	MOV p1PosY, 7
	JMP NoSub
	p1jump:
		SUB p1jmp, 1
		ret
	NoSub:

	; dec from p1jmp if it is not zero
	CMP p2jmp, 0
	JG p2jump
	MOV p2PosY, 7
	JMP NoSub2
	p2jump:
		SUB p2jmp, 1
		ret
	NoSub2:
	
		
	ret
jmpPlayers ENDP

setState PROC
	CMP p1StateTime, 0
	JE setStateToDefault1
	SUB p1StateTime, 1
	JMP Next
	setStateToDefault1:
	MOV p1State, 0

	Next:
	CMP p2StateTime, 0
	JE setStateToDefault2
	SUB p2StateTime, 1
	ret
	setStateToDefault2:
	MOV p2State, 0

	ret
setState ENDP

; Handle Keyoard Input
LookForKey PROC
	; ------------ Player1 CONTROLS ---------------

	CMP AL, 'd'
	JNE P1NoL
	INC p1PosX
	ret
	P1NoL:

	CMP AL, 'a'
	JNE P1NoR
	DEC p1PosX
	ret
	P1NoR:

	CMP AL, 'w'
	JNE P1NoJ
	; If player already not jumping then p1jmp should be zero
	CMP p1jmp, 0
	JG P1NOJ
	SUB p1PosY, 3
	MOV p1jmp, pJmpTime
	ret
	P1NoJ:

	CMP AL, 'e'
	JNE P1NoSC            ; Player 1 no state changed
	CMP p1State, 0
	JG P1NoSC
	MOV p1state, 1
	MOV p1StateTime, pStateTime ; Setting time for player1 state
	ret
	P1NoSC:

	; --------- PLAYER 2 CONTROLS ----------------

	CMP AH, 048h ; UP Key
	JNE P2NoJ
	; If player already not jumping then p1jmp should be zero
	CMP p2jmp, 0
	JG P2NOJ
	SUB p2PosY, 3
	MOV p2jmp, pJmpTime
	ret
	P2NoJ:

	CMP AH, 04Bh ; Left Key
	JNE P2NoL
	DEC p2PosX
	ret
	P2NoL:

	CMP AH, 04Dh ; Right
	JNE P2NoR
	INC p2PosX
	ret
	P2NoR:

	CMP AL, '.'
	JNE P2NoSC            ; Player 2 no state changed
	CMP p2State, 0
	JG P2NoSC
	MOV p2state, 1
	MOV p2StateTime, pStateTime ; Setting time for player1 state
	ret
	P2NoSC:

	ret
LookForKey ENDP

DisplayP1 PROC
	push p1PosX
	push p1PosY

	CMP p1State, 0
	JE p1State0
	
	CMP p1State, 1
	JE p1State1
	
	p1State0:
		PUSH SIZEOF char1
		PUSH OFFSET char1
		JMP ShowPlayer

	p1State1:
		PUSH SIZEOF char1su
		PUSH OFFSET char1su
		JMP ShowPlayer

	ShowPlayer:
		CALL PutAtScreen
	ret
DisplayP1 ENDP

DisplayP2 PROC
	CMP p2State, 0
	JE p2State0
	
	CMP p2State, 1
	JE p2State1
	
	p2State0:
		push p2PosX
		push p2PosY
		PUSH SIZEOF char2
		PUSH OFFSET char2
		JMP ShowPlayer

	p2State1:
		Sub p2PosX, 3
		push p2PosX        ; To display character movement propoerly
		Add p2PosX, 3      ; it is needed to 
		push p2PosY
		
		PUSH SIZEOF char2su
		PUSH OFFSET char2su
		JMP ShowPlayer

	ShowPlayer:
		CALL PutAtScreen
	ret
DisplayP2 ENDP

main PROC

	CALL GetMSeconds
	MOV ebx, eax

	MOV ecx, 1000
	
	LoopStart:
		CALL  InitializeScreen

		CALL ReadKey
		JZ NoKeyPressed
		CALL LookForKey
		NoKeyPressed:

		Call jmpPlayers
		Call setState

		call DisplayP1
		

		call DisplayP2

		
		CALL  Clrscr
		CALL  DislayScreen
		MOV   eax, 32
		Call  Delay
		
	JMP LoopStart
	

	CALL GetMSeconds

	SUB eax, ebx

	Call WriteDec

	INVOKE ExitProcess, 0

main endp
end main