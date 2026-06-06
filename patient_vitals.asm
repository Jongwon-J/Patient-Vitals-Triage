; =========================================================================
; Patient Vital Signs Sorting and High-Risk Filtering System
; Target: EMU8086 Emulator / TASM / MASM (Universal DOSBox compatible)
; =========================================================================

; Header & Macro (프로그램 기본 선언부)
.MODEL SMALL
.STACK 100h

PUTC MACRO arg
    PUSH AX
    MOV AL, arg
    MOV AH, 0Eh
    INT 10h
    POP AX
ENDM

.DATA ; Data Variables & Values
    N               DW 0 ; Number of patients (1 to 100)
    I               DW 0 ; Loop counter variable
    FILTER_MODE     DB 0 ; 0 = Display All, 1 = Display High-Risk Only
    
    ; Parallel Arrays
    PATIENT_ID      DB 100 DUP(?)
    HEART_RATE      DB 100 DUP(?)
    TEMPERATURE     DW 100 DUP(?) ; stored as tenths of degrees C (e.g. 36.5C -> 365)
    BLOOD_PRESSURE  DB 100 DUP(?)
    
    ; Strings & UI Texts
    MSG_TITLE       DB '=== PATIENT VITAL SIGNS MONITORING & RISK FILTERING SYSTEM ===',0
    MSG_ENTER_N     DB 'Enter the number of patients (1-100): ',0
    MSG_PATIENT_HDR DB 0Dh,0Ah,'--- Enter Data for Patient #',0
    MSG_COLON       DB ': ---',0Dh,0Ah,0
    
    MSG_ENTER_ID    DB '  Enter Patient ID (1-255): ',0
    MSG_ENTER_HR    DB '  Enter Heart Rate (bpm): ',0
    MSG_ENTER_TEMP  DB '  Enter Temp (tenths of C, e.g. 36.5C -> 365): ',0
    MSG_ENTER_BP    DB '  Enter Systolic BP (mmHg): ',0
    
    MSG_MENU_HDR    DB 0Dh,0Ah,0Dh,0Ah,'==================== M E N U ====================',0
    MSG_MENU_1      DB '1. Display All Patients',0
    MSG_MENU_2      DB '2. Sort Patients by Heart Rate (Descending)',0
    MSG_MENU_3      DB '3. Sort Patients by Temperature (Descending)',0
    MSG_MENU_4      DB '4. Sort Patients by Blood Pressure (Descending)',0
    MSG_MENU_5      DB '5. Filter and Display High-Risk Patients Only',0
    MSG_MENU_6      DB '6. Input New Patient Dataset',0
    MSG_MENU_7      DB '7. Exit System',0
    MSG_MENU_CH     DB 'Enter your choice (1-7): ',0
    
    MSG_LEGEND      DB '* Unit Legend: HR (bpm) | TEMP (Celsius) | BP (mmHg)',0Dh,0Ah,0
    MSG_TABLE_HDR   DB 'ID',09h,'HR',09h,'TEMP',09h,'BP',09h,'STATUS',0Dh,0Ah
                    DB '-------------------------------------------------------------',0
    
    MSG_STATUS_OK   DB 'Normal',0
    MSG_STATUS_HR   DB 'HIGH RISK',0
    
    MSG_SORT_HR_OK  DB 0Dh,0Ah,'Dataset successfully sorted by Heart Rate!',0
    MSG_SORT_TMP_OK DB 0Dh,0Ah,'Dataset successfully sorted by Temperature!',0
    MSG_SORT_BP_OK  DB 0Dh,0Ah,'Dataset successfully sorted by Blood Pressure!',0
    
    MSG_PRESS_KEY   DB 0Dh,0Ah,'Press any key to return to the menu...',0
    MSG_NO_PATIENTS DB 0Dh,0Ah,'No patient data available. Please input data first.',0
    MSG_HIGH_RISK_ONLY DB '*** HIGH-RISK PATIENT FILTERED REPORT ***',0Dh,0Ah,0
    MSG_NO_RISK     DB 'No high-risk patients found in the current dataset.',0
    MSG_EXIT        DB 0Dh,0Ah,'Exiting system. Thank you for using our system!',0Dh,0Ah,0

.CODE

START:
    ; Initialize data segment
    MOV AX, @DATA
    MOV DS, AX
    
    ; Initial Screen Setup (Blue background, white text)
    CALL CLEAR_SCREEN
    
    ; Welcome header
    LEA SI, MSG_TITLE
    CALL PRINT_STRING
    PUTC 0Dh
    PUTC 0Ah
    PUTC 0Dh
    PUTC 0Ah
    
    ; Input initial dataset
    CALL INPUT_DATASET

MENU_LOOP: ; MENU
    CALL CLEAR_SCREEN 
    LEA SI, MSG_MENU_HDR ; MSG_MENU_HDR에 SI 레지스터 주소를 넣는다
    CALL PRINT_STRING
    PUTC 0Dh ; 0Dh : Carriage Return (커서를 맨 앞으로 보내는 동작)
    PUTC 0Ah ; 0Ah : Line Feed (엔터 효과)
    
    LEA SI, MSG_MENU_1
    CALL PRINT_STRING
    PUTC 0Dh
    PUTC 0Ah
    
    LEA SI, MSG_MENU_2
    CALL PRINT_STRING
    PUTC 0Dh
    PUTC 0Ah
    
    LEA SI, MSG_MENU_3
    CALL PRINT_STRING
    PUTC 0Dh
    PUTC 0Ah
    
    LEA SI, MSG_MENU_4
    CALL PRINT_STRING
    PUTC 0Dh
    PUTC 0Ah
    
    LEA SI, MSG_MENU_5
    CALL PRINT_STRING
    PUTC 0Dh
    PUTC 0Ah
    
    LEA SI, MSG_MENU_6
    CALL PRINT_STRING
    PUTC 0Dh
    PUTC 0Ah
    
    LEA SI, MSG_MENU_7
    CALL PRINT_STRING
    PUTC 0Dh
    PUTC 0Ah
    
    LEA SI, MSG_MENU_CH
    CALL PRINT_STRING
    
    ; Read user option
    MOV AH, 00h
    INT 16h ; BIOS keypress (returns char in AL)
    
    CMP AL, '1'
    JE  OP_DISPLAY
    CMP AL, '2'
    JE  OP_SORT_HR
    CMP AL, '3'
    JE  OP_SORT_TEMP
    CMP AL, '4'
    JE  OP_SORT_BP
    CMP AL, '5'
    JE  OP_FILTER_RISK
    CMP AL, '6'
    JE  OP_INPUT_NEW
    CMP AL, '7'
    JNE OP_NOT_EXIT
    JMP OP_EXIT

OP_NOT_EXIT:
    JMP MENU_LOOP

OP_DISPLAY: ; Print all Patients
    MOV FILTER_MODE, 0 ; 0 (See all patients)
    CALL DISPLAY_TABLE ; Create patients table
    JMP MENU_LOOP ; Return Initial Menu screen

OP_SORT_HR: ; Sort by Heart rate
    CMP N, 0 
    JE  NO_DATA_ERR
    CALL SORT_BY_HR
    LEA SI, MSG_SORT_HR_OK
    CALL PRINT_STRING
    MOV FILTER_MODE, 0
    CALL DISPLAY_TABLE
    JMP MENU_LOOP

OP_SORT_TEMP: ; Sort by Temperature
    CMP N, 0
    JE  NO_DATA_ERR
    CALL SORT_BY_TEMP
    LEA SI, MSG_SORT_TMP_OK
    CALL PRINT_STRING
    MOV FILTER_MODE, 0
    CALL DISPLAY_TABLE
    JMP MENU_LOOP

OP_SORT_BP: ; Sort by Body pressure
    CMP N, 0
    JE  NO_DATA_ERR
    CALL SORT_BY_BP
    LEA SI, MSG_SORT_BP_OK
    CALL PRINT_STRING
    MOV FILTER_MODE, 0
    CALL DISPLAY_TABLE
    JMP MENU_LOOP

OP_FILTER_RISK: ; Filtering only high-risk patients
    CMP N, 0
    JE  NO_DATA_ERR
    MOV FILTER_MODE, 1 ; 1 (Filter only high-risk groups to view)
    CALL DISPLAY_TABLE
    JMP MENU_LOOP

OP_INPUT_NEW: ; Getting a new input
    CALL CLEAR_SCREEN
    CALL INPUT_DATASET
    JMP MENU_LOOP

NO_DATA_ERR: ; Exception Handling Shield
    LEA SI, MSG_NO_PATIENTS
    CALL PRINT_STRING
    LEA SI, MSG_PRESS_KEY
    CALL PRINT_STRING
    MOV AH, 00h
    INT 16h
    JMP MENU_LOOP

OP_EXIT:
    CALL CLEAR_SCREEN
    LEA SI, MSG_EXIT
    CALL PRINT_STRING
    MOV AX, 4C00h ; Exit to DOS
    INT 21h

; ---------------------------------------------------------
; Procedures
; ---------------------------------------------------------

CLEAR_SCREEN PROC NEAR
    MOV AH, 06h
    MOV AL, 00h    ; clear whole screen
    MOV BH, 1Fh    ; Attribute: 1 (Blue background), F (White text)
    MOV CX, 0000h  ; Top-left (0,0)
    MOV DX, 184Fh  ; Bottom-right (24,79)
    INT 10h
    
    ; Reset cursor to (0,0)
    MOV AH, 02h
    MOV BH, 00h
    MOV DX, 0000h
    INT 10h
    RET
CLEAR_SCREEN ENDP

INPUT_DATASET PROC NEAR
INPUT_N_LOOP:
    LEA SI, MSG_ENTER_N
    CALL PRINT_STRING
    CALL SCAN_NUM ; leaves value in CX
    PUTC 0Dh
    PUTC 0Ah
    CMP CX, 1
    JL  INPUT_N_LOOP
    CMP CX, 100
    JG  INPUT_N_LOOP
    MOV N, CX
    
    ; Loop to enter patient details
    MOV I, 0
INPUT_CELLS:
    LEA SI, MSG_PATIENT_HDR
    CALL PRINT_STRING
    MOV AX, I
    INC AX
    CALL PRINT_NUM_UNS
    LEA SI, MSG_COLON
    CALL PRINT_STRING
    
    ; Enter ID
    LEA SI, MSG_ENTER_ID
    CALL PRINT_STRING
    CALL SCAN_NUM
    MOV BX, I
    MOV PATIENT_ID[BX], CL
    PUTC 0Dh
    PUTC 0Ah
    
    ; Enter Heart Rate
    LEA SI, MSG_ENTER_HR
    CALL PRINT_STRING
    CALL SCAN_NUM
    MOV BX, I
    MOV HEART_RATE[BX], CL
    PUTC 0Dh
    PUTC 0Ah
    
    ; Enter Temperature
    LEA SI, MSG_ENTER_TEMP
    CALL PRINT_STRING
    CALL SCAN_NUM
    MOV BX, I
    SHL BX, 1
    MOV TEMPERATURE[BX], CX
    PUTC 0Dh
    PUTC 0Ah
    
    ; Enter BP
    LEA SI, MSG_ENTER_BP
    CALL PRINT_STRING
    CALL SCAN_NUM
    MOV BX, I
    MOV BLOOD_PRESSURE[BX], CL
    PUTC 0Dh
    PUTC 0Ah
    
    INC I
    MOV AX, I
    CMP AX, N
    JGE INPUT_CELLS_DONE
    JMP INPUT_CELLS
INPUT_CELLS_DONE:
    RET
INPUT_DATASET ENDP

CHECK_RISK PROC NEAR
    ; Input: SI = Patient index
    ; Output: AL = 0 if normal, 1 if high risk
    
    ; Check Heart Rate
    MOV AL, HEART_RATE[SI]
    CMP AL, 60
    JB  RISK_HIGH
    CMP AL, 100
    JA  RISK_HIGH
    
    ; Check Blood Pressure
    MOV AL, BLOOD_PRESSURE[SI]
    CMP AL, 90
    JB  RISK_HIGH
    CMP AL, 139
    JA  RISK_HIGH
    
    ; Check Temperature (DW array, offset SI * 2)
    MOV DI, SI
    SHL DI, 1
    MOV AX, TEMPERATURE[DI]
    CMP AX, 360 ; 36.0 C
    JB  RISK_HIGH
    CMP AX, 379 ; 37.9 C
    JA  RISK_HIGH
    
    MOV AL, 0
    RET
    
RISK_HIGH:
    MOV AL, 1
    RET
CHECK_RISK ENDP

PRINT_TEMP PROC NEAR
    ; Input: AX = Temperature (tenths of a degree, e.g. 365)
    ; Output: prints to screen as e.g. "36.5"
    MOV DX, 0
    MOV CX, 10
    DIV CX              ; AX = quotient, DX = remainder
    
    PUSH DX             ; Save remainder
    CALL PRINT_NUM_UNS  ; Print whole part
    PUTC '.'
    POP AX              ; Load remainder
    CALL PRINT_NUM_UNS  ; Print fractional part
    RET
PRINT_TEMP ENDP

PRINT_STRING_COLOR PROC NEAR
    ; Input: SI = offset of 0-terminated string
    ;        BL = Color attribute
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    CLD
    
COLOR_LOOP:
    LODSB
    CMP AL, 0
    JE  COLOR_DONE
    
    ; Get cursor position
    MOV AH, 03h
    MOV BH, 0
    INT 10h             ; Returns DH = row, DL = col
    
    ; Print character with attribute
    MOV AH, 09h
    MOV BH, 0
    MOV CX, 1
    INT 10h
    
    ; Advance cursor
    INC DL
    MOV AH, 02h
    MOV BH, 0
    INT 10h
    
    JMP COLOR_LOOP
    
COLOR_DONE:
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PRINT_STRING_COLOR ENDP

DISPLAY_TABLE PROC NEAR
    CALL CLEAR_SCREEN
    
    CMP FILTER_MODE, 1
    JE  DISP_FILTER_HDR
    
    LEA SI, MSG_TITLE
    CALL PRINT_STRING
    PUTC 0Dh
    PUTC 0Ah
    JMP DISP_TABLE_START
    
DISP_FILTER_HDR:
    LEA SI, MSG_HIGH_RISK_ONLY
    CALL PRINT_STRING
    
DISP_TABLE_START:
    PUTC 0Dh
    PUTC 0Ah
    LEA SI, MSG_LEGEND
    CALL PRINT_STRING
    PUTC 0Dh
    PUTC 0Ah
    
    LEA SI, MSG_TABLE_HDR
    CALL PRINT_STRING
    PUTC 0Dh
    PUTC 0Ah
    
    MOV I, 0
    MOV CX, 0 ; Rows printed counter
    
DISP_ROW_LOOP:
    MOV AX, I
    CMP AX, N
    JL  DISP_CONTINUE
    JMP DISP_COMPLETE
DISP_CONTINUE:
    
    CMP FILTER_MODE, 1
    JNE DISP_PRINT_ROW
    
    ; Check if high risk
    MOV SI, I
    CALL CHECK_RISK
    CMP AL, 1
    JE  DISP_PRINT_ROW
    JMP DISP_NEXT_ROW
    
DISP_PRINT_ROW:
    INC CX ; Row printed
    
    ; ID
    MOV BX, I
    MOV AL, PATIENT_ID[BX]
    MOV AH, 0
    CALL PRINT_NUM_UNS
    CALL PRINT_TAB
    
    ; HR
    MOV AL, HEART_RATE[BX]
    MOV AH, 0
    CALL PRINT_NUM_UNS
    CALL PRINT_TAB
    
    ; Temp
    MOV DI, I
    SHL DI, 1
    MOV AX, TEMPERATURE[DI]
    CALL PRINT_TEMP
    CALL PRINT_TAB
    
    ; BP
    MOV AL, BLOOD_PRESSURE[BX]
    MOV AH, 0
    CALL PRINT_NUM_UNS
    CALL PRINT_TAB
    
    ; Status
    MOV SI, I
    CALL CHECK_RISK
    CMP AL, 1
    JE  DISP_RISK
    
    LEA SI, MSG_STATUS_OK
    MOV BL, 1Ah ; Green on Blue
    CALL PRINT_STRING_COLOR
    JMP DISP_ROW_END
    
DISP_RISK:
    LEA SI, MSG_STATUS_HR
    MOV BL, 1Ch ; Red on Blue
    CALL PRINT_STRING_COLOR
    
DISP_ROW_END:
    PUTC 0Dh
    PUTC 0Ah
    
DISP_NEXT_ROW:
    INC I
    JMP DISP_ROW_LOOP
    
DISP_COMPLETE:
    CMP FILTER_MODE, 1
    JNE DISP_WAIT
    CMP CX, 0
    JNE DISP_WAIT
    
    LEA SI, MSG_NO_RISK
    CALL PRINT_STRING
    PUTC 0Dh
    PUTC 0Ah
    
DISP_WAIT:
    LEA SI, MSG_PRESS_KEY
    CALL PRINT_STRING
    MOV AH, 00h
    INT 16h
    RET
DISPLAY_TABLE ENDP

; ---------------------------------------------------------
; Sorting Subroutines (Bubble Sort Descending)
; ---------------------------------------------------------

SORT_BY_HR PROC NEAR
    CMP N, 1
    JLE SORT_HR_DONE
    
    MOV CX, N
    DEC CX           ; Outer loop limit = N - 1
    
OUTER_HR:
    PUSH CX
    MOV SI, 0        ; Inner loop index
    
INNER_HR:
    MOV AL, HEART_RATE[SI]
    CMP AL, HEART_RATE[SI+1]
    JAE SKIP_SWAP_HR ; If greater or equal, no swap
    
    ; Swap ID
    MOV AL, PATIENT_ID[SI]
    XCHG AL, PATIENT_ID[SI+1]
    MOV PATIENT_ID[SI], AL
    
    ; Swap HR
    MOV AL, HEART_RATE[SI]
    XCHG AL, HEART_RATE[SI+1]
    MOV HEART_RATE[SI], AL
    
    ; Swap BP
    MOV AL, BLOOD_PRESSURE[SI]
    XCHG AL, BLOOD_PRESSURE[SI+1]
    MOV BLOOD_PRESSURE[SI], AL
    
    ; Swap Temp (DW)
    MOV DI, SI
    SHL DI, 1
    MOV AX, TEMPERATURE[DI]
    XCHG AX, TEMPERATURE[DI+2]
    MOV TEMPERATURE[DI], AX
    
SKIP_SWAP_HR:
    INC SI
    CMP SI, CX
    JL  INNER_HR
    
    POP CX
    LOOP OUTER_HR
    
SORT_HR_DONE:
    RET
SORT_BY_HR ENDP

SORT_BY_TEMP PROC NEAR
    CMP N, 1
    JLE SORT_TMP_DONE
    
    MOV CX, N
    DEC CX
    
OUTER_TMP:
    PUSH CX
    MOV SI, 0
    
INNER_TMP:
    ; We check temp which is at SI * 2
    MOV DI, SI
    SHL DI, 1
    MOV AX, TEMPERATURE[DI]
    CMP AX, TEMPERATURE[DI+2]
    JAE SKIP_SWAP_TMP
    
    ; Swap ID
    MOV AL, PATIENT_ID[SI]
    XCHG AL, PATIENT_ID[SI+1]
    MOV PATIENT_ID[SI], AL
    
    ; Swap HR
    MOV AL, HEART_RATE[SI]
    XCHG AL, HEART_RATE[SI+1]
    MOV HEART_RATE[SI], AL
    
    ; Swap BP
    MOV AL, BLOOD_PRESSURE[SI]
    XCHG AL, BLOOD_PRESSURE[SI+1]
    MOV BLOOD_PRESSURE[SI], AL
    
    ; Swap Temp (DW)
    ; DI is already SI * 2
    MOV AX, TEMPERATURE[DI]
    XCHG AX, TEMPERATURE[DI+2]
    MOV TEMPERATURE[DI], AX
    
SKIP_SWAP_TMP:
    INC SI
    CMP SI, CX
    JL  INNER_TMP
    
    POP CX
    LOOP OUTER_TMP
    
SORT_TMP_DONE:
    RET
SORT_BY_TEMP ENDP

SORT_BY_BP PROC NEAR
    CMP N, 1
    JLE SORT_BP_DONE
    
    MOV CX, N
    DEC CX
    
OUTER_BP:
    PUSH CX
    MOV SI, 0
    
INNER_BP:
    MOV AL, BLOOD_PRESSURE[SI]
    CMP AL, BLOOD_PRESSURE[SI+1]
    JAE SKIP_SWAP_BP
    
    ; Swap ID
    MOV AL, PATIENT_ID[SI]
    XCHG AL, PATIENT_ID[SI+1]
    MOV PATIENT_ID[SI], AL
    
    ; Swap HR
    MOV AL, HEART_RATE[SI]
    XCHG AL, HEART_RATE[SI+1]
    MOV HEART_RATE[SI], AL
    
    ; Swap BP
    MOV AL, BLOOD_PRESSURE[SI]
    XCHG AL, BLOOD_PRESSURE[SI+1]
    MOV BLOOD_PRESSURE[SI], AL
    
    ; Swap Temp (DW)
    MOV DI, SI
    SHL DI, 1
    MOV AX, TEMPERATURE[DI]
    XCHG AX, TEMPERATURE[DI+2]
    MOV TEMPERATURE[DI], AX
    
SKIP_SWAP_BP:
    INC SI
    CMP SI, CX
    JL  INNER_BP
    
    POP CX
    LOOP OUTER_BP
    
SORT_BP_DONE:
    RET
SORT_BY_BP ENDP

; ---------------------------------------------------------
; Custom Input/Output Procedures (Universal 8086 Assembly)
; ---------------------------------------------------------

PRINT_STRING PROC NEAR
    PUSH AX
    PUSH SI
    CLD
PRINT_STR_LOOP:
    LODSB
    CMP AL, 0
    JE  PRINT_STR_DONE
    CMP AL, 09h
    JE  PRINT_STR_TAB
    MOV AH, 0Eh
    INT 10h
    JMP PRINT_STR_LOOP
PRINT_STR_TAB:
    CALL PRINT_TAB
    JMP PRINT_STR_LOOP
PRINT_STR_DONE:
    POP SI
    POP AX
    RET
PRINT_STRING ENDP

PRINT_TAB PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    MOV AH, 03h
    MOV BH, 0
    INT 10h             ; DL = column, DH = row
    
    MOV AL, DL
    AND AL, 7           ; AL = DL % 8
    MOV CL, 8
    SUB CL, AL          ; CL = 8 - (DL % 8)
    MOV CH, 0
    
PRINT_TAB_LOOP:
    PUTC ' '
    LOOP PRINT_TAB_LOOP
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PRINT_TAB ENDP

PRINT_NUM_UNS PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    MOV CX, 0
    MOV BX, 10
    
DIV_LOOP:
    MOV DX, 0
    DIV BX
    PUSH DX
    INC CX
    CMP AX, 0
    JNE DIV_LOOP
    
PRINT_LOOP:
    POP AX
    ADD AL, '0'
    MOV AH, 0Eh
    INT 10h
    LOOP PRINT_LOOP
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PRINT_NUM_UNS ENDP

SCAN_NUM PROC NEAR
    PUSH AX
    PUSH BX
    PUSH DX
    
    MOV CX, 0       ; Accumulate number in CX
    
READ_CHAR:
    MOV AH, 00h
    INT 16h         ; AL = ASCII code of key
    
    ; Check if Enter (ASCII 13 / 0Dh)
    CMP AL, 0Dh
    JE  SCAN_DONE
    
    ; Check if Backspace (ASCII 8 / 08h)
    CMP AL, 08h
    JE  HANDLE_BACKSPACE
    
    ; Check if digit ('0' - '9')
    CMP AL, '0'
    JB  READ_CHAR
    CMP AL, '9'
    JA  READ_CHAR
    
    ; Echo digit
    MOV AH, 0Eh
    INT 10h
    
    ; Accumulate digit: CX = CX * 10 + (AL - '0')
    SUB AL, '0'
    MOV AH, 0
    PUSH AX
    
    MOV AX, CX
    MOV BX, 10
    MUL BX
    MOV CX, AX
    
    POP AX
    ADD CX, AX
    JMP READ_CHAR
    
HANDLE_BACKSPACE:
    CMP CX, 0
    JE  READ_CHAR
    
    ; Visual Backspace
    MOV AH, 0Eh
    MOV AL, 08h
    INT 10h
    MOV AL, ' '
    INT 10h
    MOV AL, 08h
    INT 10h
    
    ; CX = CX / 10
    MOV AX, CX
    MOV DX, 0
    MOV BX, 10
    DIV BX
    MOV CX, AX
    JMP READ_CHAR
    
SCAN_DONE:
    POP DX
    POP BX
    POP AX
    RET
SCAN_NUM ENDP

END START