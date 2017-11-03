$NOMOD51
#include <Reg517a.inc>

Name ProcessB

EXTRN CODE (main, printToSerial)

PUBLIC startProcessB



; ============================================
; Interrupt Handler
; ============================================

CSEG AT 0BH
LJMP interrupt1

processBCode SEGMENT CODE
			 RSEG processBCode

interrupt1:
INC R0
CJNE R0, #20, wait
MOV A, #"#"
LCALL printToSerial
MOV R0, #00


; ===============================================
; Interrupt Counter
; ===============================================
wait:
	RETI

;SETB PSW.4 ; Lege Regsiter 3 als Speicher fest


; ===============================================
;
; ===============================================
startProcessB:
	MOV R0,#00
	MOV TMOD,#001h
	MOV TH0, #03Ch	; High Bit setzen
	MOV TL0, #0AFh	; Low Bit setzen
	SETB TR0    	; Timer 0 starten
	SETB ET0		; Interrupt f�r Timer 0 aktivieren
	SETB EAL		; Globaler Interrupt aktivieren

loop:
    NOP
    SETB wdt
    SETB swdt
    JMP loop



END
