#include "type.h"
#include "const.h"
#include "protect.h"
#include "proc.h"					//���Ҫ������proto.h֮ǰ����proto��ĳЩ���岻ʶ��
#include "proto.h"
#include "global.h"

PUBLIC void Init8253()
{
	/* ��ʼ�� 8253 PIT */
    Out_Byte(TIMER_MODE, RATE_GENERATOR);
    Out_Byte(TIMER0, (u8) (TIMER_FREQ/Hz) );
    Out_Byte(TIMER0, (u8) ((TIMER_FREQ/Hz) >> 8));
}