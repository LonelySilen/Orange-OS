
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;                              STI_CLI.asm
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;                                                       Oscar, 2013
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
[SECTION .text]
; ��������
global	EnableInterruption
global  DisableInterruption

EnableInterruption:
	sti
	ret
DisableInterruption:
	cli
	ret
