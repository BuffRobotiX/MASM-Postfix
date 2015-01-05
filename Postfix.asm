                    .586
                    .MODEL flat, stdcall

                    include win32api.asm

                    .STACK 4096

                    .DATA
                    ;set up equates
CR                  equ     13
LF                  equ     10
MAX_LENGTH          equ     255
PLUS                equ     2Bh
MINUS               equ     2Dh
TIMES               equ     2Ah
SLASH               equ     2Fh
ASCIIOFFSET         equ     30h

UserInput           byte    MAX_LENGTH dup(0)                         ;Variable to store user input string

msg1                byte    "Input a postfix expression:", CR, LF     ;Message to prompt user
negativeSign        byte    "-"                                       ;the negative sign
out                 byte    0h                                        ;variable for displaying outputs

CharsRead           dword    0                                        ;Returned by ReadConsole

BytesWritten        dword    0

hStdOut             dword    0
hStdIn              dword    0

                    .CODE

Main                Proc

                    ;*********************************************
                    ;In order to write to windows console screen
                    ;we need to get a handle to the screen
                    ;*********************************************
                    invoke  GetStdHandle, STD_OUTPUT_HANDLE
                    mov     hStdOut,eax                    ;Save output handle
                                
                    ;*********************************************
                    ;Get a handle to the standard input device
                    ;*********************************************
                    invoke  GetStdHandle, STD_INPUT_HANDLE
                    mov     hStdIn,eax                    ;Save input handle
        
                    ;*********************************************
                    ;Prompt user to input a string
                    ;*********************************************
Start:              invoke  WriteConsoleA, hStdOut, OFFSET msg1, SIZEOF msg1, OFFSET BytesWritten, 0

                    ;*********************************************
                    ;Set Console Mode for Line Input
                    ;*********************************************
                    invoke  SetConsoleMode, hStdIn, ENABLE_LINE_INPUT + ENABLE_ECHO_INPUT 


                    ;*********************************************
                    ;Get User Input
                    ;*********************************************
                    invoke  ReadConsoleA, hStdIn, OFFSET UserInput, SIZEOF UserInput, OFFSET CharsRead, 0


                    ;*********************************************
                    ;If the last character is a carriage return character, then we need
                    ;to subtract one from the number of characters read
                    ;*********************************************
                    mov     edx,CharsRead               ;number of character user entered
                    dec     edx                         ;subtract one since we are zero based
                    cmp     UserInput[edx],CR           ;is the last character a carriage return?
                    jne     NoCR                        ;no...then jump
                    dec     CharsRead                   ;yes...then so subtract 1 from length
NoCR:

                    ;*******************************************************
                    ; Test to see if the user just pressed enter
                    ; If they did then Exit Program
                    ;*******************************************************
                    cmp     CharsRead,0                 ;Did user just press enter
                    je      ExitProg                    ;Yes...then exit

                    ;*******************************************************
                    ; put the data into the stack
                    ;*******************************************************
                    mov     esi, 0h                     ;esi used as index into input string


Read:
                    cmp     UserInput[esi], PLUS        ;check for the plus character
                    je      Add
                    cmp     UserInput[esi], MINUS       ;check for the minus sign
                    je      Subtract
                    cmp     UserInput[esi], TIMES       ;check for the asterick
                    je      Multiply
                    cmp     UserInput[esi], SLASH       ;check for the slash
                    je      Divide

PushNum:                                                ;else it must be a number
                    push    UserInput[esi]              ;push the value
                    inc     esi                         ;point to next input character to read
                    cmp     esi, CharsRead              ;have we reached the end?
                    jne     Read                        ;no, continue
                    jmp     Output                      ;yes, finish

Add:
                    pop bl                              ;pop the first value off the stack, the second operand
                    sub bl, ASCIIOFFSET                 ;convert to hex
                    pop al                              ;pop the second value off the stack, the first operand
                    sub al, ASCIIOFFSET                 ;convert to hex
                    add al, bl                          ;execute
                    push al                             ;push the sum
                    inc esi                             ;increment the index
                    jmp Read                            ;go back

Subtract:
                    pop bl                              ;pop the first value off the stack, the second operand
                    sub bl, ASCIIOFFSET                 ;convert to hex
                    pop al                              ;pop the second value off the stack, the first operand
                    sub al, ASCIIOFFSET                 ;convert to hex
                    sub al, bl                          ;execute
                    push al                             ;push the difference
                    inc esi                             ;increment the index
                    jmp Read                            ;go back

Multiply:
                    pop bl                              ;pop the first value off the stack, the second operand
                    sub bl, ASCIIOFFSET                 ;convert to hex
                    pop al                              ;pop the second value off the stack, the first operand
                    sub al, ASCIIOFFSET                 ;convert to hex
                    imul al, bl                         ;execute
                    push al                             ;push the product
                    inc esi                             ;increment the index
                    jmp Read                            ;go back

Divide:
                    pop bl                              ;pop the first value off the stack, the second operand
                    sub bl, ASCIIOFFSET                 ;convert to hex
                    pop al                              ;pop the second value off the stack, the first operand
                    sub al, ASCIIOFFSET                 ;convert to hex
                    idiv al, bl                         ;execute
                    push al                             ;push the quotient
                    inc esi                             ;increment the index
                    jmp Read                            ;go back

Output:
                    pop al                              ;get the solution
                    mov out, al                         ;put it in the out var
                    cmp al, 0h                          ;check for negativity
                    jl  Negative                        ;display the negative sign
                    invoke  WriteConsoleA, hStdOut, OFFSET out, SIZEOF out, OFFSET BytesWritten, 0                ;otherwise output positive
                    jmp Start                           ;restart to do it again. User can then press enter to end the program

Negative:
                    invoke  WriteConsoleA, hStdOut, OFFSET negativeSign, SIZEOF negativeSign, OFFSET BytesWritten, 0 ;negative sign
                    invoke  WriteConsoleA, hStdOut, OFFSET out, SIZEOF out, OFFSET BytesWritten, 0                   ;output
                    jmp Start                           ;restart to do it again. User can then press enter to end the program

                    ;*************************
                    ;Terminate Program
                    ;*************************
ExitProg:           invoke  ExitProcess,0
Main                ENDP
                    END     Main