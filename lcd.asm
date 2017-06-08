
	#include	<p16f877A.inc>	; processor specific variable definitions
	radix dec

	
	global init_lcd
	global splash_screen
	global load_cmd
	global load_char
	global idle_screen
	global set_time_refresh
	global set_day_refresh		
	global set_TT_selectday_refresh	
	global set_TT_day_starts_refresh
	global set_TT_set_periods_refresh
				
	extern A11,A12,A13,A14,A15,A16,A17,A18,A19,A110,A111,A112,A113,A114,A115,A116
	extern A21,A22,A23,A24,A25,A26,A27,A28,A29,A210,A211,A212,A213,A214,A215,A216
	 extern ?_delay
	 extern min,hr,day,ampm
	 extern temp_min,temp_hr,temp_day,temp_period,set_per,temp_ampm
	 extern	asciiH,asciiL,val_conv 
	 extern d1
lcd code
	
init_lcd
	movlw d'50'; wait for the lcd
	call ?_delay
	
	movlw b'00000110' ; inc donot shift
	call load_cmd
	
	movlw b'00001100';disp on,cursor,blink
	call load_cmd
	
	movlw b'00010100'; shift cursor
	call load_cmd
	
	movlw b'00111100'; function set
	call load_cmd
	return
	
splash_screen
	
	call clear_buffer
	
	movlw 'e'
	movwf A13
		
	movlw 'C'
	movwf A14
	
	movlw 'R'
	movwf A15
	
	movlw 'O'
	movwf A16
	
	movlw 'N'
	movwf A17
	
	movlw 'E'
	movwf A18
	
	

	
	movlw 'c'
	movwf A211
	
	movlw '2'
	movwf A212
	
	movlw '0'
	movwf A213
	
	movlw '0'
	movwf A214
	
	movlw '7'
	movwf A215

	
	call fill_space
	call load_lcd
	return
	
	
load_lcd
	movlw d'16'; do 16 passes
	movwf temp_data1
	
	movlw A11-1;the address b4  A11 
	movwf FSR; 
	
	incf FSR,f; now point to A11
	
	movfw INDF; for line 1 of 16X2 LCD
	call load_char
	decfsz temp_data1,f
	goto $-4 ; inc FSR
	
	movlw b'11000000'; goto line 2
	call load_cmd; set cursor to begining of line2
	
	movlw d'16'
	movwf temp_data1
	
	movlw A21-1;the address b4  A21 
	movwf FSR; 
	
	incf FSR,f; now point to A21
	
	movfw INDF; for line 1 of 16X2 LCD
	call load_char; WE LOAD OUT CONTENTS OF THE BUFFER AND WRITE IT TO THE LCD
	decfsz temp_data1,f
	goto $-4 ; inc FSR
	
	
	return
	
load_cmd
	movwf LCD_DATA;
	bcf RS; set to instruction register
	bsf E
	
	movlw 2
	call ?_delay; delay for 3ms	
	
	bcf E

	return
	
load_char
	movwf LCD_DATA
	bsf RS
	bsf E; toggling E
	
	movlw 1
	call ?_delay; delay for 3ms
	
	bcf E
	
	return

idle_screen
	call clear_buffer


;	"ATLANTIC HALL"
;	SCHOOL NAME
	movlw a'F'
	movwf A12
	
	movlw a'A'
	movwf A13
	
	movlw a'I'
	movwf A14
	
	movlw a'T'
	movwf A15

	movlw a'H'
	movwf A16
	
	movlw a' '
	movwf A17
	
	movlw a'A'
	movwf A18
	
	movlw a'C'
	movwf A19
	
	
	movlw a'A'
	movwf A110
	
	movlw a'D'
	movwf A111
	
	movlw a'E'
	movwf A112
	
	movlw a'M'
	movwf A113
	
	movlw a'Y'
	movwf A114

	
	call idle_day_table
	
	movfw hr; convert to ascii
	movwf val_conv
	call num2ascii
		
	movfw asciiH
	movwf A28
	
	movfw asciiL
	movwf A29

	movfw min
	movwf val_conv
	call num2ascii
	
	movlw a':'
	movwf A210
	
	movfw asciiH
	movwf A211
	
	movfw asciiL	
	movwf A212
	
	movf ampm,f
	btfss zflag; 
	goto $+6; pm
	
	movlw a'a'; ampm = 0 apres meridian
	movwf A213
	
	movlw a'm'
	movwf A214
	
	goto $+5
	movlw a'p'; ampm = 255 post meridian
	movwf A213
	
	movlw a'm'
	movwf A214



	call fill_space
	call load_lcd
	call blink_lcd_off	
	return

set_time_refresh
	call clear_buffer
	
	movlw a'S'
	movwf A11
	
	movlw a'E'
	movwf A12
	
	movlw a'T'
	movwf A13
	
	movlw a'?'
	movwf A14

	
	movfw temp_hr
	movwf val_conv
	call num2ascii
	
	movfw asciiH
	movwf A110
	
	movfw asciiL
	movwf A111
	
	
	movlw a':'
	movwf A112
	
	movfw temp_min
	movwf val_conv
	call num2ascii
	
	movfw asciiH
	movwf A113

	movfw asciiL
	movwf A114
	
	movf temp_ampm,f
	btfss zflag; 
	goto $+6; pm
	
	movlw a'a'; ampm = 0 apres meridian
	movwf A115
	
	movlw a'm'
	movwf A116
	
	goto $+5
	movlw a'p'; ampm = 255 post meridian
	movwf A115
	
	movlw a'm'
	movwf A116

	
	movlw a'['
	movwf A21
	
	movlw a'C'
	movwf A22
		
	movlw a'A'
	movwf A23
	
	movlw a'N'
	movwf A24
	
	movlw a'C'
	movwf A25
	
	movlw a'E'
	movwf A26
	
	movlw a'L'
	movwf A27
	
	movlw a']'
	movwf A28	
	
	
	
	movlw a'['
	movwf A213
	
	movlw a'O'
	movwf A214
	
	movlw a'K'
	movwf A215
	
	movlw a']'
	movwf A216
	
	call fill_space
	call load_lcd
	
	; put blinking cursor at hr
	movlw set_hr
	subwf state,w; checking machine state
	btfss zflag
	goto blink_min?
	movlw R111; DDRAM address
	call blink_lcd_on
	return
blink_min?	
	movlw set_min
	subwf state,w
	btfss zflag
	goto blink_ampm?
	movlw R114; DDRAM address
	call blink_lcd_on
	return
blink_ampm?	
	movlw set_ampm
	subwf state,w
	btfss zflag
	goto $+3; blink nothing redundant code
	movlw R116; DDRAM address
	call blink_lcd_on
	return
set_day_refresh		
	;call blink_lcd_off
	call clear_buffer

	movlw a'D'
	movwf A11
	
	movlw a'A'
	movwf A12
	
	movlw a'Y'
	movwf A13
	
	movlw a'?'
	movwf A14
	
	call set_day_table	
	
	
	
	
	movlw a'['
	movwf A21

	movlw a'B'
	movwf A22
	
	movlw a'A'
	movwf A23

	movlw a'C'
	movwf A24

	movlw a'K'
	movwf A25

	movlw a']'
	movwf A26



	movlw a'['
	movwf A213

	movlw a'O'
	movwf A214

	movlw a'K'
	movwf A215

	movlw a']'
	movwf A216

	call fill_space
	call load_lcd

	return
	
	
set_TT_selectday_refresh
	
	call clear_buffer
	
	movlw a'S'
	movwf A11
	
	movlw a'E'
	movwf A12
	
	movlw a'T'
	movwf A13
	
	movlw a'?'
	movwf A18
	
	movlw a'['
	movwf A21
	
	movlw a'C'
	movwf A22

	movlw a'A'
	movwf A23

	movlw a'N'
	movwf A24

	movlw a'C'
	movwf A25

	movlw a'E'
	movwf A26

	movlw a'L'
	movwf A27

	movlw a']'
	movwf A28
	
	
	
	movlw a'['
	movwf A212
		
	movlw a'S'
	movwf A213
		
	movlw a'E'
	movwf A214
	
	movlw a'T'
	movwf A215
	
	movlw a']'
	movwf A216
	
	call set_TT_selectday_table
	
	call fill_space
	call load_lcd
	return	



set_TT_day_starts_refresh
	call clear_buffer

	call set_TT_day_starts_table
	
	movlw 'S'
	movwf A15
	
	movlw 'T'
	movwf A16
	
	movlw 'A'
	movwf A17
	
	movlw 'R'
	movwf A18
	
	movlw 'T'
	movwf A19
	
		
	movlw a'['
	movwf A21
	
	movlw a'B'
	movwf A22
	
	movlw a'A'
	movwf A23
	
	movlw a'C'
	movwf A24
	
	movlw a'K'
	movwf A25
	
	movlw a']'
	movwf A26
	
	
	movlw a'['
	movwf A28
	
	movlw a'X'; set button meaning nothing for that day
	movwf A29
	
	movlw a']'
	movwf A210
	
	
	movlw a'['
	movwf A212
	
	movlw a'P'
	movwf A213
	
	movlw a'E'
	movwf A214
	
	movlw a'R'
	movwf A215
	
	
	movlw a']'
	movwf A216
	
	movlw 255
	subwf temp_hr,w
	btfsc zflag
	goto nothing_for_today

	movf temp_hr,f
	btfss zflag
	goto $+4
	movlw 12
	movwf temp_hr
	goto ds_am

	
	movlw 11; demarcate between am & pm
	subwf temp_hr,w
	btfss carry; carry is a positive flag
	goto ds_am; am
	
	movlw 11; carry flag is a zero or positive flag
	subwf temp_hr,w
	btfss zflag
	goto $+4
	movlw 11
	movwf temp_data0
	goto ds_am; am
	
	; **********ds_pm*************
	movlw 12; 12hrs = 12 pm
	subwf temp_hr,w
	btfss zflag
	goto $+4; greater than 12 hrs
	 
	movfw temp_hr; which of course is 12pm
	movwf temp_data0
	goto $+4
	
	movlw 12; starting from 13hrs or 1pm
	subwf temp_hr,w
	movwf temp_data0; the result which is now less than 12 is in the working register
	movlw 'p';greater than 12 show pm
	movwf A116
	goto $+5
	
ds_am
	movfw temp_hr
	movwf temp_data0
	movlw 'a'; less than 12 show am
	movwf A116
ds_am_pm_cont; convert to ascii regardless of am or pm	
	movfw temp_data0; contains processed data from temp_hr
	movwf val_conv
	call num2ascii
	
	movfw asciiH
	movwf A111
	
	movfw asciiL
	movwf A112
	
	movlw a':'
	movwf A113
	
	movfw temp_min
	movwf val_conv
	call num2ascii
	
	movfw asciiH
	movwf A114
	
	movfw asciiL
	movwf A115
	
	goto sth_for_today; there are time_table entries
	
nothing_for_today
	movlw '-'
	movwf A112
	
	movlw '-'
	movwf A113
	
	movlw ':'
	movwf A114
	
	movlw '-'
	movwf A115
	
	movlw '-'
	movwf A116
	goto continue_day_starts_refresh	
	
sth_for_today	; put the cursor at the appropriate location
	

continue_day_starts_refresh	
	call fill_space
	call load_lcd
	
	movlw set_TT_daystartsH
	subwf state,w
	btfss zflag
	goto $+4
	movlw R112
	call blink_lcd_on
	return
	
	
	movlw set_TT_daystartsM
	subwf state,w
	btfss zflag
	return
	movlw R115
	call blink_lcd_on
	return
	
set_TT_set_periods_refresh
	call clear_buffer
	
	call set_TT_day_starts_table
	
	
	movlw a'P'
	movwf A15
	
	movfw set_per
	movwf val_conv
	call num2ascii
	
	movlw a'0'
	subwf asciiH,w
	btfss zflag
	goto $+4; there is ascii H and L
	movfw asciiL
	movwf A16
	goto$+5; there is no ascii H
	
	
	movfw asciiH
	movwf A16	
	
	movfw asciiL
	movwf A17
	
	
	movlw a'B'
	movwf A21
	
	movlw a'A'
	movwf A22
	
	movlw a'C'
	movwf A23
	
	movlw a'K'
	movwf A24
	
	
	movlw a'['
	movwf A28
	
	movlw a'E'
	movwf A29
	
	movlw a'N'
	movwf A210
	
	movlw a'D'
	movwf A211
	
	movlw a']'
	movwf A212
	
	
	movlw a'O'
	movwf A215
	
	movlw a'K'
	movwf A216
	
	movlw 255
	subwf temp_period,w
	btfss zflag
	goto $+8
	
	movlw 'E'
	movwf A111
	
	movlw 'N'
	movwf A112
	
	movlw 'D'
	movwf A113
	goto continue
	
	clrf temp_data0
	movlw 60; if period length is greater than 60
	subwf temp_period,w
	btfss carry
	goto less_than_60
	
	movfw temp_period
	movwf temp_data3; instead of editing the contents of temp period

still_greater_than_60?

	movlw 60
	subwf temp_data3,f
	incf temp_data0,f
	
	movlw 60; still greater than 60
	subwf temp_data3,w
	btfsc carry
	goto still_greater_than_60?
	goto show_hr_and_min
	
less_than_60	; show minutes only
	movfw temp_period
	movwf val_conv
	
	call num2ascii
	movfw asciiH
	movwf A111
	
	movfw asciiL
	movwf A112
	
	movlw a'm'
	movwf A113
	goto continue
	
show_hr_and_min	
	movfw temp_data0
	movwf val_conv
	call num2ascii
	
	movfw asciiL
	movwf A19
	
	movlw 'h'
	movwf A110
	
	
	movfw temp_data3; instead of temp_period
	movwf val_conv
	
	call num2ascii
	movfw asciiH
	movwf A111
	
	movfw asciiL
	movwf A112
	
	movlw a'm'
	movwf A113
	
	
continue	
	call fill_space
	call load_lcd
	return
	; putting the cursor in the appropriate location

	movlw set_TT_daystartsH
	subwf state,w
	btfss zflag
	goto blink_day_startsM
	movlw R113; DDRAM address
	call blink_lcd_on
	return
	
blink_day_startsM	
	movlw set_TT_daystartsM
	subwf state,w
	btfss zflag
	goto $+3
	movlw R113; DDRAM address
	call blink_lcd_on
	return
	
	
clear_buffer
	
	
	movlw d'33'
	movwf temp_data0
	
	movlw A11
	movwf FSR
	
clear_again; clear all the lcd buffers
	clrf INDF
	incf FSR,f
	decfsz temp_data0,f
	goto clear_again

	movlw 0x1
	call load_cmd
	movlw 30
	call ?_delay
	return
	
fill_space
	movlw d'33'
	movwf d1
	
	movlw A11-1 ; point to the address before FSR 
	movwf FSR
	
fill_again; clear all the lcd buffers
	decfsz d1,f
	goto $+2
	return
	incf FSR,f;point to FSR on first pass
	movf INDF,f
	btfss zflag; if the space is empty fill with space el
	goto fill_again

	movlw a' '
	movwf INDF
	goto fill_again

	
blink_lcd_on
	movwf lcd_address
	
	movlw b'00001101'; turn blink on
	call load_cmd
	
	movfw lcd_address
	iorlw b'10000000';	set cursor to the address
	
	call load_cmd
	return
blink_lcd_off	
	movlw b'00001100'; turn blinking off
	call load_cmd
	return


idle_day_table
	movlw 6
	movwf PCLATH
	
	movfw day
	addwf PCL,f
	nop
	goto mon_idle_day
	goto tue_idle_day
	goto wed_idle_day
	goto thu_idle_day
	goto fri_idle_day
	goto sat_idle_day
	goto sun_idle_day
	
mon_idle_day
	movlw a'M'
	movwf A23
	
	movlw a'O'
	movwf A24
	
	movlw a'N'
	movwf A25
	return
	
tue_idle_day
	movlw a'T'
	movwf A23
	
	movlw a'U'
	movwf A24
	
	movlw a'E'
	movwf A25
	return

wed_idle_day
	movlw a'W'
	movwf A23
	
	movlw a'E'
	movwf A24
	
	movlw a'D'
	movwf A25
	return
thu_idle_day
	movlw a'T'
	movwf A23
	
	movlw a'H'
	movwf A24
	
	movlw a'U'
	movwf A25
	return
	
fri_idle_day
	movlw a'F'
	movwf A23
	
	movlw a'R'
	movwf A24
	
	movlw a'I'
	movwf A25
	return
	
sat_idle_day
	movlw a'S'
	movwf A23
	
	movlw a'A'
	movwf A24
	
	movlw a'T'
	movwf A25
	return
	
sun_idle_day
	movlw a'S'
	movwf A23
	
	movlw a'U'
	movwf A24
	
	movlw a'N'
	movwf A25
	return

	code 0x70A
set_day_table; for the routine when the day is being set
	movlw 7
	movwf PCLATH
	
	;pagesel mon_set_day
	
	movfw temp_day
	addwf PCL,f
	nop
	goto mon_set_day
	goto tue_set_day
	goto wed_set_day
	goto thu_set_day
	goto fri_set_day
	goto sat_set_day
	goto sun_set_day
	
mon_set_day
	movlw a'M'
	movwf A112
	
	movlw a'O'
	movwf A113
	
	movlw a'N'
	movwf A114
	return
	
tue_set_day
	movlw a'T'
	movwf A112
	
	movlw a'U'
	movwf A113
	
	movlw a'E'
	movwf A114
	return

wed_set_day
	movlw a'W'
	movwf A112
	
	movlw a'E'
	movwf A113
	
	movlw a'D'
	movwf A114
	return
	
thu_set_day
	movlw a'T'
	movwf A112
	
	movlw a'H'
	movwf A113
	
	movlw a'U'
	movwf A114
	return
	
fri_set_day
	movlw a'F'
	movwf A112
	
	movlw a'R'
	movwf A113
	
	movlw a'I'
	movwf A114
	return
	
sat_set_day
	movlw a'S'
	movwf A112
	
	movlw a'A'
	movwf A113
	
	movlw a'T'
	movwf A114
	return
	
sun_set_day
	movlw a'S'
	movwf A112
	
	movlw a'U'
	movwf A113
	
	movlw a'N'
	movwf A114
	return
	
set_TT_selectday_table
	
	movlw 7
	movwf PCLATH
	
	movfw temp_day
	addwf PCL,f
	nop
	goto mon_set_TT_selectday
	goto tue_set_TT_selectday
	goto wed_set_TT_selectday
	goto thu_set_TT_selectday
	goto fri_set_TT_selectday
	
mon_set_TT_selectday
	movlw a'M'
	movwf A15
	
	movlw a'O'
	movwf A16
	
	movlw a'N'
	movwf A17
	return
	
tue_set_TT_selectday
	movlw a'T'
	movwf A15
	
	movlw a'U'
	movwf A16
	
	movlw a'E'
	movwf A17
	return

wed_set_TT_selectday
	movlw a'W'
	movwf A15
	
	movlw a'E'
	movwf A16
	
	movlw a'D'
	movwf A17
	return
	
thu_set_TT_selectday
	movlw a'T'
	movwf A15
	
	movlw a'H'
	movwf A16
	
	movlw a'U'
	movwf A17
	return
	
fri_set_TT_selectday
	movlw a'F'
	movwf A15
	
	movlw a'R'
	movwf A16
	
	movlw a'I'
	movwf A17
	return
	
set_TT_day_starts_table
	movlw 7
	movwf PCLATH
	
	movfw temp_day
	addwf PCL,f
	nop
	goto mon_set_TT_day_starts
	goto tue_set_TT_day_starts
	goto wed_set_TT_day_starts
	goto thu_set_TT_day_starts
	goto fri_set_TT_day_starts
	
mon_set_TT_day_starts
	movlw a'M'
	movwf A11
	
	movlw a'O'
	movwf A12
	
	movlw a'N'
	movwf A13
	return
	
tue_set_TT_day_starts
	movlw a'T'
	movwf A11
	
	movlw a'U'
	movwf A12
	
	movlw a'E'
	movwf A13
	return

wed_set_TT_day_starts
	movlw a'W'
	movwf A11
	
	movlw a'E'
	movwf A12
	
	movlw a'D'
	movwf A13
	return
	
thu_set_TT_day_starts
	movlw a'T'
	movwf A11
	
	movlw a'H'
	movwf A12
	
	movlw a'U'
	movwf A13
	return
	
fri_set_TT_day_starts
	movlw a'F'
	movwf A11
	
	movlw a'R'
	movwf A12
	
	movlw a'I'
	movwf A13
	return


	
	
num2ascii; this subroutine converts numerals to their ascii format
	movfw val_conv
	
	movwf asciiL
	clrf asciiH
	
	movlw 10
	subwf asciiL,w; if asciiL is greater than 10
	btfss carry
	goto less_than_10
	
greater_than_10	
	movlw 10; subtract 10
	subwf asciiL,f
	incf asciiH,f
	
	movlw 10; test
	subwf asciiL,w
	btfsc carry
	goto greater_than_10
less_than_10		
	movfw asciiH
	call ascii_table
	movwf asciiH
	
	movfw asciiL
	call ascii_table
	movwf asciiL
	return
ascii_table
	movwf temp_data1
	
	movlw 7
	movwf PCLATH
	
	movfw temp_data1
	addwf PCL,f
	retlw a'0'
	retlw a'1'
	retlw a'2'
	retlw a'3'
	retlw a'4'
	retlw a'5'
	retlw a'6'
	retlw a'7'
	retlw a'8'
	retlw a'9'						
	end
