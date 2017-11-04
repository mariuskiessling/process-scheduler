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
EXTRN CODE (fkt_text)
EXTRN CODE (printToSerial)


; ------------------------------------------------------------------------------
; Published symbols
; ------------------------------------------------------------------------------
PUBLIC execConsole
PUBLIC execProcessA
PUBLIC execProcessB
PUBLIC execProcessX
PUBLIC finishProcessA
PUBLIC killProcessB


; ------------------------------------------------------------------------------
; Stack definition
; ------------------------------------------------------------------------------
?STACK          			SEGMENT IDATA
	RSEG    ?STACK
	DS      10


; ------------------------------------------------------------------------------
; Data segment and variable definition
; ------------------------------------------------------------------------------
schedulerData 				SEGMENT DATA
	RSEG    schedulerData
stackReservedSpace:			DS  	10
processConsoleInformation:	DS  	3	; Console process meta data
processAInformation:		DS  	3	; Process A meta data
processBInformation:		DS  	3	; Process B meta data
processXInformation:		DS  	3	; Process X meta data
processTimeCounter:			DS		1	; Counter for each process timer
currentProcess:				DS  	1	; Incrementing value representing the
										; current process
processStorage:				DS		96	; Holds the registers and stack of each
										; Console: 	0-7: 	R0-R7; 08-17: Stack
										;			18: 	A;     19:    B
										;			20:		PSW;   21: 	  SP
										;			22:		DPH;   23:    DPL

										; A:		24-31: 	R0-R7; 32-41: Stack
										;			42: 	A;     43:    B
										;			44:		PSW;   45: 	  SP
										;			46:		DPH;   47:    DPL

										; B: 		48-55: 	R0-R7; 56-65: Stack
										;			66: 	A;     67:    B
										;			68:		PSW;   69: 	  SP
										;			70:		DPH;   71:    DPL

										; X: 		72-79: 	R0-R7; 80-89: Stack
										;			90: 	A;     91:    B
										;			92:		PSW;   93: 	  SP
										;			94:		DPH;   95:    DPL


; ------------------------------------------------------------------------------
; Main program entry
; ------------------------------------------------------------------------------
CSEG AT 0
LJMP init


; ------------------------------------------------------------------------------
; Scheduler timer interrupt jump definition
; ------------------------------------------------------------------------------
CSEG AT 1BH
LJMP timerTimeout


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

	MOV TMOD, #00010001b
	;MOV A, IP0
	;SETB ACC.1
	;MOV IP0, A

	MOV A, IP1
	SETB ACC.1
	MOV IP1, A

	MOV currentProcess, #-1

	JMP createProcessTable	; Trigger process tabel creation


; ------------------------------------------------------------------------------
; Checks if set amount of cycles (priority) is reached for the currently
; executed process. If the amount of necessary cycles is reached the scheduler
; interrupt routine is called. If the amount is not yet reached the process is
; restored and executed until the next timer interrupt.
; ------------------------------------------------------------------------------
timerTimeout:
	MOV A, processTimeCounter
	CLR TR1
	JNZ returnToCurrentProcess
	LJMP schedulerInterrupt


; ------------------------------------------------------------------------------
; Decrements priority counter, restores scheduler timer and returns to position
; in subprocess before interrupt was fired.
; ------------------------------------------------------------------------------
returnToCurrentProcess:
	DEC A
	MOV processTimeCounter, A

	CLR TR1
	MOV TL1, #0xE0
	MOV TH1, #0xB1
	SETB TR1
	SETB ET1
	SETB EAL
	RETI

; ------------------------------------------------------------------------------
; Interrupt handler to process the interrupt executed by hardware timer 1.
; Checks if the current process is the console process and saves its state
; (registers and stack) to the according position in the processStorage
; variable.
; ------------------------------------------------------------------------------
schedulerInterrupt:
	MOV processTimeCounter, #0
	CLR TR1

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
	MOV processStorage + 16, 16
	MOV processStorage + 17, 17

	MOV processStorage + 18, A
	MOV processStorage + 19, B
	MOV processStorage + 20, PSW
	MOV processStorage + 21, SP
	MOV processStorage + 22, DPH
	MOV processStorage + 23, DPL

	LJMP circleProcess


; ------------------------------------------------------------------------------
; Checks if the current process is the process A and saves its state (registers
; and stack) to the according position in the processStorage variable.
; ------------------------------------------------------------------------------
saveProcessAState:
	MOV R7, currentProcess
	CJNE R7, #1, saveProcessBState

	MOV processStorage + 24, R0
	MOV processStorage + 25, R1
	MOV processStorage + 26, R2
	MOV processStorage + 27, R3
	MOV processStorage + 28, R4
	MOV processStorage + 29, R5
	MOV processStorage + 30, R6
	MOV processStorage + 31, R7

	MOV processStorage + 32, 08
	MOV processStorage + 33, 09
	MOV processStorage + 34, 10
	MOV processStorage + 35, 11
	MOV processStorage + 36, 12
	MOV processStorage + 37, 13
	MOV processStorage + 38, 14
	MOV processStorage + 39, 15
	MOV processStorage + 40, 16
	MOV processStorage + 41, 17

	MOV processStorage + 42, A
	MOV processStorage + 43, B
	MOV processStorage + 44, PSW
	MOV processStorage + 45, SP
	MOV processStorage + 46, DPH
	MOV processStorage + 47, DPL

	LJMP circleProcess


; ------------------------------------------------------------------------------
; Checks if the current process is the process B and saves its state (registers
; and stack) to the according position in the processStorage variable.
; ------------------------------------------------------------------------------
saveProcessBState:
	MOV R7, currentProcess
	CJNE R7, #2, saveProcessXState

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
	MOV processStorage + 64, 16
	MOV processStorage + 65, 17

	MOV processStorage + 66, A
	MOV processStorage + 67, B
	MOV processStorage + 68, PSW
	MOV processStorage + 69, SP
	MOV processStorage + 70, DPH
	MOV processStorage + 71, DPL

	LJMP circleProcess


; ------------------------------------------------------------------------------
; Checks if the current process is the process X and saves its state (registers
; and stack) to the according position in the processStorage variable.
; ------------------------------------------------------------------------------
saveProcessXState:
	MOV processStorage + 72, R0
	MOV processStorage + 73, R1
	MOV processStorage + 74, R2
	MOV processStorage + 75, R3
	MOV processStorage + 76, R4
	MOV processStorage + 77, R5
	MOV processStorage + 78, R6
	MOV processStorage + 79, R7

	MOV processStorage + 80, 08
	MOV processStorage + 81, 09
	MOV processStorage + 82, 10
	MOV processStorage + 83, 11
	MOV processStorage + 84, 12
	MOV processStorage + 85, 13
	MOV processStorage + 86, 14
	MOV processStorage + 87, 15
	MOV processStorage + 88, 16
	MOV processStorage + 89, 17

	MOV processStorage + 90, A
	MOV processStorage + 91, B
	MOV processStorage + 92, PSW
	MOV processStorage + 93, SP
	MOV processStorage + 94, DPH
	MOV processStorage + 95, DPL

	LJMP circleProcess


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

	MOV processTimeCounter, processConsoleInformation + 8

	MOV TL1, #0xE0							; Reset timer
	MOV TH1, #0xB1							; Reset timer
	SETB TR1								; Reset timer
	SETB ET1								; Reset timer
	SETB EAL								; Reset timer

	MOV DPTR, #startConsole
	PUSH DPL
	PUSH DPH
	RETI


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
	MOV 16, processStorage + 16
	MOV 17, processStorage + 17

	MOV A, processStorage + 18
	MOV B, processStorage + 19
	MOV PSW, processStorage + 20
	MOV SP, processStorage + 21
	MOV DPH, processStorage + 22
	MOV DPL, processStorage + 23

	MOV processTimeCounter, processConsoleInformation + 8

	MOV TL1, #0xE0	; Reset timer
	MOV TH1, #0xB1	; Reset timer
	SETB TR1		; Reset timer
	SETB ET1		; Reset timer
	SETB EAL		; Reset timer

	RETI			; Jump back to position the scheduler's
					; interrupt occurred


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

	MOV processTimeCounter, processAInformation + 8

	MOV TL1, #0xE0					; Reset timer
	MOV TH1, #0xB1					; Reset timer
	SETB TR1						; Reset timer
	SETB ET1						; Reset timer
	SETB EAL						; Reset timer

	MOV DPTR, #startProcessA
	PUSH DPL
	PUSH DPH
	RETI


; ------------------------------------------------------------------------------
; RECOVER CONSOLE PROCESS
; Checks if the console process is running. If it is started the console's
; registers and stack are restored and
; ------------------------------------------------------------------------------
isProcessARunning:
	CJNE R7, #1, circleProcess

	MOV R0, processStorage + 24
	MOV R1, processStorage + 25
	MOV R2, processStorage + 26
	MOV R3, processStorage + 27
	MOV R4, processStorage + 28
	MOV R5, processStorage + 29
	MOV R6, processStorage + 30
	MOV R7, processStorage + 31

	MOV 08, processStorage + 32
	MOV 09, processStorage + 33
	MOV 10, processStorage + 34
	MOV 11, processStorage + 35
	MOV 12, processStorage + 36
	MOV 13, processStorage + 37
	MOV 14, processStorage + 38
	MOV 15, processStorage + 39
	MOV 16, processStorage + 40
	MOV 17, processStorage + 41

	MOV A, processStorage + 42
	MOV B, processStorage + 43
	MOV PSW, processStorage + 44
	MOV SP, processStorage + 45
	MOV DPH, processStorage + 46
	MOV DPL, processStorage + 47

	MOV processTimeCounter, processAInformation + 8

	MOV TL1, #0xE0		; Reset timer
	MOV TH1, #0xB1		; Reset timer
	SETB TR1			; Reset timer
	SETB ET1			; Reset timer
	SETB EAL			; Reset timer

	RETI				; Jump back to position the scheduler's
						; interrupt occurred


; ------------------------------------------------------------------------------
; START PROCESS B
; Checks if process B is scheduled to be started. If it is scheduled the
; process's meta data is updated, set to running, a timer started and the
; process's start label executed.
; ------------------------------------------------------------------------------
evaluateProcessB:
	MOV R7, currentProcess
	CJNE R7, #2, evaluateProcessX

	MOV R7, processBInformation + 0
	CJNE R7, #2, isProcessBRunning

	MOV processBInformation + 0, #1

	MOV processTimeCounter, processBInformation + 8

	MOV TL1, #0xE0		; Reset timer
	MOV TH1, #0xB1		; Reset timer
	SETB TR1			; Reset timer
	SETB ET1			; Reset timer
	SETB EAL			; Reset timer

	MOV DPTR, #startProcessB
	PUSH DPL
	PUSH DPH
	RETI


; ------------------------------------------------------------------------------
; Helper label to enable longer jumps executed by the CJNE command.
; ------------------------------------------------------------------------------
circleProcessShortJumpHelper:
	LJMP circleProcess


; ------------------------------------------------------------------------------
; RECOVER PROCESS B
; Checks if the process B is running. If it is started the process's registers
; and stack are restored and
; ------------------------------------------------------------------------------
isProcessBRunning:
	CJNE R7, #1, circleProcessShortJumpHelper

	MOV R0, processStorage + 48
	MOV R1, processStorage + 49
	MOV R2, processStorage + 50
	MOV R3, processStorage + 51
	MOV R4, processStorage + 52
	MOV R5, processStorage + 53
	MOV R6, processStorage + 54
	MOV R7, processStorage + 55

	MOV 08, processStorage + 56
	MOV 09, processStorage + 57
	MOV 10, processStorage + 58
	MOV 11, processStorage + 59
	MOV 12, processStorage + 60
	MOV 13, processStorage + 61
	MOV 14, processStorage + 62
	MOV 15, processStorage + 63
	MOV 16, processStorage + 64
	MOV 17, processStorage + 65

	MOV A, processStorage + 66
	MOV B, processStorage + 67
	MOV PSW, processStorage + 68
	MOV SP, processStorage + 69
	MOV DPH, processStorage + 70
	MOV DPL, processStorage + 71

	MOV processTimeCounter, processBInformation + 8

	MOV TL1, #0xE0		; Reset timer
	MOV TH1, #0xB1		; Reset timer
	SETB TR1			; Reset timer
	SETB ET1			; Reset timer
	SETB EAL			; Reset timer

	RETI				; Jump back to position the scheduler's
						; interrupt occurred


; ------------------------------------------------------------------------------
; START PROCESS X
; Checks if process X is scheduled to be started. If it is scheduled the
; process's meta data is updated, set to running, a timer started and the
; process's start label executed.
; ------------------------------------------------------------------------------
evaluateProcessX:
	MOV R7, currentProcess
	CJNE R7, #3, resetProcessCircle

	MOV R7, processXInformation + 0
	CJNE R7, #2, isProcessXRunning

	MOV processXInformation + 0, #1

	MOV processTimeCounter, processXInformation + 8

	MOV TL1, #0xE0		; Reset timer
	MOV TH1, #0xB1		; Reset timer
	SETB TR1			; Reset timer
	SETB ET1			; Reset timer
	SETB EAL			; Reset timer

	MOV DPTR, #fkt_text
	PUSH DPL
	PUSH DPH
	RETI


; ------------------------------------------------------------------------------
; RECOVER PROCESS X
; Checks if the process X is running. If it is started the process's registers
; and stack are restored and
; ------------------------------------------------------------------------------
isProcessXRunning:
	CJNE R7, #1, resetProcessCircle

	MOV R0, processStorage + 72
	MOV R1, processStorage + 73
	MOV R2, processStorage + 74
	MOV R3, processStorage + 75
	MOV R4, processStorage + 76
	MOV R5, processStorage + 77
	MOV R6, processStorage + 78
	MOV R7, processStorage + 79

	MOV 08, processStorage + 80
	MOV 09, processStorage + 81
	MOV 10, processStorage + 82
	MOV 11, processStorage + 83
	MOV 12, processStorage + 84
	MOV 13, processStorage + 85
	MOV 14, processStorage + 86
	MOV 15, processStorage + 87
	MOV 16, processStorage + 88
	MOV 17, processStorage + 89

	MOV A, processStorage + 90
	MOV B, processStorage + 91
	MOV PSW, processStorage + 92
	MOV SP, processStorage + 93
	MOV DPH, processStorage + 94
	MOV DPL, processStorage + 95

	MOV processTimeCounter, processXInformation + 8

	MOV TL1, #0xE0		; Reset timer
	MOV TH1, #0xB1		; Reset timer
	SETB TR1			; Reset timer
	SETB ET1			; Reset timer
	SETB EAL			; Reset timer

	RETI				; Jump back to position the scheduler's
						; interrupt occurred


; ------------------------------------------------------------------------------
; Jumps back to beginning of the scheduler's process cycle.
; ------------------------------------------------------------------------------
resetProcessCircle:
	MOV currentProcess, #-1
	JMP circleProcess


; ------------------------------------------------------------------------------
; Builds the process meta information table that holds the state and priority
; of each process. The table stores two information about each process:
; - State (located at offset 0)
; - Process timer timeout / priority (located at offset 8)
;
; The state can hold these values:
; - 0 = Not running
; - 1 = Currently running
; - 2 = Ready (to be started during the next scheduling cycle)
;
; The process timer timeout holds an integer representing a factor of 10ms.
; Thus a priority of '10' guarantees 100ms of process execution.
; ------------------------------------------------------------------------------
createProcessTable:
	MOV processConsoleInformation + 0,  #2
	MOV processConsoleInformation + 8,  #10

	MOV processAInformation + 0,  #0
	MOV processAInformation + 8,  #10

	MOV processBInformation + 0,  #0
	MOV processBInformation + 8,  #20

	MOV processXInformation + 0,  #0
	MOV processXInformation + 8,  #10

	LJMP circleProcess


; ------------------------------------------------------------------------------
; Signals the scheduler to start the console process during the next scheduling
; cycle.
; ------------------------------------------------------------------------------
execConsole:
	MOV processConsoleInformation + 0, #2


; ------------------------------------------------------------------------------
; Signals the scheduler to start process A during the next scheduling cycle.
; ------------------------------------------------------------------------------
execProcessA:
	MOV processAInformation + 0, #2
	RET


; ------------------------------------------------------------------------------
; Signals the scheduler to start process B during the next scheduling cycle.
; ------------------------------------------------------------------------------
execProcessB:
	MOV processBInformation + 0, #2
	RET


; ------------------------------------------------------------------------------
; Signals the scheduler to start process X during the next scheduling cycle.
; ------------------------------------------------------------------------------
execProcessX:
	MOV processXInformation + 0, #2
	RET


; ------------------------------------------------------------------------------
; Signals the scheduler that process A is done executing. Process A however
; still executes until it reaches its maximum execution time.
; ------------------------------------------------------------------------------
finishProcessA:
	MOV processAInformation + 0, #0
	RET


; ------------------------------------------------------------------------------
; Signals the scheduler to kill process B. Updates the meta information of
; process B and stops any timer that was used by process B.
; ------------------------------------------------------------------------------
killProcessB:
	MOV processBInformation + 0, #0
	CLR TR0
	CLR ET0
	RET

END
