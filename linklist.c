//use MSS hardware timer1 @100MHz and GPIO mapped to LEDS

#include "mss_timer.h"
#include "mss_gpio.h"
#include "stdlib.h"
#include "linklist.h"

timer_t *root = NULL;


//remove the head node
void removeHead(timer_t **pp) {
	if(*pp == NULL) {
		return;
	}
	if((*pp)->next == NULL)
	{
		timer_t *temp = *pp;
		*pp = NULL;
		free(temp);
		return;
	}
	timer_t *temp = *pp;
	*pp = (*pp)->next;
	free(temp);
}

void sort(timer_t** pp)
{
    int swapped;
    timer_t *ptr1;
    timer_t *lptr = NULL;

    /* Checking for empty list */
    if (*pp == NULL)
        return;

    do
    {
        swapped = 0;
        ptr1 = *pp;

        while (ptr1->next != lptr)
        {
            if (ptr1->time > ptr1->next->time)
            {
                swap(ptr1, (ptr1->next));
                swapped = 1;
            }
            ptr1 = ptr1->next;
        }
        lptr = ptr1;
    }
    while (swapped);
}

void swap(timer_t *lhs, timer_t *rhs) {
	uint32_t time = lhs->time;
	lhs->time = rhs->time;
	rhs->time = time;
	uint32_t period = lhs->period;
	lhs->period = rhs->period;
	rhs->period = period;
	uint32_t mode = lhs->mode;
	lhs->mode = rhs->mode;
	rhs->mode = mode;

	int arg1 = lhs->arg1;
	lhs->arg1 = rhs->arg1;
	rhs->arg1 = arg1;
	int arg2 = lhs->arg2;
	lhs->arg2 = rhs->arg2;
	rhs->arg2 = arg2;
	int arg3 = lhs->arg3;
	lhs->arg3 = rhs->arg3;
	rhs->arg3 = arg3;

	handler_t handler = lhs->handler;
	lhs->handler = rhs->handler;
	rhs->handler = handler;
}

void insert(timer_t **pp,timer_t* new_node)
{
	new_node->next = *pp;
	*pp = new_node;
	sort(pp);
}


void update_timers(timer_t **pp){
	if(*pp == NULL) {
		return;
	}
	//timer_t *headtemp = *pp;
	(*pp)->handler((*pp)->arg1, (*pp)->arg2, (*pp)->arg3);
	timer_t *tempnode = malloc(sizeof(timer_t));
	tempnode->mode = (*pp)->mode;
	tempnode->handler = (*pp)->handler;
	tempnode->period = (*pp)->period;
	tempnode->time = (*pp)->time;
	tempnode->next = (*pp)->next;
	tempnode->arg1 = (*pp)->arg1;
	tempnode->arg2 = (*pp)->arg2;
	tempnode->arg3 = (*pp)->arg3;
	removeHead(pp);

	uint32_t val = tempnode->time;

	timer_t *temp = *pp;
	if(temp != NULL) {
		while(temp->next != NULL) {
			if(temp->time >= val)
				temp->time -= val;
			temp = temp->next;
		}
		if(temp->time >= val)
			temp->time -= val;
	}
	if((*pp)->time == 0) update_timers(pp);
	if(!(tempnode->mode))
	{
		startTimerContinuous(tempnode->handler, tempnode->period, tempnode->arg1, tempnode->arg2, tempnode->arg3);
	}

	free(tempnode);

}


void startTimerContinuous(handler_t handler, uint32_t period, int arg1, int arg2, int arg3)
{
	timer_t *timer = malloc(sizeof(timer_t));
	timer->handler = handler;
	timer->period = period;
	timer->time = period;
	timer->arg1 = arg1;
	timer->arg2 = arg2;
	timer->arg3 = arg3;
	timer->mode = 0; //one is one-shot, zero is continuous
	insert(&root, timer);
}

void startTimerOneshot(handler_t handler, uint32_t period, int arg1, int arg2, int arg3){
	timer_t *timer = malloc(sizeof(timer_t));
	timer->handler = handler;
	timer->period = period;
	timer->time = period;
	timer->arg1 = arg1;
	timer->arg2 = arg2;
	timer->arg3 = arg3;
	timer->mode = 1; //one is one-shot, zero is continuous
	insert(&root, timer);
}

//look in mss_timer.h for details
void start_hardware_timer(uint32_t period){

	MSS_TIM1_init(MSS_TIMER_ONE_SHOT_MODE);
	MSS_TIM1_load_immediate(period);
	MSS_TIM1_start();
	MSS_TIM1_enable_irq();
}

//hardware timer down counting at 100MHz
//should interrupt once a second.
void Timer1_IRQHandler( void ){
	MSS_TIM1_clear_irq();
	sort(&root);
	update_timers(&root);
	sort(&root);
	MSS_TIM1_load_immediate(root->time);
	MSS_TIM1_start();
}

void clear_list()
{
	int length = 0;
	timer_t* temp = root;
	while(temp->next)
	{
		length++;
		temp = temp->next;
	}
	int i;
	for(i=0; i<=length; i++)
	{
		removeHead(&root);
	}
}
