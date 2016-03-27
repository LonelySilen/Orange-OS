
/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Interruption.c
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Oscar 2013
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

#include "type.h"
#include "const.h"
#include "protect.h"
#include "proc.h"					//���Ҫ������proto.h֮ǰ����proto��ĳЩ���岻ʶ��
#include "proto.h"
#include "global.h"

char ClockTimes = 0;
int KeyPressedTimes = 1;
int ClockTick = 0;



PUBLIC void TimeHandler();

PUBLIC void SetIRQHandler(int irq,irq_handler handler)
{
	Disable_IRQ(irq);
	irq_table[irq] = handler;
	Enable_IRQ(irq);
}
/*======================================================================*
DefaultIRQHandler
*======================================================================*/
PUBLIC void DefaultHandler(int irq)
{
	char * int_msg[] = 
	{
		"Interrupt routine for irq 0 (the clock).\n",
		"Interrupt routine for irq 1 (keyboard).\n",
		"Interrupt routine for irq 2 (cascade!).\n",
		"Interrupt routine for irq 3 (second serial).\n",
		"Interrupt routine for irq 4 (first serial).\n",
		"Interrupt routine for irq 5 (XT winchester).\n",
		"Interrupt routine for irq 6 (floppy).\n",
		"Interrupt routine for irq 7 (printer).\n",
		"Interrupt routine for irq 8 (realtime clock).\n",
		"Interrupt routine for irq 9 (irq 2 redirected).\n",
		"Interrupt routine for irq 10.\n",
		"Interrupt routine for irq 11.\n",
		"Interrupt routine for irq 12.\n",
		"Interrupt routine for irq 13 (FPU exception).\n",
		"Interrupt routine for irq 14 (AT winchester).\n",
		"Interrupt routine for irq 15.\n",
	};
	//PrintStrPos(int_msg[irq],BlueScreenWord,1000,0);
	return;
}
PUBLIC void ClockHandler(int irq)					//���̵����㷨�����޸Ĵ˺�����ʵ��
{
	TimeHandler();
	ticks ++;
	p_proc_ready->ticks --;
	if(k_reenter != 0);
	else
	{
		if(p_proc_ready->ticks > 0)			/*ticks��Ϊ0֮ǰ������������������*/
			return;				
		Schedule();
	}
}

PUBLIC void TimeHandler()
{
	ClockTick++;
	if(ClockTick%Hz == 0)
	{
		systime.second++;
		if(systime.second >= 60)
		{
			systime.second = 0;
			systime.minite ++;
		}
		if(systime.minite >= 60)
		{
			systime.minite = 0;
			systime.hour ++;
		}
		if(systime.hour >= 24)
		{
			systime.hour = 0;
			GetCurrentTime(&systime);		//����24Сʱ�����¶�ȡCMOSʱ�䣬�Ա��ⷱ�ӵ����ڴ���
		}
	}
}
PUBLIC void SetIRQ()
{
	int i;
	for(i = 0 ; i < NR_IRQ ; i++ )
		irq_table[i] = DefaultHandler;			//��ȫ������ΪĬ�ϵĴ������
	/*���������жϴ�����*/
	//SetIRQHandler(0,ClockHandler);
	SetIRQHandler(1,KeyboardHandler);
	SetIRQHandler(8,TimeHandler);
	SetIRQHandler(12,MouseHandler);
	SetIRQHandler(AT_WINI_IRQ, HDHandler);

}
