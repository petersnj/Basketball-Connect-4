/*
 * vgacontrol.c
 *
 *  Created on: Nov 28, 2018
 *      Author: shribha
 */
#define PLAYER1 0x40050104
#define PLAYER2 0x40050108
#define PLAY 0x40050114
#define WIN 0x40050118

#include "vgacontrol.h"
#include "mss_gpio.h"
//#include "linklist.h"

int won3 = 0;
//never give score above 9 or out of bounds
void inc_score(int player) {
	volatile int *p1addr = (int *) PLAYER1;
	volatile int *p2addr = (int *) PLAYER2;
	int score;
	if(player == 1) {
		score = *p1addr;
		if(score < 14){
			*p1addr = score+1;
		}
		else{
			*p1addr = 0;
			writeWin(player);
			won3 = 1;
			//startTimerOneshot(&reset_game, 10*100000000, 0, 0, 30);
		}
	}
	else if(player == 2) {
		score = *p2addr;
		if(score < 14) {
			*p2addr = score+1;
		} else {
			*p2addr = 0;
			writeWin(player);
			won3 = 1;
			//startTimerOneshot(&reset_game, 10*100000000, 0, 0, 30);
		}
	}
}

void clear_scores() {
	volatile int *p1addr = (int *) PLAYER1;
	volatile int *p2addr = (int *) PLAYER2;
	*p1addr = 0;
	*p2addr = 0;
}

//PLAYER is ONE or TWO, NOT ZERO!!!!!!!
void set_player(int player) {
	volatile int *whichplayer = (int *) PLAY;
	*whichplayer = player-1;
}

int get_score(int player)
{
	volatile int *p1addr = (int *) PLAYER1;
	volatile int *p2addr = (int *) PLAYER2;
	if(player == 1)
	{
		return *p1addr;
	}
	else
	{
		return *p2addr;
	}
}

void writeWin(int player) {
	int * winAddr = (int*) WIN;
	*winAddr = player;
	if(player > 0)
	{
		MSS_GPIO_set_output(MSS_GPIO_11, 0);
	}
}

void reset_VGA()
{
	writeWin(0);
	clear_scores();
	set_player(1);
}
int get_won3()
{
	return won3;
}

void set_won3(int val)
{
	won3 = val;
}
