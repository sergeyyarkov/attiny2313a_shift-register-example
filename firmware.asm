;
; Project name: shift-register-example
; Description: An example of using the single 74HC595 shift register with an AVR microcontroller
; Source code: https://github.com/sergeyyarkov/attiny2313a_shift-register-example
; Device: ATtiny2313A
; Device Datasheet: http://ww1.microchip.com/downloads/en/DeviceDoc/doc8246.pdf
; Package: SOIC-20W_7.5x12.8mm_P1.27mm
; Assembler: AVR macro assembler 2.2.7
; Clock frequency: 12 MHz External Crystal Oscillator
; Fuses: lfuse: 0x4F, hfuse: 0x9F, efuse: 0xFF, lock: 0xFF
;
; Written by Sergey Yarkov 22.01.2023

.INCLUDE "tn2313Adef.inc"
.LIST

.DEF COUNTER = r20

;========================================;
;                LABELS                  ;
;========================================;

.EQU CLOCK_PIN        = PB0   ; ST_CP on 74HC595
.EQU DATA_PIN         = PB1   ; DS on 74HC595
.EQU LATCH_PIN        = PB2   ; SH_CP on 74HC595

;========================================;
;              CODE SEGMENT              ;
;========================================;

.CSEG
.ORG 0x00

;========================================;
;                VECTORS                 ;
;========================================;

rjmp 	RESET_vect			      ; Program start at RESET vector
;reti                        ; External Interrupt Request 0 / inactive
;reti		                    ; External Interrupt Request 1 / inactive
;reti                        ; Timer/Counter1 Capture Event / inactive
;reti		                    ; Timer/Counter1 Compare Match A / inactive
;reti                        ; Timer/Counter1 Overflow / inactive
;reti                        ; Timer/Counter0 Overflow / inactive
;reti                        ; USART0, Rx Complete / inactive
;reti                        ; USART0 Data Register Empty / inactive
;reti						            ; USART0, Tx Complete / inactive
;reti                        ; Analog Comparator / inactive
;reti	                      ; Pin Change Interrupt Request 0/ inactive
;reti                        ; Timer/Counter1 Compare Match B / inactive
;reti                        ; Timer/Counter0 Compare Match A / inactive
;reti                        ; Timer/Counter0 Compare Match B / inactive
;reti                        ; USI Start Condition/ inactive
;reti                        ; USI Overflow / inactive
;reti                        ; EEPROM Ready/ inactive
;reti                        ; Watchdog Timer Overflow / inactive
;reti                        ; Pin Change Interrupt Request 1 / inactive
;reti                        ; Pin Change Interrupt Request 2 / inactive

RESET_vect:
  ;========================================;
  ;        INITIALIZE STACK POINTER        ;
  ;========================================;
  ldi       r16, low(RAMEND)
  out       SPL, r16

MCU_INIT:
  rcall     INIT_PORTS

  ldi       COUNTER, 0
  rjmp      LOOP

INIT_PORTS:
  ldi       r16, (1<<CLOCK_PIN) | (1<<LATCH_PIN) | (1<<DATA_PIN)
  out       DDRB, r16
ret

;========================================;
;          SEND BYTE TO 74HC595          ;
;========================================;
TRANSMIT_595:
  push      r19
  mov       r19, COUNTER
  ldi       r16, 8
  _TRANSMIT_595_LOOP:
    lsl     r19
    brcc    _TRANSMIT_595_SEND_LOW
    brcs    _TRANSMIT_595_SEND_HIGH
    
    _TRANSMIT_595_SEND_HIGH:
      sbi     PORTB, DATA_PIN
      rjmp    _TRANSMIT_595_COMMIT

    _TRANSMIT_595_SEND_LOW:
      cbi     PORTB, DATA_PIN

    _TRANSMIT_595_COMMIT:
      sbi      PORTB, CLOCK_PIN
      cbi      PORTB, CLOCK_PIN
      sbi      PORTB, LATCH_PIN
      cbi      PORTB, LATCH_PIN 
    dec      r16
    brne     _TRANSMIT_595_LOOP
  pop        r19
ret

;========================================;
;            MAIN PROGRAM LOOP           ;
;========================================;

LOOP:
  rcall     TRANSMIT_595
  inc       COUNTER
  rcall     DELAY
  rjmp      LOOP

DELAY:
  push      r16
  push      r17
  cli
  ldi       r16, 20
  _DELAY_1:
    ldi     r17, 255   
  _DELAY_2:
    dec     r17         
    nop                 
    nop                
    nop                 
    brne    _DELAY_2    

    dec     r16
    brne    _DELAY_1    
  sei

  pop       r17
  pop       r16
ret                    