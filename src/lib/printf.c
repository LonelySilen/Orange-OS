#include "type.h"
#include "const.h"
#include "protect.h"
#include "proc.h"					//���Ҫ������proto.h֮ǰ����proto��ĳЩ���岻ʶ��
#include "proto.h"
#include "global.h"

/******************************************************************************************
                        �ɱ������������ԭ�������漰�����ֽ�Ϊ������
===========================================================================================

i = 0x23;
j = 0x78;
char fmt[] = "%x%d";
printf(fmt, i, j);

        push    j
        push    i
        push    fmt
        call    printf
        add     esp, 3 * 4


                ��        HIGH        ��                        ��        HIGH        ��
                ��        ...         ��                        ��        ...         ��
                �ǩ���������������������                        �ǩ���������������������
                ��                    ��                 0x32010��        '\0'        ��
                �ǩ���������������������                        �ǩ���������������������
         0x3046C��        0x78        ��                 0x3200c��         d          ��
                �ǩ���������������������                        �ǩ���������������������
   arg = 0x30468��        0x23        ��                 0x32008��         %          ��
                �ǩ���������������������                        �ǩ���������������������
         0x30464��      0x32000 �������橤��������       0x32004��         x          ��
                �ǩ���������������������        ��              �ǩ���������������������
                ��                    ��        �������� 0x32000��         %          ��
                �ǩ���������������������                        �ǩ���������������������
                ��        ...         ��                        ��        ...         ��
                ��        LOW         ��                        ��        LOW         ��

ʵ���ϣ����� vsprintf �������������ģ�

        vsprintf(buf, 0x32000, 0x30468);

******************************************************************************************/

/*======================================================================*
                                 printf
 *======================================================================*/
int printf(const char *fmt, ...)
{
	int i;
	char buf[256];

	va_list arg = (va_list)((char*)(&fmt) + 4); /*4�ǲ���fmt��ռ��ջ�еĴ�С*/
	i = vsprintf(buf, fmt, arg);
	buf[i] = 0;
	printx(buf);

	return i;
}
/*======================================================================*
                                i2a
 *======================================================================*/
PRIVATE char* i2a(unsigned int val, int base, char ** ps)
{
	int m = val % base;
	int q = val / base;
	if (q) {
		i2a(q, base, ps);
	}
	*(*ps)++ = (m < 10) ? (m + '0') : (m - 10 + 'A');

	return *ps;
}


/*======================================================================*
                                vsprintf
 *======================================================================*/
/*
 *  Ϊ���õ����˺�����ԭ���ɲο� printf ��ע�Ͳ��֡�
 */
PUBLIC int vsprintf(char *buf, const char *fmt, va_list args)
{
	char*	p;

	va_list	p_next_arg = args;
	int	m;

	char	inner_buf[STR_DEFAULT_LEN];
	char	cs;
	int	align_nr;

	for (p=buf;*fmt;fmt++) {
		if (*fmt != '%') {
			*p++ = *fmt;
			continue;
		}
		else {		/* a format string begins */
			align_nr = 0;
		}

		fmt++;

		if (*fmt == '%') {
			*p++ = *fmt;
			continue;
		}
		else if (*fmt == '0') {
			cs = '0';
			fmt++;
		}
		else {
			cs = ' ';
		}
		while (((unsigned char)(*fmt) >= '0') && ((unsigned char)(*fmt) <= '9')) {
			align_nr *= 10;
			align_nr += *fmt - '0';
			fmt++;
		}

		char * q = inner_buf;
		memset(q, 0, sizeof(inner_buf));

		switch (*fmt) {
		case 'c':
			*q++ = *((char*)p_next_arg);
			p_next_arg += 4;
			break;
		case 'x':
			m = *((int*)p_next_arg);
			i2a(m, 16, &q);
			p_next_arg += 4;
			break;
		case 'd':
			m = *((int*)p_next_arg);
			if (m < 0) {
				m = m * (-1);
				*q++ = '-';
			}
			i2a(m, 10, &q);
			p_next_arg += 4;
			break;
		case 's':
			strcpy(q, (*((char**)p_next_arg)));
			q += strlen(*((char**)p_next_arg));
			p_next_arg += 4;
			break;
		default:
			break;
		}

		int k;
		for (k = 0; k < ((align_nr > strlen(inner_buf)) ? (align_nr - strlen(inner_buf)) : 0); k++) {
			*p++ = cs;
		}
		q = inner_buf;
		while (*q) {
			*p++ = *q++;
		}
	}

	*p = 0;

	return (p - buf);
}


/*======================================================================*
                                 sprintf
 *======================================================================*/
int sprintf(char *buf, const char *fmt, ...)
{
	va_list arg = (va_list)((char*)(&fmt) + 4);        /* 4 �ǲ��� fmt ��ռ��ջ�еĴ�С */
	return vsprintf(buf, fmt, arg);
}
