/*
* asm.s
*
* Ömer Faruk KOÇ
*
* description: counter with 7 segment displays
*
*/
.syntax unified
.cpu cortex-m0
.fpu softvfp
.thumb
.global Reset_Handler
.word _sdata
.word _edata
.word _sbss
.word _ebss

/* define peripheral addresses from RM0444 page 57, Tables 3-4 */
.equ RCC_BASE, (0x40021000) // RCC base address
.equ RCC_IOPENR, (RCC_BASE + (0x34)) // RCC IOPENR register offset
.equ GPIOB_BASE, (0x50000400) // GPIOb base address
.equ GPIOB_MODER, (GPIOB_BASE + (0x00)) // GPIOb MODER register offset
.equ GPIOB_ODR, (GPIOB_BASE + (0x14)) // GPIOb ODR register offset
.equ GPIOB_IDR, (GPIOB_BASE + (0x10))
.equ GPIOA_BASE, (0x50000000) // GPIOa base address
.equ GPIOA_MODER, (GPIOA_BASE + (0x00)) // GPIOa MODER registe roffset
.equ GPIOA_ODR, (GPIOA_BASE + (0x14)) // GPIOa ODR register offset
.equ GPIOA_IDR, (GPIOA_BASE + (0x10))

/* vector table, +1 thumb mode */
.section .vectors
vector_table:
.word _estack /* Stack pointer */
.word Reset_Handler +1 /* Reset handler */
.word Default_Handler +1 /* NMI handler */
.word Default_Handler +1 /* HardFault handler */

/* add rest of them here if needed */
/* reset handler */
.section .text
Reset_Handler:
/* set stack pointer */
ldr r0, =_estack
mov sp, r0
/* initialize data and bss
* not necessary for rom only code
* */
bl init_data
/* call main */
bl main
/* trap if returned */
b .

/* initialize data and bss sections */
.section .text
init_data:
/* copy rom to ram */
ldr r0, =_sdata
ldr r1, =_edata
ldr r2, =_sidata
movs r3, #0
b LoopCopyDataInit
CopyDataInit:
ldr r4, [r2, r3]
str r4, [r0, r3]
adds r3, r3, #4
LoopCopyDataInit:
adds r4, r0, r3
cmp r4, r1
bcc CopyDataInit
/* zero bss */
ldr r2, =_sbss
ldr r4, =_ebss
movs r3, #0
b LoopFillZerobss

FillZerobss:
str r3, [r2]
adds r2, r2, #4
LoopFillZerobss:
cmp r2, r4
bcc FillZerobss
bx lr

/* default handler */
.section .text
Default_Handler:
b Default_Handler


/* main function */
.section .text
main:
/* enable GPIOa-b clock, bit1-bit2 on IOPENR */
ldr r6, =RCC_IOPENR
ldr r5, [r6]
movs r4, 0x3
orrs r5, r5, r4
str r5, [r6]

/* i choose a0-a1-a4-a5 for screen parts a6 for external led and
a7 for button*/
/* setup to output mode for input */
/* 1111_1111_0000_1111 */
ldr r6, =GPIOA_MODER
ldr r5, [r6]
ldr r4, =0xFF0F
mvns r4, r4
ands r5, r5, r4
ldr r4, =0x1505
orrs r5, r5, r4
str r5, [r6]

/* i choose b0=a, b1=b, b2=c, b3=d, b4=e, b5=f, b6=g for screen
parts */
ldr r6, =GPIOB_MODER
ldr r5, [r6]
ldr r4, =0x3FFF
mvns r4, r4
ands r5, r5, r4
ldr r4, =0x1555
orrs r5, r5, r4
str r5, [r6]
ldr r7, =GPIOA_ODR
ldr r6, [r7]
ldr r5, =GPIOB_ODR
ldr r4, [r5]
ldr r3, =0x3E8 /*seed*/
/*i use r0 for the choosen number to show */
/*this function turn off the led and show my number until button
pressed */

my_school_number:
/*external led turn on after 0000*/
ldr r2, =0x40
orrs r6,r6,r2
str r6, [r7]
show_my_school_number:
ldr r0,=0x6B1
bl decompose_digits_and_show
b button_check
/*if button pressed goes to count_down */
button_check:
push {r0-r3}
ldr r0, =GPIOA_IDR
ldr r1, [r0]
ldr r2,=0x80
ands r1,r1,r2
CMP r1,r2
BEQ make_pop
BNE show_my_number_1

make_pop:
pop {r0-r3}
bl secret_delay
B count_down
/*reason why i wrote these functions, prevent any stack problems
*/
show_my_number_1:
pop {r0-r3}
B show_my_school_number

count_down:
push {r0-r3}
ldr r2, =0x0
ands r6,r6,r2
str r6, [r7]
/*external led turn off*/
/*subs untill zero or button press*/
back_from_count_loop:
bl decompose_digits_and_show
bl button_check_for_stop
subs r0,0x1
CMP r0,0x0
BEQ after_count
b back_from_count_loop
/*go to show my school number after waiting 1 second*/
after_count:
/*external led turn on after 0000*/
ldr r2, =0x40
orrs r6,r6,r2
str r6, [r7]
bl wait_one_second
b stop_the_count
/*after some trys 0x500 give me the 1 second wait*/
/*after r0 = 0 it show the last 0000 number about 1 second*/

wait_one_second:
push {r1-r3,lr}
ldr r1, =0x500
wait_one_second_loop:
subs r1,0x1
bl decompose_digits_and_show
CMP r1,0x0
BNE wait_one_second_loop
pop {r1-r3,pc}
/*this function turn on the external led and stops the counting
and showing last number after button press.*/

stop_the_count:
ldr r2, =0x40
orrs r6,r6,r2
str r6, [r7]
bl decompose_digits_and_show
b button_check_for_start_again
button_check_for_stop:
push {r0-r3}
ldr r0, =GPIOA_IDR
ldr r1, [r0]
ldr r2,=0x80
ands r1,r1,r2
CMP r1,r2
pop {r0-r3}
BEQ stop_the_count_1
bx lr
/*goes stop the count after little secret delay*/
stop_the_count_1:
bl secret_delay
b stop_the_count

button_check_for_start_again:
push {r1-r4}
ldr r4, =GPIOA_IDR
ldr r1, [r4]
ldr r2,=0x80
ands r1,r1,r2
CMP r1,r2
pop {r1-r4}
BNE stop_the_count
b back_from_count_2
/*checks the button if button pressed goes the counting after secret delay*/

back_from_count_2:
bl secret_delay
b my_school_number
/*i named secret delay because it is unnoticeable when program
working. It blocks the button press twice.*/
/*after some trys 0x100 give me enough time to take my hand off
the button*/
/*after button press it show the last r0 number about 1 second*/

secret_delay:
push {r1-r3,lr}
ldr r1, =0x100
secret_delay_loop:
subs r1,0x1
bl decompose_digits_and_show
CMP r1,0x0
BNE secret_delay_loop
pop {r1-r3,pc}


/*this function basicly takes the 4 digit number first gets the
first digit with dividing(subs style)
* actives screen1 and says the
* leds what number is first number. after it close first screen
do all that for 2,3,4..*/
decompose_digits_and_show:
push {r0-r3,lr}
bl thousand
bl ssd_screen1_active
bl display
bl delay
bl ssd_screen_deactive
bl hundred
bl ssd_screen2_active
bl display
bl delay
bl ssd_screen_deactive
bl ten
bl ssd_screen3_active
bl display
bl delay
bl ssd_screen_deactive
movs r3,r0
/*in this point r0 value goes r3 because in display function r3
is the digit */
bl ssd_screen4_active
bl display
bl delay
bl ssd_screen_deactive
pop {r0-r3,pc}


delay:
push {r0-r7,lr}
ldr r0, =0x400
/*r0 controls the speed of the counting make sure its not zero.
0x400 is good enough the counting speed.
*it is about 1000 times a second*/
delay_loop:
subs r0,r0,0x1
CMP r0,0x0
BNE delay_loop
pop {r0-r7,pc}


/*r0 dividing by 1000 after that r0 = r0-1000. this way its
easier to divide by hundreds tens*/
thousand:
push {r1-r2}
movs r3,0x0
/*r3 counter*/
ldr r1, =0x3E8
CMP r0,r1
BLT break_thousand
thousand_loop:
subs r0,r0,r1
adds r3,r3,0x1
CMP r0,r1
BGE thousand_loop
break_thousand:
pop {r1-r2}
bx lr


/*r0 dividing by 100 after that r0 = r0-100. this way its easier
to divide by hundreds tens*/
hundred:
push {r1-r2}
movs r3,0x0
/*r3 counter*/
ldr r1, =0x64
CMP r0,r1
BLT break_hundred
hundred_loop:
subs r0,r0,r1
adds r3,r3,0x1
CMP r0,r1
BGE hundred_loop
break_hundred:
pop {r1-r2}
bx lr


/*r0 dividing by 10 after that r0 = r0-10. this way its easier
to divide by hundreds tens*/
ten:
push {r1-r2}
movs r3,0x0
/*r3 counter*/
ldr r1, =0xA
CMP r0,r1
BLT break_ten
ten_loop:
subs r0,r0,r1
adds r3,r3,0x1
CMP r0,r1
BGE ten_loop


break_ten:
pop {r1-r2}
bx lr
/*d1-d2-d3-d4 pins of the 7 segment display. sets and resets*/
ssd_screen1_active:
push {r0-r5}
movs r0, 0x1
orrs r6,r6,r0
str r6,[r7]
pop {r0-r5}
bx lr
ssd_screen2_active:
push {r0-r5}
movs r0, 0x2
orrs r6,r6,r0
str r6,[r7]
pop {r0-r5}
bx lr
ssd_screen3_active:
push {r0-r5}
movs r0, 0x10
orrs r6,r6,r0
str r6,[r7]
pop {r0-r5}
bx lr
ssd_screen4_active:
push {r0-r5}
movs r0, 0x20
orrs r6,r6,r0
str r6,[r7]
pop {r0-r5}
bx lr
ssd_screen_deactive:
push {r0-r5}
movs r0, 0x40
ands r6,r6,r0
str r6,[r7]
pop {r0-r5}
bx lr


/*in dividing stage r3 was the counter. counter compared 0 to 9
and goes light that*/
display:
push {r0-r3}
movs r0,0x0
CMP r3,r0
BEQ sayzero
adds r0,r0,0x1
CMP r3,r0
BEQ sayone
adds r0,r0,0x1
CMP r3,r0
BEQ saytwo
adds r0,r0,0x1
CMP r3,r0
BEQ saythree
adds r0,r0,0x1
CMP r3,r0
BEQ sayfour
adds r0,r0,0x1
CMP r3,r0
BEQ sayfive
adds r0,r0,0x1
CMP r3,r0
BEQ saysix
adds r0,r0,0x1
CMP r3,r0
BEQ sayseven
adds r0,r0,0x1
CMP r3,r0
BEQ sayeight
adds r0,r0,0x1
CMP r3,r0
BEQ saynine
/*these are the 7 segment display states 0 to 9*/
sayzero:
/* for zero abcdef light */
/* but first close all pins*/
push {r0-r3}
movs r0,0x0
ands r4,r4,r0
movs r0,0x3F
orrs r4,r4,r0
/* i use common anode so reverse all*/
mvns r4,r4
str r4,[r5]
pop {r0-r3}
pop {r0-r3}
bx lr
sayone:
/* for one bc light */
/* but first close all pins*/
push {r0-r3}
movs r0,0x0
ands r4,r4,r0
movs r0,0x6
orrs r4,r4,r0
/* i use common anode so reverse all*/
mvns r4,r4
str r4,[r5]
pop {r0-r3}
pop {r0-r3}
bx lr
saytwo:
/* for two abdeg light */
/* but first close all pins*/
push {r0-r3}
movs r0,0x0
ands r4,r4,r0
movs r0,0x5B /*0101_1011*/
orrs r4,r4,r0
/* i use common anode so reverse all*/
mvns r4,r4
str r4,[r5]
pop {r0-r3}
pop {r0-r3}
bx lr
saythree:
/* for three abcdg light */
/* but first close all pins*/
push {r0-r3}
movs r0,0x0
ands r4,r4,r0
movs r0,0x4F /*0100_1111*/
orrs r4,r4,r0
/* i use common anode so reverse all*/
mvns r4,r4
str r4,[r5]
pop {r0-r3}
pop {r0-r3}
bx lr
sayfour:
/* for four bcfg light */
/* but first close all pins*/
push {r0-r3}
movs r0,0x0
ands r4,r4,r0
movs r0,0x66 /*0110_0110*/
orrs r4,r4,r0
/* i use common anode so reverse all*/
mvns r4,r4
str r4,[r5]
pop {r0-r3}
pop {r0-r3}
bx lr
sayfive:
/* for five acdfg light */
/* but first close all pins*/
push {r0-r3}
movs r0,0x0
ands r4,r4,r0
movs r0,0x6D /*0110_1101*/
orrs r4,r4,r0
/* i use common anode so reverse all*/
mvns r4,r4
str r4,[r5]
pop {r0-r3}
pop {r0-r3}
bx lr
saysix:
/* for six acdefg light */
/* but first close all pins*/
push {r0-r3}
movs r0,0x0
ands r4,r4,r0
movs r0,0x7D /*0111_1101*/
orrs r4,r4,r0
/* i use common anode so reverse all*/
mvns r4,r4
str r4,[r5]
pop {r0-r3}
pop {r0-r3}
bx lr
sayseven:
/* for seven abc light */
/* but first close all pins*/
push {r0-r3}
movs r0,0x0
ands r4,r4,r0
movs r0,0x7 /*0000_0111*/
orrs r4,r4,r0
/* i use common anode so reverse all*/
mvns r4,r4
str r4,[r5]
pop {r0-r3}
pop {r0-r3}
bx lr
sayeight:
/* for eight abcdefg light */
/* but first close all pins*/
push {r0-r3}
movs r0,0x0
ands r4,r4,r0
movs r0,0x7F /*0111_1111*/
orrs r4,r4,r0
/* i use common anode so reverse all*/
mvns r4,r4
str r4,[r5]
pop {r0-r3}
pop {r0-r3}
bx lr
saynine:
/* for nine abcdefg light */
/* but first close all pins*/
push {r0-r3}
movs r0,0x0
ands r4,r4,r0
movs r0,0x6F /*0110_1111*/
orrs r4,r4,r0
/* i use common anode so reverse all*/
mvns r4,r4
str r4,[r5]
pop {r0-r3}
pop {r0-r3}
bx lr

/* for(;;); */
b .
/* this should never get executed */
nop
