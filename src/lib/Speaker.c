
/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Speaker.c
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Oscar 2013
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

#include "type.h"
#include "const.h"
#include "protect.h"
#include "proc.h"					//���Ҫ������proto.h֮ǰ����proto��ĳЩ���岻ʶ��
#include "proto.h"
#include "global.h"

void Speaker(u16 frequency,u16 duration)
{
	MESSAGE msg;
	reset_msg(&msg);
	msg.type = BEEP_ON;
	msg.u.m1.m1i1 = frequency;
	send_recv(BOTH, TASK_SYS, &msg);
	Delay(duration);
	msg.type = BEEP_OFF;
	send_recv(BOTH, TASK_SYS, &msg);
}
