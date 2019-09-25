/*
 * neopixels.h
 *
 *  Created on: Nov 28, 2018
 *      Author: shribha
 */

#ifndef NEOPIXELS_H_
#define NEOPIXELS_H_

extern const int DROPTIME;
extern int grid[5][6];
extern int curr_player;
extern int back_hit;
extern int made_shot;


void set_led(uint32_t, uint32_t, uint32_t, uint32_t);
void clear_all(uint32_t);
void set_ledhex(uint32_t, uint32_t);
void drop_chip(uint32_t, int);
void ledOn(int, int, int);
void ledOff(int, int, int);
void ledToggle(int,int,int);
int get_ledNum(int, int);
void connect_four();
uint32_t scale(int);
int get_won2();
void set_won2(int);
void reset_game();

#endif /* NEOPIXELS_H_ */
