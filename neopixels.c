/*
 * neopixels.c
 *
 *  Created on: Nov 28, 2018
 *      Author: Nathan Peterson,
				Shrihari Bhaskaramurthi
 */


#include <stdint.h>
#include "mss_timer.h"
#include "mss_gpio.h"
#include "stdlib.h"
#include "neopixels.h"
#include "linklist.h"
#include "vgacontrol.h"

#define LEDADDR 0x40050010

const int DROPTIME = 30000000;
int grid[5][6] = {0};
int won2 = 0;

void set_led(uint32_t ledNum, uint32_t r, uint32_t g, uint32_t b) {
	volatile uint32_t *neoAddr = (uint32_t*) LEDADDR;
	uint32_t val = ((ledNum<<24)&(31<<24)) | (g<<16) | (r<<8) | b;
	*neoAddr = val;
}

void clear_all(uint32_t led_total) {
	volatile uint32_t *neoAddr = (uint32_t*) LEDADDR;
	int i = 0;
	for(i; i < (led_total); i++) *neoAddr = i<<24;
}

void set_ledhex(uint32_t ledNum, uint32_t hex) {
	volatile uint32_t *neoAddr = (uint32_t*) LEDADDR;
	uint32_t temp = (hex & 0xFF00) << 8;
	uint32_t temp2 = (hex & 0xFF0000) >> 8;
	temp = (hex & 0xFF) | temp2 | temp;
	uint32_t val = ((ledNum<<24)&(31<<24)) | temp;
	*neoAddr = val;
}

void ledOn(int column, int row, int player)
{
	int ledNum = get_ledNum(row, column); //Calculate using column, row

	if(player == 1) //red
	{
		set_led(ledNum, 255,0,0);
	}
	else if(player == 2) //blue
	{
		set_led(ledNum, 0,0,255);
	}
}

//player has value 1 or 2
void drop_chip(uint32_t column, int player) {

	//int column = (int)(scale(stepVal)); // number between [0 - 5] to indicate column
	int lowestchip = 4;
	int i;
	for(i = 4; i>=0; i--)
	{
		if(grid[i][column] > 0)
		{
			lowestchip = i-1;
		}
		else{
			break;
		}
	}

	for(i = 0; i < lowestchip; i++)
	{
		startTimerOneshot(&ledOn, (uint32_t) (DROPTIME*i), column, i, player);
		startTimerOneshot(&ledOff, (uint32_t) (DROPTIME+DROPTIME*i), column, i, player);
	}
	if(lowestchip >= 0)
	{
		startTimerOneshot(&ledOn, (uint32_t) (DROPTIME*lowestchip), column, lowestchip, player);
		grid[lowestchip][column] = player;
		startTimerOneshot(&connect_four, (uint32_t) (DROPTIME*(lowestchip+1)), player, column, lowestchip);
	}
}



void ledOff(int column, int row, int player)
{
	int ledNum = get_ledNum(row, column); //Calculate using column, row

	set_led(ledNum, 0,0,0);
}

void ledToggle(int column, int row, int player)
{
	int ledNum = get_ledNum(row, column);
	if(player == 1)//red
	{
		if(grid[row][column] == 1) {
			grid[row][column] = 0;
			set_led(ledNum, 0, 0, 0);
		}
		else {
			grid[row][column] = 1;
			set_led(ledNum, 255, 0, 0);
		}
	}
	if(player == 2)//blue
	{
		if(grid[row][column] == 2) {
			grid[row][column] = 0;
			set_led(ledNum, 0, 0, 0);
		}
		else {
			grid[row][column] = 2;
			set_led(ledNum, 0, 0, 255);
		}
	}
}

int get_ledNum(int row, int column)
{
	int ledNum = 0; //Calculate using column, row
	if(column == 0)
	{
		ledNum = 4 - row;
	}
	else if(column == 1)
	{
		ledNum = 5 + row;
	}
	else if(column == 2)
	{
		ledNum = 14 - row;
	}
	else if(column == 3)
	{
		ledNum = 15 + row;
	}
	else if(column == 4)
	{
		ledNum = 24 - row;
	}
	else if(column == 5)
	{
		ledNum = 25 + row;
	}
	return ledNum;
}

void connect_four(int player, int column, int row)
{
	int winX = row;
	int winY = column;
	int type = 0; //1 = row, 2 = col, 3 = diagleft, 4 = diagright
	//row check
	int i;
	for(i = 0; i < 3; i++) {
		if(grid[row][i] == player && grid[row][i+1] == player && grid[row][i+2] == player && grid[row][i+3] == player) {
			winY = i;
			type = 1;
			break;
		}
	}
	//column check
	if(type == 0) {
		for(i = 0; i < 2; i++) {
			if(grid[i][column] == player && grid[i+1][column] == player && grid[i+2][column] == player && grid[i+3][column] == player) {
				winX = i;
				type = 2;
				break;
			}
		}
	}
	//diag left-down
	if(type == 0) {
		int connectCount = 1;
		int i = row;
		int j = column;
		//look down-right
		while(i != 4 && j != 5) {
			if(grid[i+1][j+1] == player) {
				connectCount += 1;
			}
			else {
				break;
			}
			i++;
			j++;
		}
		i = row;
		j = column;
		//look up-left
		while(i != 0 && j != 0) {
			if(grid[i-1][j-1] == player) {
				connectCount += 1;
				winX = i-1;
				winY = j-1;
			}
			else {
				break;
			}
			i--;
			j--;
		}
		if(connectCount >= 4) {
			type = 3;
		}
	}
	//diag up-right
	if(type == 0) {
		int connectCount = 1;
		int i = row;
		int j = column;
		winX = row;
		winY = column;
		//look up-right
		while(i != 0 && j != 5) {
			if(grid[i-1][j+1] == player) {
				connectCount += 1;
			}
			else {
				break;
			}
			i--;
			j++;
		}
		i = row;
		j = column;
		//look down-left
		while(i != 4 && j != 0) {
			if(grid[i+1][j-1] == player) {
				connectCount += 1;
				winX = i+1;
				winY = j-1;
			}
			else {
				break;
			}
			i++;
			j--;
		}
		if(connectCount >= 4) {
			type = 4;
		}
	}
	if(type != 0) {
		//vga stuff
		//our stuff!
		//tell vga the winning player
		writeWin(player);
		won2 = 1;

		int i;
		if(type == 1)
		{
			for(i = 0; i < 4; i++) {
				startTimerContinuous(&ledToggle, (uint32_t) (DROPTIME * 2), winY+i, winX, player);
			}
		}
		else if (type == 2)
		{
			for(i = 0; i < 4; i++) {
				startTimerContinuous(&ledToggle, (uint32_t) (DROPTIME * 2), winY, winX+i, player);
			}
		}
		else if (type == 3)
		{
			for(i = 0; i < 4; i++) {
				startTimerContinuous(&ledToggle, (uint32_t) (DROPTIME * 2), winY+i, winX+i, player);
			}
		}
		else if (type == 4)
		{
			for(i = 0; i < 4; i++) {
				startTimerContinuous(&ledToggle, (uint32_t) (DROPTIME * 2), winY+i, winX-i, player);
			}
		}
	}
	if(get_won2() || get_won3())
	{
		startTimerOneshot(&reset_game, 10*100000000, 0, 0, 30);
	}
}

uint32_t scale(int stepVal)
{ //CHANGE ALL VALUES
	if(stepVal < 500)
	{
		return 0;
	}
	else if(stepVal >= 500 && stepVal < 1500)
	{
		return 1;
	}
	else if(stepVal >= 1500 && stepVal < 2500)
	{
		return 2;
	}
	else if(stepVal >= 2500 && stepVal < 3500)
	{
		return 3;
	}
	else if(stepVal >= 3500 && stepVal < 4500)
	{
		return 4;
	}
	else
	{
		return 5;
	}
}
int get_won2()
{
	return won2;
}

void set_won2(int val)
{
	won2 = val;
}
void reset_game(int a, int b, int numLed)
{
	curr_player = 1;
	set_won2(0);
	set_won3(0);
	reset_VGA();
	MSS_GPIO_set_output(MSS_GPIO_11, 1);
	MSS_GPIO_set_output(MSS_GPIO_12, 1);
	MSS_GPIO_set_output(MSS_GPIO_13, 1);
	MSS_GPIO_set_output(MSS_GPIO_14, 1);
	back_hit = 0;
	made_shot = 0;
	int i,j;
	for(i = 0; i<5; i++)
	{
		for(j = 0; j<6; j++)
		{
			grid[i][j] = 0;
		}
	}
	clear_list();
	clear_all(numLed);
}
