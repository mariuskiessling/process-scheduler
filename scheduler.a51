$NOMOD51
#include <reg517a.inc>

; ------------------------------------------------------------------------------
; Module name
; ------------------------------------------------------------------------------
NAME Scheduler


; ------------------------------------------------------------------------------
; Imported symbols from other modules
; ------------------------------------------------------------------------------
EXTRN CODE (startConsole)
EXTRN CODE (startProcessA)
EXTRN CODE (startProcessB)
EXTRN CODE (printToSerial)


; ------------------------------------------------------------------------------
; Published symbols
; ------------------------------------------------------------------------------
PUBLIC main
PUBLIC execConsole
PUBLIC execProcessA
PUBLIC execProcessB
PUBLIC execProcessX
PUBLIC finishProcessA


; ------------------------------------------------------------------------------
; Stack definition
; ------------------------------------------------------------------------------
?STACK          			SEGMENT IDATA
							RSEG    ?STACK
							DS      8


; ------------------------------------------------------------------------------
; Data segment and variable definition
; ------------------------------------------------------------------------------
schedulerData 				SEGMENT DATA
							RSEG    schedulerData
processConsoleInformation:	DS  	3	; Console process meta data
processAInformation:		DS  	3	; Process A meta data
processBInformation:		DS  	3	; Process B meta data
processXInformation:		DS  	3	; Process X meta data
currentProcess:				DS  	1	; Incrementing value representing the
										; current process
processStorage:				DS		64	; Holds the registers and stack of each
										; Console: 	0-7: 	R0-R7; 08-15: Stack
										; A:		16-23: 	R0-R7; 24-31: Stack
										; B: 		32-39: 	R0-R7; 40-47: Stack
										; X: 		48-55: 	R0-R7; 56-63: Stack


; ------------------------------------------------------------------------------
; Main program entry
; ------------------------------------------------------------------------------
CSEG AT 0
LJMP init


; ------------------------------------------------------------------------------
; Scheduler timer interrupt jump definition
; ------------------------------------------------------------------------------
CSEG AT 1BH
LJMP schedulerInterrupt


; ------------------------------------------------------------------------------
; Code segement definition
; ------------------------------------------------------------------------------
schedulerCode SEGMENT CODE
              RSEG schedulerCode


; ================================ Module code =================================

; ------------------------------------------------------------------------------
; Init procedure to locate the stack and disable the watchdog.
; ------------------------------------------------------------------------------
init:
	MOV SP, #?STACK-1 		; Assign stack
	SETB wdt				; Disable watchdog
    SETB swdt				; Disable watchdog

	JMP createProcessTable	; Trigger process tabel creation

; ------------------------------------------------------------------------------
; Interrupt handler to process the interrupt executed by hardware timer 1.
; Checks if the current process is the console process and saves its state
; (registers and stack) to the according position in the processStorage
; variable.
; ------------------------------------------------------------------------------
schedulerInterrupt:
	MOV R7, currentProcess
	CJNE R7, #0, saveProcessAState
	MOV processStorage + 0, R0
	MOV processStorage + 1, R1
	MOV processStorage + 2, R2
	MOV processStorage + 3, R3
	MOV processStorage + 4, R4
	MOV processStorage + 5, R5
	MOV processStorage + 6, R6
	MOV processStorage + 7, R7

	MOV processStorage + 8, 08
	MOV processStorage + 9, 09
	MOV processStorage + 10, 10
	MOV processStorage + 11, 11
	MOV processStorage + 12, 12
	MOV processStorage + 13, 13
	MOV processStorage + 14, 14
	MOV processStorage + 15, 15

	LJMP circleProcess


; ------------------------------------------------------------------------------
; Checks if the current process is the process A and saves its state (registers
; and stack) to the according position in the processStorage variable.
; ------------------------------------------------------------------------------
saveProcessAState:
	MOV R7, currentProcess
	CJNE R7, #1, saveProcessBState

	MOV processStorage + 16, R0
	MOV processStorage + 17, R1
	MOV processStorage + 18, R2
	MOV processStorage + 19, R3
	MOV processStorage + 20, R4
	MOV processStorage + 21, R5
	MOV processStorage + 22, R6
	MOV processStorage + 23, R7

	MOV processStorage + 24, 08
	MOV processStorage + 25, 09
	MOV processStorage + 26, 10
	MOV processStorage + 27, 11
	MOV processStorage + 28, 12
	MOV processStorage + 29, 13
	MOV processStorage + 30, 14
	MOV processStorage + 31, 15

	LJMP circleProcess


; ------------------------------------------------------------------------------
; Checks if the current process is the process B and saves its state (registers
; and stack) to the according position in the processStorage variable.
; ------------------------------------------------------------------------------
saveProcessBState:
	MOV R7, currentProcess
	CJNE R7, #2, saveProcessXState

	MOV processStorage + 32, R0
	MOV processStorage + 33, R1
	MOV processStorage + 34, R2
	MOV processStorage + 35, R3
	MOV processStorage + 36, R4
	MOV processStorage + 37, R5
	MOV processStorage + 38, R6
	MOV processStorage + 39, R7

	MOV processStorage + 40, 08
	MOV processStorage + 41, 09
	MOV processStorage + 42, 10
	MOV processStorage + 43, 11
	MOV processStorage + 44, 12
	MOV processStorage + 45, 13
	MOV processStorage + 46, 14
	MOV processStorage + 47, 15

	LJMP circleProcess


; ------------------------------------------------------------------------------
; Checks if the current process is the process X and saves its state (registers
; and stack) to the according position in the processStorage variable.
; ------------------------------------------------------------------------------
saveProcessXState:
	MOV processStorage + 48, R0
	MOV processStorage + 49, R1
	MOV processStorage + 50, R2
	MOV processStorage + 51, R3
	MOV processStorage + 52, R4
	MOV processStorage + 53, R5
	MOV processStorage + 54, R6
	MOV processStorage + 55, R7

	MOV processStorage + 56, 08
	MOV processStorage + 57, 09
	MOV processStorage + 58, 10
	MOV processStorage + 59, 11
	MOV processStorage + 60, 12
	MOV processStorage + 61, 13
	MOV processStorage + 62, 14
	MOV processStorage + 63, 15

	LJMP circleProcess


main:
	;CALL startProcessA
	NOP
	JMP startProcessB
    JMP main



; ------------------------------------------------------------------------------
; Cycles through the processes that can be managed by the process scheduler.
; This is the entry point for each process cycle. The correct process is
; scheduled based on the value stored inside the currentProcess variable. It can
; contain these values:
; 0 = Console
; 1 = Process A
; 2 = Process B
; 3 = Process X
; ------------------------------------------------------------------------------
circleProcess:
	SETB wdt						; Disable watchdog
	SETB swdt						; Disable watchdog

	INC currentProcess				; Increment process identifier

	MOV R7, currentProcess
	CJNE R7, #0, evaluateProcessA	; Jump if currentProcess is not the console
	JMP evaluateConsoleProcess		; Jump if currentProcess is the console


; ------------------------------------------------------------------------------
; START CONSOLE PROCESS
; Checks if the console process is scheduled to be started. If it is scheduled
; the console's meta data is updated, set to running, a timer started and the
; console's start label executed.
; ------------------------------------------------------------------------------
evaluateConsoleProcess:
	MOV R7, processConsoleInformation + 0
	CJNE R7, #2, isConsoleRunning			; Jump if console is not scheduled
											; to be started

	MOV processConsoleInformation + 0, #1	; Set console process meta data
											; status to running
	CALL startTimer							; Call for the timer to be started
	LJMP startConsole						; Jump to start of console process


; ------------------------------------------------------------------------------
; RECOVER CONSOLE PROCESS
; Checks if the console process is running. If it is started the console's
; registers and stack are restored and
; ------------------------------------------------------------------------------
isConsoleRunning:
	CJNE R7, #1, circleProcess
	MOV R0, processStorage + 0
	MOV R1, processStorage + 1
	MOV R2, processStorage + 2
	MOV R3, processStorage + 3
	MOV R4, processStorage + 4
	MOV R5, processStorage + 5
	MOV R6, processStorage + 6
	MOV R7, processStorage + 7

	MOV 08, processStorage + 8
	MOV 09, processStorage + 9
	MOV 10, processStorage + 10
	MOV 11, processStorage + 11
	MOV 12, processStorage + 12
	MOV 13, processStorage + 13
	MOV 14, processStorage + 14
	MOV 15, processStorage + 15

	RETI							; Jump back to position the scheduler's
									; interrupt occurred


; ------------------------------------------------------------------------------
; START PROCESS A
; Checks if process A is scheduled to be started. If it is scheduled the
; process's meta data is updated, set to running, a timer started and the
; process's start label executed.
; ------------------------------------------------------------------------------
evaluateProcessA:
	MOV R7, currentProcess
	CJNE R7, #1, evaluateProcessB	; Jump if process B is not scheduled to be
									; started

	MOV R7, processAInformation + 0 ; Set console process meta data
									; status to running

	CJNE R7, #2, isProcessARunning
	MOV processAInformation + 0, #1
	;CALL startTimer
	LJMP startProcessA
	;starte ProzessA Methode

isProcessARunning:
	CJNE R7, #1, circleProcess

	MOV processAInformation + 0, #1
	LJMP startProcessA
	; Starte Process A
	MOV A, #'A'
	CALL printToSerial
	JMP circleProcess

evaluateProcessB:
	MOV R7, currentProcess
	CJNE R7, #2, evaluateProcessX
	MOV R7, processBInformation + 0
	CJNE R7, #2, isProcessBRunning

	;start ProzessB Methode

isProcessBRunning:
	CJNE R7, #1, circleProcess
	; Start Process B
	MOV A, #'B'
	CALL printToSerial
	JMP circleProcess

evaluateProcessX:
	MOV R7, currentProcess
	CJNE R7, #3, resetProcessCircle
	MOV R7, processXInformation + 0

	CJNE R7, #2, isProcessXRunning

	;starte ProzessX Methode
isProcessXRunning:
	CJNE R7, #1, resetProcessCircle
	; Start Process X
	MOV A, #'X'
	CALL printToSerial
	JMP resetProcessCircle

resetProcessCircle:
	MOV currentProcess, #-1
	JMP circleProcess


createProcessTable:
	MOV currentProcess, #-1

	MOV processConsoleInformation + 0,  #2		; State (0 = Not running, 1 = Running, 2 = Ready)
	MOV processConsoleInformation + 8,  #0		; PC
	MOV processConsoleInformation + 16, #0		; Time slot width

	MOV processAInformation + 0,  #0		; State (0 = Not running, 1 = Running, 2 = Ready)
	MOV processAInformation + 8,  #0		; PC
	MOV processAInformation + 16, #0		; Time slot width

	MOV processBInformation + 0,  #0		; State (0 = Not running, 1 = Running, 2 = Ready)
	MOV processBInformation + 8,  #0		; PC
	MOV processBInformation + 16, #0		; Time slot width

	MOV processXInformation + 0,  #0		; State (0 = Not running, 1 = Running, 2 = Ready)
	MOV processXInformation + 8,  #0		; PC
	MOV processXInformation + 16, #0		; Time slot width

	LJMP circleProcess
	;RET


execConsole:
	MOV processConsoleInformation + 0, #2


execProcessA:
	MOV processAInformation + 0, #2
	RET

execProcessB:
	MOV processBInformation + 0, #2
	RET

execProcessX:
	MOV processXInformation + 0, #2
	RET

finishProcessA:
	MOV processAInformation + 0, #0
	RET

startTimer:
	MOV TMOD,#010h
	MOV TH1, #03Ch	; High Bit setzen
	MOV TL1, #0AFh	; Low Bit setzen
	SETB TR1    	; Timer 0 starten
	SETB ET1		; Interrupt f�r Timer 0 aktivieren
	SETB EAL		; Globaler Interrupt aktivieren
	RET

END
