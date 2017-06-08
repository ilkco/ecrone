;**********************************************************************;
;eCRONE the following file contain source code for a digital timekeeper*
;**********************************************************************


	list		p=16f877A	; list directive to define processor
	#include	<p16f877A.inc>	; processor specific variable definitions
	
	__CONFIG _CP_OFF & _WDT_OFF & _BODEN_OFF & _PWRTE_ON & _XT_OSC & _WRT_OFF & _LVP_OFF & _CPD_OFF
	radix dec
	
	udata 0X20
	
A11 res 1
A12 res 1
A13 res 1
A14 res 1
A15 res 1
A16	res 1
A17 res 1
A18 res 1
A19 res 1
A110 res 1
A111 res 1
A112 res 1
A113 res 1
A114 res 1
A115 res 1
A116 res 1

A21 res 1
A22 res 1
A23 res 1
A24 res 1
A25 res 1
A26	res 1
A27 res 1
A28 res 1
A29 res 1
A210 res 1
A211 res 1
A212 res 1
A213 res 1
A214 res 1
A215 res 1
A216 res 1

ms  res 1
sec  res 1
min  res 1
day  res 1
hr  res 1
ampm  res 1

temp_hr  res 1
temp_min  res 1
temp_ampm  res 1
temp_day  res 1
temp_period  res 1
set_per  res 1

asciiH res 1
asciiL res 1
val_conv res 1




	;***********************VARIABLE DEFINITIONS********************************************
	
	
	
p1 res 1
p2 res 1
p3 res 1 
p4 res 1
p5 res 1
p6 res 1
p7 res 1 
p8 res 1
p9 res 1
p10 res 1
p11 res 1
p12 res 1
p13 res 1
p14 res 1
p15 res 1 
p16 res 1 
p17 res 1
p18 res 1

d1 res 1 
d2 res 1
d3	res 1 

daystartsH res 1
daystartsM res 1
daystartsAMPM res 1

current_period res 1
current_period_add res 1
current_period_off res 1
TT_active res 1
ds_saved? res 1


	global A11,A12,A13,A14,A15,A16,A17,A18,A19,A110,A111,A112,A113,A114,A115,A116
	global A21,A22,A23,A24,A25,A26,A27,A28,A29,A210,A211,A212,A213,A214,A215,A216
	global ?_delay
	global min,hr,day,ampm
	global temp_min,temp_hr,temp_day,temp_period,set_per,temp_ampm
	global	asciiH,asciiL,val_conv 
	global d1
	
	
	extern init_lcd
	extern splash_screen
	extern load_cmd
	extern load_char
    extern idle_screen
	extern set_time_refresh
	extern set_day_refresh		
	extern set_TT_selectday_refresh	
	extern set_TT_day_starts_refresh
	extern set_TT_set_periods_refresh

RST CODE  0x000   ; Strictly in location 0X0

	nop			  ; nop required for icd
  	goto    main              ; go to beginning of program


INT CODE    0x004             ; interrupt vector location

	movwf   temp_w           ; save off current W register contents
	movf	STATUS,w          ; move status register into W register
	movwf	temp_status       ; save off contents of STATUS register
	movf	FSR,w	  ; move FSR register into w register
	movwf	temp_FSR	  ; save off contents of FSR register
	clrf STATUS
	
	incf ms,f ; incremeting the millisec
	movlw 100
	subwf ms,w
	btfss zflag; check for overflow
	goto config_tmr0; 1 minute hasnot passed leave isr
	clrf ms
	
	;ONE SECOND HAS ELAPSED
	
	incf sec,f
	
	; code for the ringer
	
	movf ring_length,f
	btfsc zflag
	goto $+4
	decfsz ring_length,f
	goto $+2
	bcf BELL
	
	movlw 60 ;0-59 seconds
	subwf sec,w
	btfss zflag
	goto config_tmr0
	clrf sec
	;*********ONE MINUTE HAS ELAPSED************************
	
	incf min,f
	
	movf stay?,f
	btfss zflag; if stay is zero donot decrement it anymore
	decf stay?,f
	

					
TT_on?; Is the timetable ON
			
	movlw 255; IF (TT_active = 0XFF)
	subwf TT_active,w
	btfss zflag
	goto continue_min
			decfsz current_period,f; should never be zero
			goto continue_min
			call load_next_period
			
			movlw 10; RING FOR 10 SECONDS
			movwf ring_length
			bsf BELL
			
			movlw 255; IF current_period = 255 deactivate the timetable
			subwf current_period,w	
			btfss zflag
			goto continue_min
			clrf TT_active; deactivate timetable till another day
			movlw 20
			movwf ring_length
			bsf BELL
				
	

	
	
	

continue_min	
	movlw 255
	movwf timechange?
		
	movlw 60
	subwf min,w
	btfss zflag
	goto config_tmr0
			
	clrf min
	
	;**********ONE HOUR HAS ELAPSED**************
	incf hr,f
	
	movlw 12
	subwf hr,w
	btfss zflag
	goto $+2
	comf ampm,f; complement. 255 = pm
	
	movlw 13
	subwf hr,w
	btfss zflag
	goto $+3
	movlw d'1'; 13 hrs = 1 hr
	movwf hr
	
		;NEW DAY ? new day = 12:00 am
	
	movlw 12;
	subwf hr,w
	btfss zflag
	goto config_tmr0
	
	movlw d'0'
	subwf ampm,w
	btfss zflag
	goto config_tmr0
	
	; if we just went past PM 1 day has elapsed
	incf day,f
	incf sec,f; correct by 1 second daily
	call load_new_periods
	
	movlw d'8'
	subwf day,w
	btfss zflag
	goto config_tmr0
	movlw d'1'
	movwf day
	
load_next_period ; only gets here after timetable has been activated TT _active = 255
	movlw 17
	subwf current_period_off,w
	btfsc zflag
	goto $+8
	incf current_period_off,f; the first offset is zero
	movfw current_period_off
	addwf current_period_add,f
	movfw current_period_add

	movwf FSR
	movfw INDF
	
	movwf current_period
	return	
	
	
	

config_tmr0; configure tmr0 for the next interrupt; AND ACTIVATE TIME TABLE AS SEEN FIT

	movf TT_active,f; IF (TT_active = 0) then
	btfss zflag
	goto load_tmr0
			
			movfw daystartsM; if(dsMin = min); (dsHr = hr) ;(dsAmPm = ampm)
			subwf min,w
			btfss zflag
			goto load_tmr0; test failed!
			
			movfw daystartsH				;ONLY THESE CONDITIONS CAN START THE TIMETABLE IT WILL NOT START IF THE DAY IS DEACTIVATED (daystarts = 255)
			subwf hr,w
			btfss zflag
			goto load_tmr0; test failed!
			
			movfw daystartsAMPM
			subwf ampm,w
			btfss zflag
			goto load_tmr0; test failed!
	
					movlw 255
					movwf TT_active ; the timetable of the day has started
					
					bsf BELL; ring the bell
					movlw 20; 20 seconds
					movwf ring_length
					
					movlw p1
					movwf current_period_add
					
					movfw current_period_add
					movwf FSR
					movfw INDF
					movwf current_period
					clrf current_period_off; Clear the offset


load_tmr0
	movlw 100
	movwf TMR0
	bcf INTCON,TMR0IF; clear interrupt flag for next interrupt
	
	
	movf	temp_FSR,w	  ; retrieve copy of FSR register
	movwf	FSR		  ; restore pre-isr FSR register contents
	movf    temp_status,w     ; retrieve copy of STATUS register
	movwf	STATUS            ; restore pre-isr STATUS register contents
	swapf   temp_w,f
	swapf   temp_w,w          ; restore pre-isr W register contents
	retfie                    ; return from interrupt


MAIN_PGM CODE; rellocateable code 

main


		
	; the time is 11:59:00 Monday
	clrf sec
	clrf ms
	
	movlw d'11'
	movwf hr
	
	movlw d'59'
	movwf min
	
	movlw d'255'
	movwf ampm
	
	movlw d'1'
	movwf day
	
	clrf TT_active
	
	movlw b'11111000'; buttons start from RB7
	banksel TRISB; buttons
	movwf TRISB
	clrf TRISC; lcd data
	clrf TRISD; lcd control
	movlw b'00010101'
	movwf OPTION_REG; Enable PORTB pull up
	clrf STATUS; back to bank 0	
	
	call init_lcd
	call splash_screen
	
	bsf BELL
	call _1sec
	bcf BELL
	call _1sec
	bsf BELL
	call _1sec
	bcf BELL

	movlw 100
	movwf TMR0
	clrf INTCON
	bsf INTCON,GIE
	bsf INTCON,TMR0IE; enable timer 0 interrupts
	call load_new_periods; load periods for a monday
	
main_loop_refresh
	
	call idle_screen



main_loop

	movlw d'255'
	subwf timechange?,w
	btfss zflag
	goto $+3
	clrf timechange?; so that the LCD can refresh again
	call idle_screen
		
	btfss ENTER_but
	goto $+2
	goto main_loop
	
	call _deb
	btfsc ENTER_but
	goto main_loop
	
	call _1sec
	btfsc ENTER_but
	goto set_time
	btfsc ENTER_but
	goto set_time
	call _1sec
	btfsc ENTER_but
	goto set_time
	call _1sec
	btfsc ENTER_but
	goto set_time
	goto set_TT; when the button has been held down for some time, timetable is set not time
	
	
	
set_time
	movfw hr
	movwf temp_hr
	
	movfw min 
	movwf temp_min	

	movfw ampm
	movwf temp_ampm	

	movfw day
	movwf temp_day
	
	movlw 2
	movwf stay?
	
	movlw set_hr
	movwf state

set_time_loop_refresh
	
	call set_time_refresh 
	movlw 100
	call ?_delay
set_time_loop
	
	
	movf stay?,f
	btfsc zflag ; if z flag is set waiting time has elapsed
	goto main_loop_refresh; refresh lcd and enter the  main loop
	
	btfss UP_but
	goto up_action_set_time
	btfss DOWN_but
	goto down_action_set_time
	btfss LEFT_but
	goto left_action_set_time
	btfss RIGHT_but
	goto right_action_set_time
	;btfss SET_but
	;goto set_action_set_time
	goto set_time_loop
	
up_action_set_time
	call _deb; debounce the button
	btfsc UP_but
	goto set_time_loop_refresh
	
	movlw 2
	movwf stay?
	
	movlw set_hr
	subwf state,w
	btfss zflag
	goto inc_min ; it is minute we are setting
	
	incf temp_hr,f
	movlw d'13'; if time is 60, make temp_hr 0
	subwf temp_hr,w
	btfss zflag
	goto set_time_loop_refresh
	movlw 1
	movwf temp_hr
	goto set_time_loop_refresh
inc_min	
	movlw set_min
	subwf state,w
	btfss zflag
	goto inc_ampm
	
	incf temp_min,f
	movlw d'60'
	subwf temp_min,w
	btfss zflag
	goto set_time_loop_refresh
	movlw d'1'
	movwf temp_min
	goto set_time_loop_refresh
inc_ampm
	movlw set_ampm
	subwf state,w
	btfss zflag; we are setting the ampm
	goto set_time_loop_refresh
	
	comf temp_ampm,f
	goto set_time_loop_refresh
	
down_action_set_time
		call _deb; debounce the button
	btfsc DOWN_but
	goto set_time_loop
	
	movlw 2
	movwf stay?
	
	movlw set_hr
	subwf state,w
	btfss zflag
	goto dec_min ; it is minute we are setting
	
	decf temp_hr,f
	movlw 0; if time 0 then we make time 1hr 
	subwf temp_hr,w
	btfss zflag
	goto set_time_loop_refresh
	movlw 12
	movwf temp_hr
	goto set_time_loop_refresh
dec_min	
	movlw set_min
	subwf state,w
	btfss zflag
	goto dec_ampm
	
	decf temp_min,f
	movlw 2-3
	subwf temp_min,w
	btfss zflag
	goto set_time_loop_refresh
	movlw d'59'
	movwf temp_min
	goto set_time_loop_refresh
dec_ampm
	movlw set_ampm
	subwf state,w
	btfss zflag; we are setting the ampm
	goto set_time_loop
	
	comf temp_ampm,f
	goto set_time_loop_refresh



left_action_set_time
	call _deb
	btfsc LEFT_but
	goto main_loop

	movlw 2
	movwf stay?
	
	movlw set_hr
	subwf state,w
	btfss zflag
	goto $+2
	goto main_loop_refresh; the idle screen
	
	decf state,f; 
	goto set_time_loop_refresh; refresh and loop
	
	
right_action_set_time
	call _deb
	btfsc RIGHT_but
	goto main_loop
	
	movlw 2
	movwf stay?
	
	
	movlw set_hr; set hr
	subwf state,w
	btfss zflag
	goto $+4
	movlw set_min
	movwf state
	goto set_time_loop_refresh
	
	movlw set_min; ; set min
	subwf state,w
	btfss zflag
	goto $+4
	movlw set_ampm
	movwf state
	goto set_time_loop_refresh
		
	
	movlw set_ampm; set ampm
	subwf state,w
	btfss zflag
	goto $+3
	movlw set_day; the state is now set dsy
	movwf state
	
	
	
	
day_set	
	call _deb
	
	movlw 2
	movwf stay?

set_day_loop_refresh; refresh then loop

	call set_day_refresh
	movlw 100; delay so that screen does not blur due to very fast refreshes
	call ?_delay
set_day_loop
	
	movf stay?,f
	btfsc zflag
	goto main_loop_refresh; idle screen
	
	btfss UP_but
	goto up_action_set_day
	btfss DOWN_but
	goto down_action_set_day
	btfss RIGHT_but
	goto right_action_set_day
	btfss LEFT_but	
	goto left_action_set_day
	
	
	goto set_day_loop


up_action_set_day
	call _deb
	btfsc UP_but
	goto set_day_loop

	incf temp_day,f
	movlw 8
	subwf temp_day,w
	btfss zflag
	goto $+3
	movlw 1
	movwf temp_day
	goto set_day_loop_refresh
	
down_action_set_day
	call _deb
	btfsc DOWN_but
	goto set_day_loop

	decf temp_day,f
	movf temp_day,f; when temp day = 0
	btfss zflag
	goto $+3
	movlw 7
	movwf temp_day
	goto set_day_loop_refresh
	
right_action_set_day
	call _deb
	btfsc RIGHT_but
	goto set_day_loop

	movfw temp_hr
	movwf hr
	
	movfw temp_min
	movwf min
	
	movfw temp_ampm
	movwf ampm
	
	movfw temp_day
	movwf day
	
	call load_new_periods; load new periods for the current day that has just been set
	clrf TT_active; deactivate timetable and star checking again
	goto main_loop_refresh
	
left_action_set_day
	call _deb
	btfsc LEFT_but
	goto set_day_loop
	goto set_time; go back and set the time
	
	
set_TT
	movlw set_TT_selectday
	movwf state

	movlw 2 
	movwf stay?
	
	movlw 1
	movwf temp_day; starting with monday

set_TT_selectday_loop_refresh	
	call set_TT_selectday_refresh
	movlw 100; delay so that screen does not blur due to very fast refreshes
	call ?_delay
set_TT_selectday_loop		
	
	movf stay?,f
	btfsc zflag
	goto main_loop_refresh	
		
	btfss UP_but
	goto up_action_selectday
	btfss DOWN_but
	goto down_action_selectday
	btfss RIGHT_but
	goto right_action_selectday
	btfss LEFT_but
	goto left_action_selectday
	goto set_TT_selectday_loop	

up_action_selectday
	call _deb
	btfsc UP_but
	goto set_TT_selectday_loop
	;SELECT DAY
	incf temp_day,f
	movlw 6
	subwf temp_day,w
	btfss zflag
	goto $+3
	movlw 1
	movwf temp_day; there are no weekend days
	goto set_TT_selectday_loop_refresh

down_action_selectday
	call _deb
	btfsc DOWN_but
	goto set_TT_selectday_loop
	;SELECT DAY
	decf temp_day,f
	movlw 0
	subwf temp_day,w
	btfss zflag
	goto $+3
	movlw 5
	movwf temp_day; there are no weekend days
	goto set_TT_selectday_loop_refresh
right_action_selectday
		call _deb
		btfsc RIGHT_but
		goto set_TT_selectday_loop
		
		goto set_TT_day_starts
		
left_action_selectday
		call _deb
		btfsc LEFT_but
		goto set_TT_selectday_loop
		
		goto main_loop_refresh; go back


		
		
		
set_TT_day_starts

	movlw set_TT_daystartsH
	movwf state
	
	movlw 2
	movwf stay?
	
	call load_day_starts; reads out data from eeprom 
	
set_TT_day_starts_loop_refresh
	call set_TT_day_starts_refresh
	
set_TT_day_starts_loop
	movf stay?,f
	btfsc zflag
	goto main_loop_refresh

	btfss UP_but
	goto up_action_daystarts
	btfss DOWN_but
	goto down_action_daystarts
	btfss RIGHT_but
	goto right_action_daystarts
	btfss LEFT_but
	goto left_action_daystarts
	btfss SET_but
	goto set_action_daystarts
	goto set_TT_day_starts_loop	


up_action_daystarts
	call _deb
	btfsc UP_but
	goto set_TT_day_starts_loop

	movlw set_TT_daystartsH
	subwf state,w
	btfss zflag
	goto inc_ds_min
			;inc hr
			movlw 255; if there is nothing on that day and you press up the time is made 7 am
			subwf temp_hr,w
			btfss zflag
			goto $+6
			movlw 7
			movwf temp_hr
			clrf temp_min
			movlw temp_ampm
			goto set_TT_day_starts_loop_refresh
			
			incf temp_hr,f
			movlw d'24'		;		24 hrs = 0 hrs
			subwf temp_hr,w
			btfss zflag
			goto set_TT_day_starts_loop_refresh
			clrf temp_hr								; 0 TO 23 hrs
			goto set_TT_day_starts_loop_refresh

inc_ds_min				
		movlw 255
		subwf temp_min,w
		btfss zflag 
		goto $+5
		movlw 7
		movwf temp_hr
		clrf temp_min
		goto set_TT_day_starts_loop_refresh
		

	incf temp_min,f
	movlw 60
	subwf temp_min,w
	btfss zflag
	goto set_TT_day_starts_loop_refresh
	clrf temp_min
	goto set_TT_day_starts_loop_refresh
	


down_action_daystarts
	call _deb
	btfsc DOWN_but
	goto set_TT_day_starts_loop

	movlw set_TT_daystartsH
	subwf state,w
	btfss zflag
	goto dec_ds_min
	
		movlw 255
		subwf temp_hr,w
		btfss zflag
		goto $+5
		movlw 7; time is now 7 am since there was nothing before
		movwf temp_hr
		clrf temp_min
		goto set_TT_day_starts_loop_refresh
			;inc hr
			decf temp_hr,f
			movlw 2-3
			subwf temp_hr,w
			btfss zflag
			goto set_TT_day_starts_loop_refresh
			movlw 23
			movwf temp_hr
			goto set_TT_day_starts_loop_refresh


dec_ds_min	
		movlw 255;
		subwf temp_min,w
		btfss zflag
		goto $+5
		movlw 7
		movwf temp_hr
		clrf temp_min
		goto set_TT_day_starts_loop_refresh
		
	decf temp_min,f
	movlw 2-3
	subwf temp_min,w
	btfss zflag
	goto set_TT_day_starts_loop_refresh
	movlw 59
	movwf temp_min
	goto set_TT_day_starts_loop_refresh
	
right_action_daystarts
	call _deb
	btfsc RIGHT_but
	goto set_TT_day_starts_loop
	
	movlw set_TT_daystartsH
	subwf state,w
	btfss zflag
	goto $+4
	
	movlw set_TT_daystartsM
	movwf state
	goto set_TT_day_starts_loop_refresh
	
	movlw set_TT_daystartsM
	subwf state,w
	btfss zflag
	goto set_TT_day_starts_loop_refresh
	goto set_periods

left_action_daystarts
	call _deb
	btfsc LEFT_but
	goto set_TT_day_starts_loop

	movlw set_TT_daystartsM
	subwf state,w
	btfss zflag
	goto $+4
	movlw set_TT_daystartsH
	movwf state
	goto set_TT_day_starts_loop_refresh
	
	movlw set_TT_daystartsH
	subwf state,w
	btfss zflag
	goto set_TT_day_starts_loop_refresh
	goto set_TT
	
set_action_daystarts; REMEMBER TEMP HR AND MIN ARE SAVED AT THE END OF TT SETTING WHEN PERIODS TOO HAVE BEEN SET
	call _deb
	btfsc SET_but
	goto set_TT_day_starts_loop
	
	movlw 255; nothing for today________________
	movwf temp_hr
	
	movlw 255
	movwf temp_min
	
	goto set_TT_day_starts_loop_refresh; show - - meaning nothing!

set_periods	
	clrf ds_saved?
	movlw set_TT_setperiod
	movwf state
	
	movlw 2
	movwf stay?
	
	movlw 1
	movwf set_per; starting always with the first pereiod
	
	call load_periods; LOAD PERIODS AD THEY ARE NEEDED
	
set_periods_loop_refresh	
	call set_TT_set_periods_refresh
	movlw 100; delay so that screen does not blur due to very fast refreshes
	call ?_delay
	
set_periods_loop
	movf stay?,f
	btfsc zflag
	goto main_loop_refresh

	btfss UP_but
	goto up_action_set_period
	btfss DOWN_but
	goto down_action_set_period
	btfss RIGHT_but
	goto right_action_set_period
	btfss LEFT_but
	goto left_action_set_period
	btfss ENTER_but
	goto enter_action_set_period
	
	goto set_periods_loop
	
up_action_set_period
	call _deb
	btfsc UP_but
	goto set_periods_loop
	
	movlw 255
	subwf temp_period,w
	btfss zflag
	goto $+4
	movlw 5
	movwf temp_period
	goto set_periods_loop_refresh
	
	
	movlw 5 
	addwf temp_period,f; increase periods by 5 until periods = 185
	
	movlw d'185'
	subwf temp_period,w
	btfss zflag
	goto set_periods_loop_refresh
	movlw 5
	movwf temp_period
	goto set_periods_loop_refresh



down_action_set_period
	call _deb
	btfsc DOWN_but
	goto set_periods_loop
	
	movlw 255
	subwf temp_period,w
	btfss zflag
	goto $+4
	movlw 5
	movwf temp_period
	goto set_periods_loop_refresh
	
	movlw 5
	subwf temp_period,f
	movlw 0; change @ zero
	subwf temp_period,w
	btfss zflag
	goto set_periods_loop_refresh
	movlw d'180'
	movwf temp_period
	goto set_periods_loop_refresh



right_action_set_period
	call _deb
	btfsc RIGHT_but
	goto set_periods_loop
	
	call save_periods; save the period lengths
	incf set_per,f
	movlw 19
	subwf set_per,w
	btfsc zflag
	goto $+3
	call load_periods
	goto set_periods_loop_refresh
	

	goto set_TT; select day again
	 
left_action_set_period
	call _deb
	btfsc LEFT_but
	goto set_periods_loop
	
	
	decf set_per,f
	movf set_per,f
	btfsc zflag
	goto $+3
	call load_periods
	goto set_periods_loop_refresh
	
	goto set_TT; select day again; 
	
enter_action_set_period
	call _deb
	btfsc ENTER_but
	goto set_periods_loop
	movlw 255
	movwf temp_period	

	call save_periods; save the current contents of temp period
	goto set_TT; select day again
	
load_day_starts
		movlw 2
		movwf PCLATH
		movfw temp_day
		addwf PCL,f
		nop
		goto load_mon_day_starts
		goto load_tue_day_starts
		goto load_wed_day_starts
		goto load_thu_day_starts
		goto load_fri_day_starts
		
load_mon_day_starts
		movlw monH
		movwf ee_addr
		call eeprom_read
		movwf temp_hr
		
		movlw monM
		movwf ee_addr
		call eeprom_read
		movwf temp_min
		return
load_tue_day_starts
		movlw tueH
		movwf ee_addr
		call eeprom_read
		movwf temp_hr
		
		movlw tueM
		movwf ee_addr
		call eeprom_read
		movwf temp_min
		return
load_wed_day_starts
		movlw wedH
		movwf ee_addr
		call eeprom_read
		movwf temp_hr
		
		movlw wedM
		movwf ee_addr
		call eeprom_read
		movwf temp_min
		return
load_thu_day_starts
		movlw thuH
		movwf ee_addr
		call eeprom_read
		movwf temp_hr
		
		movlw thuM
		movwf ee_addr
		call eeprom_read
		movwf temp_min
		return
load_fri_day_starts
		movlw friH
		movwf ee_addr
		call eeprom_read
		movwf temp_hr
		
		movlw friM
		movwf ee_addr
		call eeprom_read
		movwf temp_min				
		return
		
		
		
load_periods
	movlw 2
	movwf PCLATH
	
	movfw temp_day
	addwf PCL,f
	nop
	goto mon_load_periods
	goto tue_load_periods
	goto wed_load_periods
	goto thu_load_periods
	goto fri_load_periods

mon_load_periods
	
	movlw mon1-1
	movwf temp_data2; 
	
	movfw set_per
	addwf temp_data2,w; POINT TO THE CORRECT EEPROM ADDRESS
	
	movwf ee_addr
	call eeprom_read
	movfw ee_data
	movwf temp_period
	return
	
		
tue_load_periods
	movlw tue1-1
	movwf temp_data2; 
	
	movfw set_per
	addwf temp_data2,w; POINT TO THE CORRECT EEPROM ADDRESS
	
	movwf ee_addr
	call eeprom_read
	movfw ee_data
	movwf temp_period
	return
	
wed_load_periods
	movlw wed1-1
	movwf temp_data2; 
	
	movfw set_per
	addwf temp_data2,w; POINT TO THE CORRECT EEPROM ADDRESS
	
	movwf ee_addr
	call eeprom_read
	movfw ee_data
	movwf temp_period
	return
	
thu_load_periods
	movlw thu1-1
	movwf temp_data2; 
	
	movfw set_per
	addwf temp_data2,w; POINT TO THE CORRECT EEPROM ADDRESS
	
	movwf ee_addr
	call eeprom_read
	movfw ee_data
	movwf temp_period
	return
	
fri_load_periods
	movlw fri1-1
	movwf temp_data2; 
	
	movfw set_per
	addwf temp_data2,w; POINT TO THE CORRECT EEPROM ADDRESS
	
	movwf ee_addr
	call eeprom_read
	movfw ee_data
	movwf temp_period
	return
	
	
save_periods
	
	movlw 3
	movwf PCLATH
	
	movfw temp_day
	addwf PCL,f
	nop
	goto mon_save_periods
	goto tue_save_periods
	goto wed_save_periods
	goto thu_save_periods
	goto fri_save_periods
	
	
mon_save_periods
	movf ds_saved?,f; has the start of the day been saved
	btfss zflag
	goto mon_save_cont
	
	movfw temp_hr; save temp_hr
	movwf ee_data
	movlw monH
	movwf ee_addr
	call eeprom_write
	
	movfw temp_min; save temp_min
	movwf ee_data
	movlw monM
	movwf ee_addr
	
	call eeprom_write
	incf ds_saved?,f; the start of the day has been saved
mon_save_cont
	
	movlw mon1-1
	movwf temp_data2
		
	movfw set_per
	addwf temp_data2,w
	movwf ee_addr
	
	movfw temp_period
	movwf ee_data
	
	call eeprom_write
	return
	
tue_save_periods
	movf ds_saved?,f; has the start of the day been saved
	btfss zflag
	goto tue_save_cont

	movfw temp_hr
	movwf ee_data
	movlw tueH
	movwf ee_addr
	call eeprom_write
	
	movfw temp_min
	movwf ee_data
	movlw tueM
	movwf ee_addr
	call eeprom_write
	incf ds_saved?,f; the start of the day has been saved
tue_save_cont

	movlw tue1-1
	movwf temp_data2
	
	movfw set_per
	addwf temp_data2,w
	movwf ee_addr
	
	movfw temp_period
	movwf ee_data
	
	call eeprom_write
	return
wed_save_periods
	movf ds_saved?,f; has the start of the day been saved
	btfss zflag
	goto wed_save_cont

	movfw temp_hr
	movwf ee_data
	movlw wedH
	movwf ee_addr
	call eeprom_write
	
	movfw temp_min
	movwf ee_data
	movlw wedM
	movwf ee_addr
	call eeprom_write
	incf ds_saved?,f; the start of the day has been saved
wed_save_cont

	movlw wed1-1
	movwf temp_data2
	
	movfw set_per
	addwf temp_data2,w
	movwf ee_addr
	
	movfw temp_period
	movwf ee_data
	
	call eeprom_write
	return
thu_save_periods

	movf ds_saved?,f; has the start of the day been saved
	btfss zflag
	goto thu_save_cont
	
	movfw temp_hr
	movwf ee_data
	movlw thuH
	movwf ee_addr
	call eeprom_write
	
	movfw temp_min
	movwf ee_data
	movlw thuM
	movwf ee_addr
	call eeprom_write
	incf ds_saved?,f; the start of the day has been saved
	
thu_save_cont
	movlw thu1-1
	movwf temp_data2
	
	movfw set_per
	addwf temp_data2,w
	movwf ee_addr
	
	movfw temp_period
	movwf ee_data
	
	call eeprom_write
	return
	
fri_save_periods
	movf ds_saved?,f; has the start of the day been saved
	btfss zflag
	goto fri_save_cont

	movfw temp_hr
	movwf ee_data
	movlw friH
	movwf ee_addr
	call eeprom_write

	movfw temp_min
	movwf ee_data
	movlw friM
	movwf ee_addr
	call eeprom_write
	incf ds_saved?,f; the start of the day has been saved
fri_save_cont

	movlw fri1-1
	movwf temp_data2
	
	movfw set_per
	addwf temp_data2,w
	movwf ee_addr
	
	movfw temp_period
	movwf ee_data
	
	call eeprom_write
	return


_deb
	movlw	0x9F
	movwf	d1
	movlw	0x10
	movwf	d2
Delay_deb
	decfsz	d1, f
	goto	$+2
	decfsz	d2, f
	goto	Delay_deb
			;2 cycles
	goto	$+1
	return
	
_1sec
	movlw	0x08
	movwf	d1
	movlw	0x2F
	movwf	d2
	movlw	0x03
	movwf	d3
Delay_1sec
	decfsz	d1, f
	goto	$+2
	decfsz	d2, f
	goto	$+2
	decfsz	d3, f
	goto	Delay_1sec
	goto	$+1
	nop
	return

?_delay
	movwf temp_data2
	
?_delay_loop	
	movlw	0xC7
	movwf	d1
	movlw	0x01
	movwf	d2
Delay_?_delay
	decfsz	d1, f
	goto	$+2
	decfsz	d2, f
	goto	Delay_?_delay
	goto	$+1
	decfsz temp_data2,f
	goto ?_delay_loop
	return
	
load_new_periods
	movlw 3 
	movwf PCLATH
	movfw day
	addwf PCL,f
	nop
	goto load_mon
	goto load_tue
	goto load_wed
	goto load_thu
	goto load_fri
	goto load_sat
	goto load_sun
	
load_mon
	movlw monH
	movwf temp_data3
	
	movlw monM
	movwf temp_data4
	call load_new_day_starts
	return
		
load_tue
	movlw tueH
	movwf temp_data3
	
	movlw tueM
	movwf temp_data4
	call load_new_day_starts
	return
load_wed
	movlw wedH
	movwf temp_data3
	
	movlw wedM
	movwf temp_data4
	call load_new_day_starts
	return
load_thu
	movlw thuH
	movwf temp_data3
	
	movlw thuM
	movwf temp_data4
	call load_new_day_starts
	return
load_fri
	movlw friH
	movwf temp_data3
	
	movlw friM
	movwf temp_data4
	call load_new_day_starts
	return
load_sat
	movlw d'255'
	movwf daystartsH
	
	movlw d'255'
	movwf daystartsM
	return
load_sun
	movlw d'255'
	movwf daystartsH
	
	movlw d'255'
	movwf daystartsM
	return

load_new_day_starts
	movfw temp_data3
	movwf ee_addr	
	call eeprom_read
	movfw ee_data
	movwf daystartsH
	
	movfw temp_data4
	movwf ee_addr	
	call eeprom_read
	movfw ee_data
	movwf daystartsM
	
	; convert day starts which is in 24hrs to 12 hrs with ampm
	movf daystartsH,f; REMEMBER THE TRECHEROUS TWELVES!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	btfss zflag ; 0hr = 12am
	goto $+5; test failed != 0hr
	
		movlw 12
		movwf daystartsH
		clrf daystartsAMPM
		goto continu_new_day_load
		
	movlw 12; test for 12hrs; 12pm
	subwf daystartsH,w
	btfss zflag 
	goto $+4; 
	
		movlw 255
		movwf daystartsAMPM
		goto continu_new_day_load
	
			; CHECK THE AMPM STATUS
	movlw 12; if the starting hr is greater than or equ 12 
	subwf daystartsH,w
	btfss carry
	goto $+4
	movlw 255 ; the time is a post meridian time
	movwf daystartsAMPM; pm
	goto $+3
	clrf  daystartsAMPM; am
	goto continu_new_day_load
	
	movlw 12
	subwf daystartsH,f
	
continu_new_day_load	
	incf ee_addr,f; point to the first period in the day
	
	movlw p1
	movwf FSR; point to the first period in the day
	
	movlw 18; loop 18 times first pass
	movwf d1
	
load_per_again
	call eeprom_read
	
	movfw ee_data
	movwf INDF
	incf ee_addr,f	
	incf FSR,f
	decfsz d1,f
	goto load_per_again
	return
eeprom_read
	movfw ee_addr
	banksel EEADR
	movwf EEADR
	banksel EECON1
	bcf EECON1,EEPGD
	bsf EECON1,RD
	banksel EEDATA
	movf EEDATA,w
	clrf STATUS; bank 0
	movwf ee_data
	return
	
	
eeprom_write
	movfw ee_addr; reachable regardless of current bank
	banksel EEADR
	movwf EEADR; both eeadd and eedata are in the same bank
	movfw ee_data
	movwf EEDATA	
	banksel EECON1
	bcf EECON1,EEPGD; access data memory
	bsf EECON1,WREN; enable write
	bcf INTCON,GIE; globally disable interrupts
	movlw 0x55
	movwf EECON2
	movlw 0xAA
	movwf EECON2
	bsf EECON1,WR; write the data
	bsf INTCON,GIE; enable interrupts again
	bcf EECON1,WREN; to prevent accidental writes
	btfsc EECON1,WR; wait till write procedure is complete WR is clear
	goto $-1
	clrf STATUS; back to bank 0
	return
	
	
	END ; directive 'end of program'

