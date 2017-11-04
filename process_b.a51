$NOMOD51
#include <Reg517a.inc>

; ------------------------------------------------------------------------------
; Module name
; ------------------------------------------------------------------------------
Name ProcessB


; ------------------------------------------------------------------------------
; Imported symbols from other modules
; ------------------------------------------------------------------------------
EXTRN CODE (printToSerial)


; ------------------------------------------------------------------------------
; Published symbols
; ------------------------------------------------------------------------------
PUBLIC startProcessB


; ------------------------------------------------------------------------------
; Process B timer interrupt jump definition
; ------------------------------------------------------------------------------
CSEG AT 00BH
LJMP timerInterrupt


; ------------------------------------------------------------------------------
; Code segement definition
; ------------------------------------------------------------------------------
processBCode SEGMENT CODE
			 RSEG processBCode


; ================================ Module code =================================

 ; ------------------------------------------------------------------------------
 ; Starts process B and configures its timer
 ; ------------------------------------------------------------------------------
 startProcessB:
 	MOV R0,#00
 	MOV TL0, #0xE0
 	MOV TH0, #0xB1
 	SETB TR0
 	SETB ET0
 	SETB EAL
 	JMP waitLoop


; ------------------------------------------------------------------------------
; Checks if 10 interrupts have been triggered. If interrupt count has been
; reached '#' is printed the interrupt count reset.
; ------------------------------------------------------------------------------
timerInterrupt:
	INC R0
	CJNE R0, #10, returnOperation
	MOV A, #"#"
	LCALL printToSerial
	MOV R0, #00


; ------------------------------------------------------------------------------
; Triggers RETI to return to normal operation of process B and wait for the next
; interrupt.
; ------------------------------------------------------------------------------
returnOperation:
	RETI


; ------------------------------------------------------------------------------
; Loops through empty loop until the next timer interrupt is fired.
; ------------------------------------------------------------------------------
waitLoop:
	SETB wdt		; Disable watchdog
	SETB swdt		; Disable watchdog
	JMP waitLoop

END
