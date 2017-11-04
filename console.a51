$NOMOD51
#include <Reg517a.inc>

; ------------------------------------------------------------------------------
; Module name
; ------------------------------------------------------------------------------
Name Console


; ------------------------------------------------------------------------------
; Imported symbols from other modules
; ------------------------------------------------------------------------------
EXTRN CODE (printToSerial)
EXTRN CODE (execProcessA)
EXTRN CODE (execProcessB)
EXTRN CODE (execProcessX)
EXTRN CODE (killProcessB)


; ------------------------------------------------------------------------------
; Published symbols
; ------------------------------------------------------------------------------
PUBLIC startConsole


; ------------------------------------------------------------------------------
; Code segement definition
; ------------------------------------------------------------------------------
consoleProcessCode	SEGMENT CODE
             		RSEG consoleProcessCode


; ================================ Module code =================================

; ------------------------------------------------------------------------------
; Start procedure for the console process
; ------------------------------------------------------------------------------
startConsole:
    NOP
    CLR SM0                ; Setup serial interface
    SETB SM1               ; Setup serial interface
    SETB REN0              ; Enable serial receive
    SETB BD                ; Setup serial interface
    MOV S0RELH, #0EFH      ;
    MOV S0RELL, #0F3H
    JMP waitForInput


; ------------------------------------------------------------------------------
; Waits for any input and triggers the checking of the entered character
; ------------------------------------------------------------------------------
waitForInput:
    SETB wdt                ; Disable watchdog
    SETB swdt               ; Disable watchdog
    JNB RI0, waitForInput
    MOV A, S0BUF            ; Write buffer to A
    CLR RI0

    ; OPTIONAL DEBUG
    ; CALL printToSerial

    CJNE A, #'a', inputIsNotA

; ------------------------------------------------------------------------------
; Tells the scheduler to start process A. Is called if the entered character is
; an 'a'.
; ------------------------------------------------------------------------------
inputIsA:
    CALL execProcessA   ; Tell scheduler to start process A
    SJMP waitForInput


; ------------------------------------------------------------------------------
; Checks if the entered character is not a 'b'. If the given input is a 'b' the
; next label is executed.
; ------------------------------------------------------------------------------
inputIsNotA:
    CJNE A, #'b', inputIsNotB


; ------------------------------------------------------------------------------
; Tells the scheduler to start process B. Is called if the entered character is
; an 'b'.
; ------------------------------------------------------------------------------
inputIsB:
    CALL execProcessB   ; Tell scheduler to start process B
    SJMP waitForInput


; ------------------------------------------------------------------------------
; Checks if the entered character is not a 'c'. If the given input is a 'c' the
; next label is executed.
; ------------------------------------------------------------------------------
inputIsNotB:
    CJNE A, #'c', inputIsNotC


; ------------------------------------------------------------------------------
; Tells the scheduler to kill process B. Is called if the entered character is
; an 'c'.
; ------------------------------------------------------------------------------
inputIsC:
    CALL killProcessB   ; Tell scheduler to stop process B
    SJMP waitForInput


; ------------------------------------------------------------------------------
; Checks if the entered character is not a 'z'. If the given input is a 'z' the
; next label is executed.
; ------------------------------------------------------------------------------
inputIsNotC:
    CJNE A, #'z', inputIsNotZ


; ------------------------------------------------------------------------------
; Tells the scheduler to start process Z. Is called if the entered character is
; an 'z'.
; ------------------------------------------------------------------------------
inputIsZ:
    CALL execProcessX
    SJMP waitForInput


; ------------------------------------------------------------------------------
; Returns to waiting for the next input.
; ------------------------------------------------------------------------------
inputIsNotZ:
    LJMP waitForInput

END
