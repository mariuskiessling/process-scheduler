$NOMOD51
#include <reg517a.inc>

Name SerialManager
	
PUBLIC printToSerial

serialManagerCode SEGMENT CODE
				  RSEG serialManagerCode

printToSerial:
	CLR TI0
	MOV S0BUF, A
	JNB TI0,$
	RET
	
END