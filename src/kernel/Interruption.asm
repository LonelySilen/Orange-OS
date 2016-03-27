; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;                               Interruption.asm
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;															Oscar 2013.2
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
[SECTION .bss]
StackSpace		resb	2 * 1024
StackTop:		; ջ��
[SECTION .text]

%include "sconst.inc"

extern	p_proc_ready
extern	tss
extern	k_reenter
extern	ClockHandler
extern	irq_table
extern  sys_call_table

; ��������
global  hwint00
global  hwint01
global  hwint02
global  hwint03
global  hwint04
global  hwint05
global  hwint06
global  hwint07
global  hwint08
global  hwint09
global  hwint10
global  hwint11
global  hwint12
global  hwint13
global  hwint14
global  hwint15

global  sys_call

; �жϺ��쳣 -- Ӳ���ж�
; ---------------------------------
%macro  hwint_master    1
		call	save
		in		al, 21h 
		or		al, (1 << %1)
		out		21h, al
		mov		al, 20h			; EOI
		out		20h, al
		sti
        push    %1
        call    [irq_table + 4 * %1]
		pop		ecx
		cli
		in		al, 21h 
		and		al, ~(1 << %1)
		out		21h, al
		ret									; ����ʱ��ת��.restart_reenter,��Ϊ.1��.restart_reenterѹջ

%endmacro
; ---------------------------------

sys_call:
		call	save
		push	dword [p_proc_ready]		  ; ����ǰ����ָ�봫�ݸ�sys_write
		sti
		push	edx
		push	ecx
		push	ebx

		call	[sys_call_table + eax * 4]
		add		esp, 4*4
		mov		[esi + EAXREG - P_STACKBASE], eax
		cli
		ret
save:
		pushad
		push	ds
		push	es
		push	fs
		push	gs
							   ; ֱ���л��ں�ջ֮ǰ����ʹ��push popָ����ƻ����̱�����ʹ��edx���ݲ���

		mov		esi, edx      ; ����edx��ϵͳ���ý�ʹ��edx���ݲ���

		mov		dx, ss
		mov		ds, dx
		mov		es, dx

		mov		edx, esi		; �ָ�edx

		mov		esi, esp			; esi���̱���ʼ��ַ	 eaxҪ����ϵͳ���õĲ���
		inc		dword[k_reenter]			; �ж�ȫ�ֱ���k_reenter��ֵ����ֹ�ж�����ʹ��ջ���
		cmp		dword[k_reenter], 0
		jne		.1
		mov		esp, StackTop		; �л����ں�ջ
		push	.restart
		jmp		[esi + RETADR - P_STACKBASE]
.1:
		push	.restart_reenter
		jmp		[esi + RETADR - P_STACKBASE]
.restart:
		mov		esp, [p_proc_ready]	; �뿪�ں�ջ
		lldt	[esp + P_LDT_SEL]				; �����л�ʱҪ���¼���ldt
		lea		esi, [esp + P_STACKTOP]
		mov		dword[tss + TSS3_S_SP0], esi				; ��ֵtss.esp0
.restart_reenter:
		dec		dword[k_reenter]				; ֮ǰ©д��䵼���жϴ������ֻ��ִ��һ��
		pop		gs
		pop		fs
		pop		es
		pop		ds
		popad
		add		esp, 4
		iretd

ALIGN   16
hwint00:                ; Interrupt routine for irq 0 (the clock).
		hwint_master    0

ALIGN   16
hwint01:                ; Interrupt routine for irq 1 (keyboard)
		hwint_master    1

ALIGN   16
hwint02:                ; Interrupt routine for irq 2 (cascade!)
        hwint_master    2

ALIGN   16
hwint03:                ; Interrupt routine for irq 3 (second serial)
        hwint_master    3

ALIGN   16
hwint04:                ; Interrupt routine for irq 4 (first serial)
        hwint_master    4

ALIGN   16
hwint05:                ; Interrupt routine for irq 5 (XT winchester)
        hwint_master    5

ALIGN   16
hwint06:                ; Interrupt routine for irq 6 (floppy)
        hwint_master    6

ALIGN   16
hwint07:                ; Interrupt routine for irq 7 (printer)
        hwint_master    7

; ---------------------------------
%macro  hwint_slave     1
        call	save
		in		al, 0A1h 
		or		al, (1 << %1)
		out		0A1h, al
		mov		al, 20h			; EOI
		out		20h,  al		;��ƬEOI
		out		0A0h, al		;��ƬEOI
		sti
        push    %1
        call    [irq_table + 4 * %1]
		pop		ecx
		cli
		in		al, 0A1h 
		and		al, ~(1 << %1)
		out		0A1h, al
		ret									; ����ʱ��ת��.restart_reenter,��Ϊ.1��.restart_reenterѹջ
%endmacro
; ---------------------------------

ALIGN   16
hwint08:                ; Interrupt routine for irq 8 (realtime clock).
        hwint_slave     8

ALIGN   16
hwint09:                ; Interrupt routine for irq 9 (irq 2 redirected)
        hwint_slave     9

ALIGN   16
hwint10:                ; Interrupt routine for irq 10
        hwint_slave     10

ALIGN   16
hwint11:                ; Interrupt routine for irq 11
        hwint_slave     11

ALIGN   16
hwint12:                ; Interrupt routine for irq 12
        hwint_slave     12

ALIGN   16
hwint13:                ; Interrupt routine for irq 13 (FPU exception)
        hwint_slave     13

ALIGN   16
hwint14:                ; Interrupt routine for irq 14 (AT winchester)
        hwint_slave     14

ALIGN   16
hwint15:                ; Interrupt routine for irq 15
        hwint_slave     15


