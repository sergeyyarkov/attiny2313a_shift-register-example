;
; Project name: shift-register-example
; Description: An example of using the single 74HC595 shift register with an AVR microcontroller
; Source code: https://github.com/sergeyyarkov/attiny2313a_shift-register-example
; Device: ATtiny2313A
; Device Datasheet: http://ww1.microchip.com/downloads/en/DeviceDoc/doc8246.pdf
; Package: SOIC-20W_7.5x12.8mm_P1.27mm
; Assembler: AVR macro assembler 2.2.7
; Clock frequency: 8 MHz Internal with CKDIV8
; Fuses: lfuse: 0x64, hfuse: 0x9F, efuse: 0xFF, lock: 0xFF
;
; Written by Sergey Yarkov 28.01.2023

.INCLUDE "tn2313Adef.inc"
.LIST

.DEF TEMP_A           = r16               ; Temp register A
.DEF TEMP_B           = r17               ; Temp register B
.DEF DATA             = r20               ; DATA to transmit

;========================================;
;                LABELS                  ;
;========================================;

.EQU CLOCK_PIN        = PB0   ; SH_CP on 74HC595
.EQU DATA_PIN         = PB1   ; DS on 74HC595
.EQU LATCH_PIN        = PB2   ; ST_CP on 74HC595

;========================================;
;              CODE SEGMENT              ;
;========================================;

.CSEG
.ORG 0x00

;========================================;
;                VECTORS                 ;
;========================================;

rjmp 	RESET_vect			      ; Program start at RESET vector

RESET_vect:
  ;========================================;
  ;        INITIALIZE STACK POINTER        ;
  ;========================================;

  ldi       TEMP_A, low(RAMEND)
  out       SPL, TEMP_A

MCU_INIT:
  rcall     INIT_PORTS
  ldi       DATA, 0b00000001
  rjmp      LOOP

;========================================;
;            MAIN PROGRAM LOOP           ;
;========================================;

LOOP:
  rcall     TRANSMIT_595
  rol       DATA
  rcall     DELAY
  rjmp      LOOP

INIT_PORTS:
  ldi       TEMP_A, (1<<CLOCK_PIN) | (1<<LATCH_PIN) | (1<<DATA_PIN)
  out       DDRB, TEMP_A
ret

;========================================;
;          SEND BYTE TO 74HC595          ;
;========================================;

TRANSMIT_595:
  in        r21, SREG
  mov       r19, DATA
  ldi       TEMP_B, 8
  _TRANSMIT_595_LOOP:
    ;
    ; Shift a bit into the Carry flag and check if it is set to 1 or 0.
    lsl     r19
    brcc    _TRANSMIT_595_SEND_LOW
    brcs    _TRANSMIT_595_SEND_HIGH
    
    _TRANSMIT_595_SEND_HIGH:
      sbi     PORTB, DATA_PIN
      rjmp    _TRANSMIT_595_COMMIT

    _TRANSMIT_595_SEND_LOW:
      cbi     PORTB, DATA_PIN

    _TRANSMIT_595_COMMIT:
      cbi      PORTB, CLOCK_PIN
      sbi      PORTB, CLOCK_PIN
    dec      TEMP_B
    brne     _TRANSMIT_595_LOOP
    
    ;
    ; Copy data from shift register to storage register
    sbi      PORTB, LATCH_PIN
    cbi      PORTB, LATCH_PIN 
  out        SREG, r21
ret

DELAY:
  push      TEMP_A
  ldi       TEMP_A, 70
  _DELAY_1:
    ldi     TEMP_B, 255   
  _DELAY_2:
    dec     TEMP_B         
    nop                 
    nop                
    nop                 
    brne    _DELAY_2    
    dec     TEMP_A
    brne    _DELAY_1
  pop       TEMP_A    
ret                    