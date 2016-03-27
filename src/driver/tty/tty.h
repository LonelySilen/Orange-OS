
#ifndef _ORANGES_TTY_H_
#define _ORANGES_TTY_H_


#define TTY_IN_BYTES	256	/* tty input queue size */

#define SCR_SIZE		(80 * 25)
#define SCR_WIDTH		80


/* CONSOLE */
typedef struct s_console
{
	int	window_size_limit;		/* ��ǰ����̨ռ���Դ��С */
	int window_len;
	int window_wid;
	int	cursor;					/* ��ǰ���λ�ã����أ� */
	
	char 	char_buf[20000];		/* TTY �ַ������� */
	int  	char_current_pos;		/* ��ǰ�ַ�λ��   */
	int	char_count;					/* �ַ����� */
	int	char_current_line;			/* ��ǰ��ʾ�� */
	int	char_start_line;			/* ��ʼ�� */
	
	int	gralayer1;			//TTYͼ��һ��������
	int	gralayer2;			//TTYͼ��������֣�
	
}CONSOLE;


/* TTY */
typedef struct s_tty
{
	int	in_buf[TTY_IN_BYTES];	/* TTY ���뻺���� */
	int*	p_inbuf_head;		/* ָ�򻺳�������һ������λ�� */
	int*	p_inbuf_tail;		/* ָ���������Ӧ����ļ�ֵ */
	int	inbuf_count;			/* ���������Ѿ�����˶��� */
	
	
	
	struct s_console *	p_console;
}TTY;


#endif /* _ORANGES_TTY_H_ */
