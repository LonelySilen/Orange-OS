
#ifndef _ORANGES_TTY_H_
#define _ORANGES_TTY_H_


#define TTY_IN_BYTES	256	/* tty input queue size */

#define SCR_SIZE		(80 * 25)
#define SCR_WIDTH		80

#define DEFAULT_CHAR_COLOR	(MAKE_COLOR(BLACK, WHITE))
#define GRAY_CHAR		(MAKE_COLOR(BLACK, BLACK) | BRIGHT)
#define RED_CHAR		(MAKE_COLOR(BLUE, RED) | BRIGHT)

/* CONSOLE */
typedef struct s_console
{
	unsigned int	current_start_addr;	/* ��ǰ��ʾ����ʲôλ��	  */
	unsigned int	original_addr;		/* ��ǰ����̨��Ӧ�Դ�λ�� */
	unsigned int	v_mem_limit;		/* ��ǰ����̨ռ���Դ��С */
	unsigned int	cursor;			/* ��ǰ���λ�� */
}CONSOLE;


#define DEFAULT_CHAR_COLOR	0x07	/* 0000 0111 �ڵװ��� */

/* TTY */
typedef struct s_tty
{
	u32	in_buf[TTY_IN_BYTES];	/* TTY ���뻺���� */
	u32*	p_inbuf_head;		/* ָ�򻺳�������һ������λ�� */
	u32*	p_inbuf_tail;		/* ָ���������Ӧ����ļ�ֵ */
	int	inbuf_count;		/* ���������Ѿ�����˶��� */

	struct s_console *	p_console;
}TTY;


#endif /* _ORANGES_TTY_H_ */
