#include "drivers/mss_uart/mss_uart.h"
#include "drivers/mss_ace/mss_ace.h"
#include "drivers/mss_gpio/mss_gpio.h"
#include <stdint.h>
#include "mss_timer.h"
#include "mss_gpio.h"
#include "stdlib.h"
#include "neopixels.h"
#include "linklist.h"
#include "vgacontrol.h"

#define SW 0x40050000
#define SW2 0x4005010C
#define SW_reset 0x40050118
#define STEPPER 0x40050200

int curr_player = 1;
ace_channel_handle_t adc_handler;
//int stepVal;
int back_hit = 0;
int made_shot = 0;

void bad_shot(int, int, int);
void swish();
void nice_shot();
__attribute__ ((interrupt)) void Fabric_IRQHandler( void )
{
	made_shot = 1;
	volatile int* stepper_addr = (int*) STEPPER; // load from memory
	uint32_t column = scale(*stepper_addr);
	//store value of stepper motor
	//drop chip
	if(!back_hit)
	{
		swish();
	}
	else {
		nice_shot();
	}
	if(!(get_won2() || get_won3()))
	{
		if (get_score(curr_player) == 14)
		{
			startTimerOneshot(&reset_game, 10*100000000, 0, 0, 30);
		}
		else {
			drop_chip(column, curr_player);
		}

		inc_score(curr_player);
	//set_led(0, 255, 0, 0);
	//set_led(1, 0, 255, 0);
	//set_led(29, 0, 0, 255);
		 //also checks for connect 4
	}

    NVIC_ClearPendingIRQ( Fabric_IRQn );
}

int main()
{
	ACE_init();
	adc_handler = ACE_get_channel_handle((const uint8_t *)"ADCDirectInput_2");

	MSS_GPIO_init();


	MSS_GPIO_config(MSS_GPIO_11, MSS_GPIO_OUTPUT_MODE);
	MSS_GPIO_config(MSS_GPIO_12, MSS_GPIO_OUTPUT_MODE);
	MSS_GPIO_config(MSS_GPIO_13, MSS_GPIO_OUTPUT_MODE);
	MSS_GPIO_config(MSS_GPIO_14, MSS_GPIO_OUTPUT_MODE);

	clear_all(30);
	startTimerOneshot(&ledOn, 100000000, 0,0,1);
	startTimerOneshot(&ledOff, 2*100000000, 0,0,1);
	start_hardware_timer(root->time);
    NVIC_ClearPendingIRQ( Fabric_IRQn );
	NVIC_EnableIRQ(Fabric_IRQn);
	writeWin(0);
	set_player(1);
	//set_led(0, 255, 0, 0);
	volatile int* SW2_addr = (int*) SW2;
	volatile int* SWreset_addr = (int*) SW_reset;
	int prev_player_sw, player_sw, prev_reset_sw, reset_sw;
	int column_counter = 0;
	prev_player_sw = 0;
	prev_reset_sw = 0;
	volatile int* s = (int*) STEPPER;
	while( 1 )
	{
		uint16_t adc_data = ACE_get_ppe_sample(adc_handler);

		//printf("%d\r\n", *s);
		if (((adc_data >> 4) > 165 || (adc_data >> 4) < 80) && !back_hit) {
			back_hit = 1;
			startTimerOneshot(&bad_shot, 2*100000000, 0,0,0);
		}
		player_sw = *SW2_addr;
		reset_sw = *SWreset_addr;
		if(player_sw && !prev_player_sw) {
			if(curr_player == 1) {
				curr_player = 2;
			}
			else {
				curr_player = 1;
			}
			set_player(curr_player);
			column_counter++;
			MSS_GPIO_set_output(MSS_GPIO_11, 1);
			MSS_GPIO_set_output(MSS_GPIO_12, 1);
			MSS_GPIO_set_output(MSS_GPIO_13, 1);
			MSS_GPIO_set_output(MSS_GPIO_14, 1);
			back_hit = 0;
			made_shot = 0;
		}
		/*
		if(column_counter == 2) {
			column_counter = 0;
			if(stepVal >= 500) {
				stepVal = 50;
			}
			else {
				stepVal += 100;
			}
		}*/
		if(reset_sw && !prev_reset_sw) {
			reset_game(0,0,30);
		}
		prev_player_sw = player_sw;
		prev_reset_sw = reset_sw;

	}
}

void bad_shot(int a, int b, int c)
{
	if(!made_shot)
	{
		MSS_GPIO_set_output(MSS_GPIO_12, 0);
	}
}

void swish()
{
	MSS_GPIO_set_output(MSS_GPIO_14, 0);
}

void nice_shot()
{
	MSS_GPIO_set_output(MSS_GPIO_13, 0);
}
