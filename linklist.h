/*
 * linklist.h
 *
 *  Created on: Oct 16, 2018
 *      Author: shribha
 *
*/
#ifndef LINKLIST_H_
#define LINKLIST_H_



typedef void (*handler_t)(int a, int b, int c);


//structure holding virtual timer info
//this may vary depending on your implementation
typedef struct Timer {
    handler_t	handler;//function pointer (called after timer period)
    uint32_t	time;//time remaining for this counter
    uint32_t	period;//period
    uint32_t	mode;//continuous or one shot timer
    int			arg1; //arguments for handler function
    int			arg2;
    int			arg3;
    struct Timer*  next;//points to next timer
} timer_t;

extern timer_t *root;

//used to initialize hardware
void start_hardware_timer(uint32_t period);


//insert timer into linked list
void insert(timer_t **pp, timer_t* new_node);

//remove a specific node
void removeHead(timer_t **pp);

void swap(timer_t *lhs, timer_t *rhs);

//sort linked list function
void sort(timer_t **pp);


//add a continuous (periodic) timer to linked list.
void startTimerContinuous(handler_t handler, uint32_t period, int arg1, int arg2, int arg3);
//example
//startTimerContinuous(&led0, 50000000);

//add a one shot timer to the linked list.
void startTimerOneshot(handler_t handler, uint32_t period, int arg1, int arg2, int arg3);


//update down count with elapsed time, call fnc if timer zero, update continuous timers
//with new down count
void update_timers(timer_t **pp);

void clear_list();
#endif // LINKLIST_H_

