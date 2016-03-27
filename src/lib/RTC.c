
/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
RTC.c
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Oscar 2013
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

#include "type.h"
#include "const.h"
#include "protect.h"
#include "proc.h"					//���Ҫ������proto.h֮ǰ����proto��ĳЩ���岻ʶ��
#include "proto.h"
#include "global.h"

/***********************************************************************/
/*Ring 1
/*Request RTC time from CMOS,called when system initialized

/***********************************************************************/
void GetCurrentTime(Time * time)
{
	unsigned int temp;
	Out_Byte(0x70,0x80|0x00);//��
	temp = In_Byte(0x71);
	time->second = (temp&0x0F) + (temp>>4)*10;   //BCDתʮ����	+�����ȼ���&�ߣ�
	
	Out_Byte(0x70,0x80|0x02);//��
	temp = In_Byte(0x71);
	time->minite = (temp&0x0F) + (temp>>4)*10;  //BCDתʮ����
	
	Out_Byte(0x70,0x80|0x04);//ʱ
	temp = In_Byte(0x71);
	time->hour = (temp&0x0F) + (temp>>4)*10;   //BCDתʮ����
	
	Out_Byte(0x70,0x80|0x07);//��
	temp = In_Byte(0x71);
	time->day = (temp&0x0F) + (temp>>4)*10;   //BCDתʮ����
	
	Out_Byte(0x70,0x80|0x08);//��
	temp = In_Byte(0x71);
	time->month = (temp&0x0F) + (temp>>4)*10;   //BCDתʮ����
	
	Out_Byte(0x70,0x80|0x09);//��
	temp = In_Byte(0x71);
	time->year = (temp&0x0F) + (temp>>4)*10;   //BCDתʮ����
	
	Out_Byte(0x70,0x80|0x06);//����
	temp = In_Byte(0x71);
	time->week = (temp&0x0F) + (temp>>4)*10;   //BCDתʮ����
	
}