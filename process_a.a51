$NOMOD51
#include <reg517a.inc>

; ------------------------------------------------------------------------------
; Module name
; ------------------------------------------------------------------------------
Name ProcessA


; ------------------------------------------------------------------------------
; Imported symbols from other modules
; ------------------------------------------------------------------------------
EXTRN CODE (printToSerial)
EXTRN CODE (finishProcessA)


; ------------------------------------------------------------------------------
; Published symbols
; ------------------------------------------------------------------------------
PUBLIC startProcessA


; ------------------------------------------------------------------------------
; Code segement definition
; ------------------------------------------------------------------------------
processACode SEGMENT CODE
             RSEG processACode


; ================================ Module code =================================

; ------------------------------------------------------------------------------
; Start procedure for process A. Prints the string edcba to serial.
; ------------------------------------------------------------------------------
startProcessA:
	MOV A, #"e"
	CALL printToSerial
	MOV A, #"d"
	CALL printToSerial
	MOV A, #"c"
	CALL printToSerial
	MOV A, #"b"
	CALL printToSerial
	MOV A, #"a"
	CALL printToSerial

    CALL finishProcessA

END
