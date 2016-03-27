
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;                               kernel.asm
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;                                                     Forrest Yu, 2005
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

; ----------------------------------------------------------------------
; �������ӷ���:
; $ rm -f kernel.bin
; $ nasm -f elf -o kernel.o kernel.asm
; $ nasm -f elf -o string.o string.asm
; $ nasm -f elf -o klib.o klib.asm
; $ gcc -c -o start.o start.c
; $ ld -s -Ttext 0x30400 -o kernel.bin kernel.o string.o start.o klib.o
; $ rm -f kernel.o string.o start.o
; $ 
; ----------------------------------------------------------------------


; ���뺯��
extern	Initialization
extern  init_prot
extern	kernel_main
extern	Delay

; ����ȫ�ֱ���
extern	gdt_ptr
extern  idt_ptr
extern	p_proc_ready
extern	tss
 



[SECTION .bss]
StackSpace		resb	2 * 1024
StackTop:		; ջ��


[section .text]	; �����ڴ�

global _start	; ���� _start
global restart

_start:
	; ��ʱ�ڴ濴��ȥ�������ģ�����ϸ���ڴ������ LOADER.ASM ����˵������
	;              ��                                    ��
	;              ��                 ...                ��
	;              �ǩ�������������������������������������
	;              ��������������Page  Tables��������������
	;              ������������(��С��LOADER����)���������� PageTblBase
	;    00101000h �ǩ�������������������������������������
	;              ����������Page Directory Table���������� PageDirBase = 1M
	;    00100000h �ǩ�������������������������������������
	;              ���������� Hardware  Reserved ���������� B8000h �� gs
	;       9FC00h �ǩ�������������������������������������
	;              ����������������LOADER.BIN�������������� somewhere in LOADER �� esp
	;       90000h �ǩ�������������������������������������
	;              ����������������KERNEL.BIN��������������
	;       80000h �ǩ�������������������������������������
	;              ������������������KERNEL���������������� 30400h �� KERNEL ��� (KernelEntryPointPhyAddr)
	;       30000h �ǩ�������������������������������������
	;              ��                 ...                ��
	;              ��                                    ��
	;           0h ���������������������������������������� �� cs, ds, es, fs, ss
	;
	;
	; GDT �Լ���Ӧ���������������ģ�
	;
	;		              Descriptors               Selectors
	;              ����������������������������������������
	;              ��         Dummy Descriptor           ��
	;              �ǩ�������������������������������������
	;              ��         DESC_FLAT_C    (0��4G)     ��   8h = cs
	;              �ǩ�������������������������������������
	;              ��         DESC_FLAT_RW   (0��4G)     ��  10h = ds, es, fs, ss
	;              �ǩ�������������������������������������
	;              ��         DESC_VIDEO                 ��  1Bh = gs
	;              ����������������������������������������
	;
	; ע��! ��ʹ�� C �����ʱ��һ��Ҫ��֤ ds, es, ss �⼸���μĴ�����ֵ��һ����
	; ��Ϊ�������п��ܱ����ʹ�����ǵĴ���, ��������Ĭ��������һ����. ���紮�����������õ� ds �� es.
	;
	;


	; �� esp �� LOADER Ų�� KERNEL
	mov	esp, StackTop	; ��ջ�� bss ����

	sgdt	[gdt_ptr]	; cstart() �н����õ� gdt_ptr
	call	Initialization		; �ڴ˺����иı���gdt_ptr������ָ���µ�GDT
	lgdt	[gdt_ptr]	; ʹ���µ�GDT

	lidt	[idt_ptr]

	;call    init_prot	���ô˺����������γ�ʼ��8259A�Ӷ�ʹ���õ�ISRʧЧ

	jmp	SELECTOR_KERNEL_CS:csinit
csinit:		; �������תָ��ǿ��ʹ�øոճ�ʼ���Ľṹ������<<OS:D&I 2nd>> P90.
	
	
	xor	eax, eax
	mov	ax, SELECTOR_TSS
	ltr	ax	;ִ��LTRָ��ó�ʼ����ģʽ����Ķ�ѡ������߿�д�ڴ�����Ķ���������������Ĵ���TR�������д�ڴ����������������л�ʱ��������TSS��Ϣ��

	jmp	kernel_main


%include "sconst.inc"
; ====================================================================================
;                                   restart
; ====================================================================================
restart:
	mov	esp, [p_proc_ready]
	lldt	[esp + P_LDT_SEL] 
	lea	eax, [esp + P_STACKTOP]
	mov	dword [tss + TSS3_S_SP0], eax

	pop	gs
	pop	fs
	pop	es
	pop	ds
	popad

	add	esp, 4
	iretd
