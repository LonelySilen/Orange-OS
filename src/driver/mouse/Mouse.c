
/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Mouse.c
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Oscar 2013
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

#include "type.h"
#include "const.h"
#include "protect.h"
#include "proc.h"					//���Ҫ������proto.h֮ǰ����proto��ĳЩ���岻ʶ��
#include "proto.h"
#include "global.h"
#include "Mouse.h"

MouseData Mouse_Data;
void InitMouse()
{
	Out_Byte(0x64,0xa8);// ���� ��� �ӿ� 
	Out_Byte(0x64,0xd4);// ֪ͨ 8042 �¸��ֽڵķ��� 0x60 �����ݽ����� ���
	Out_Byte(0x60,0xf4);// ���� ��� ������
	Out_Byte(0x64,0x60);// ֪ͨ 8042,�¸��ֽڵķ��� 0x60 ������Ӧ���� 8042 ������Ĵ���
	Out_Byte(0x60,0x47);// ��ɼ��̼� ��� �ӿڼ��ж�
}

void MouseHandler()
{
	static int NoMousePackage;	// �˱���������¼���ǵڼ������ݰ��� ��Ϊ ��� ������ÿ�����ݰ� ��������һ���ж�

	static int SignX;
	static int SignY;
	static int SignZ;
	
	char PackageData;
	
	PackageData = In_Byte(0x60);
	switch(NoMousePackage ++)
	{
		case 0:
			Mouse_Data.LeftButton = PackageData & 0x01 ? 1:0;
			Mouse_Data.RightButton = PackageData & 0x02 ? 1:0;
			Mouse_Data.MidButton = PackageData & 0x04 ? 1:0;
			SignX = PackageData & 0x10 ? 0xffffff00:0;
			SignY = PackageData & 0x20 ? 0xffffff00:0;
			break;
		case 1:
			Mouse_Data.PositionX += (PackageData | SignX);
			break;
		case 2:
			Mouse_Data.PositionY += (PackageData | SignY);
			NoMousePackage = 0;				// 2D��꣬3D�����ע�͵������
			DrawPointVRAM(Mouse_Data.PositionX,Mouse_Data.PositionY,0xffffffff);
			break;
		case 3:
			SignZ = PackageData & 0x08 ? 0xffffff00:0;
			Mouse_Data.MidWheel +=(PackageData | SignZ);
			NoMousePackage = 0;
			break;
	}
	
}



