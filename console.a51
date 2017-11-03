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
; Start procedure for console process
; ------------------------------------------------------------------------------
startConsole:
	NOP
	CLR SM0             	; Setze Bit auf 0, 8-Bit UART, Baudrate variable einstellbar
	SETB SM1             	; Setze Bit auf 1
	SETB REN0             	; Setze Bit auf 1, Empfang �ber serielle Schnittstelle zulassen
	SETB BD             	; Setze Bit auf 1, Baudrate durch Bautratengenerator
	MOV S0RELH, #0EFH
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
; Waits for any input and triggers the checking of the entered character
; ------------------------------------------------------------------------------
inputIsA:
    CALL execProcessA       ; Tell scheduler to start process A
    SJMP waitForInput

inputIsNotA:
    CJNE A, #'b', inputIsNotB

inputIsB:
    CALL execProcessB       ; Tell scheduler to start process B
    SJMP waitForInput

inputIsNotB:
    CJNE A, #'c', inputIsNotC

inputIsC:
    nop                     ; Tell scheduler to stop process B
    SJMP waitForInput

inputIsNotC:
    CJNE A, #'z', inputIsNotZ

inputIsZ:
    nop            ; Starte Text Prozess
    SJMP waitForInput
inputIsNotZ:
    LJMP waitForInput

END
