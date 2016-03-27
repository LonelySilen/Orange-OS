;******************************************************************************
; Loader.asm
; Oscar
; 2013.5
; ��LoaderĿǰֻ�ܼ���С��1M���ں�
;******************************************************************************
org  0100h

	jmp	LABEL_START		; Start

; ������ FAT12 ���̵�ͷ, ֮���԰���������Ϊ�����õ��˴��̵�һЩ��Ϣ
%include	"Fat32BPB.inc"
%include	"load.inc"
%include	"pm.inc"

; GDT
;                            �λ�ַ     �ν���, ����
LABEL_GDT:			Descriptor 0,            0, 0              ; ��������
LABEL_DESC_FLAT_C:  Descriptor 0,      0fffffh, DA_CR|DA_32|DA_LIMIT_4K ;0-4G
LABEL_DESC_FLAT_RW: Descriptor 0,      0fffffh, DA_DRW|DA_32|DA_LIMIT_4K;0-4G
LABEL_DESC_VIDEO:   Descriptor 0, 	   0fffffh, DA_DRW|DA_DPL3|DA_LIMIT_4K ; �Դ��׵�ַ

GdtLen		equ	$ - LABEL_GDT
GdtPtr		dw	GdtLen - 1				; �ν���
GdtAdd		dd	BaseOfLoaderPhyAddr + LABEL_GDT		; ����ַ

; GDT ѡ����
SelectorFlatC		equ	LABEL_DESC_FLAT_C	- LABEL_GDT
SelectorFlatRW		equ	LABEL_DESC_FLAT_RW	- LABEL_GDT
SelectorVideo		equ	LABEL_DESC_VIDEO	- LABEL_GDT + SA_RPL3

BaseOfStack	equ	0100h


LABEL_START:					; <--- �����￪ʼ *************

	mov	ax, cs
	mov	ds, ax
	mov	es, ax
	mov	ss, ax
	mov	sp, BaseOfStack

	mov	dh, 0					; "Loading  "
	call	DispStrRealMode		; ��ʾ�ַ���

	; �õ��ڴ���
	mov	ebx, 0					; ebx = ����ֵ, ��ʼʱ��Ϊ 0
	mov	di, _MemChkBuf			; es:di ָ��һ����ַ��Χ�������ṹ(ARDS)
.MemChkLoop:
	mov	eax, 0E820h				; eax = 0000E820h
	mov	ecx, 20					; ecx = ��ַ��Χ�������ṹ�Ĵ�С
	mov	edx, 0534D4150h			; edx = 'SMAP'
	int	15h						; int 15h
	jc	.MemChkFail
	add	di, 20
	inc	dword [_dwMCRNumber]	; dwMCRNumber = ARDS �ĸ���
	cmp	ebx, 0
	jne	.MemChkLoop
	jmp	.MemChkOK
.MemChkFail:
	mov	dword [_dwMCRNumber], 0
.MemChkOK:

	; ������ A �̵ĸ�Ŀ¼Ѱ�� KERNEL.BIN
	xor	ah, ah				; ��
	mov	dl, [BIOS_drive]	; �� Ӳ�̸�λ
	int	13h					; ��

	; ������ C �̵ĸ�Ŀ¼Ѱ�� KERNEL.BIN
	mov	word [wSectorNo], SectorNoOfRootDirectory
LABEL_SEARCH_IN_ROOT_DIR_BEGIN:
	cmp	word [wRootDirSizeForLoop], 0	; ��
	jz	LABEL_NO_LOADERBIN				; �� �жϸ�Ŀ¼���ǲ����Ѿ�����
	dec	word [wRootDirSizeForLoop]		; �� ��������ʾû���ҵ� LOADER.BIN
	mov	ax, BaseOfKernelFile
	mov	es, ax					; es <- BaseOfKernelFile
	mov	bx, OffsetOfKernelFile	; bx <- OffsetOfKernelFile
	mov	ax, [wSectorNo]			; ax <- Root Directory �е�ĳ Sector ��
	mov [BlockNum_L32],	ax
	mov [BufAddr_H16],es
	mov [BufAddr_L16],bx
	mov word[BlockCount],	1

	call	ReadSector

	mov	si, KernelFileName		; ds:si -> "KERNEL  BIN"
	mov	di, OffsetOfKernelFile	; es:di -> BaseOfLoader:0100 = BaseOfLoader*10h+100
	cld
	mov	dx, 80h								; ԭ�����������һ�������ģ�������Ӧ����һ����
LABEL_SEARCH_FOR_LOADERBIN:
	cmp	dx, 0								; ��ѭ����������
	jz	LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR	; ������Ѿ�������һ�� Sector,
	dec	dx									; ����������һ�� Sector
	mov	cx, 11
LABEL_CMP_FILENAME:
	cmp	cx, 0
	jz	LABEL_FILENAME_FOUND		; ����Ƚ��� 11 ���ַ������, ��ʾ�ҵ�
	dec	cx
	lodsb							; ds:si -> al
	cmp	al, byte [es:di]
	jz	LABEL_GO_ON
	jmp	LABEL_DIFFERENT				; ֻҪ���ֲ�һ�����ַ��ͱ����� DirectoryEntry ����
; ����Ҫ�ҵ� KERNEL.BIN
LABEL_GO_ON:
	inc	di
	jmp	LABEL_CMP_FILENAME			;	����ѭ��

LABEL_DIFFERENT:
	and	di, 0FFE0h					; else ��	di &= E0 Ϊ������ָ����Ŀ��ͷ
	add	di, 20h						;      ��
	mov	si, KernelFileName			;      �� di += 20h  ��һ��Ŀ¼��Ŀ
	jmp	LABEL_SEARCH_FOR_LOADERBIN	;      ��

LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR:
	add	word [wSectorNo], 1
	jmp	LABEL_SEARCH_IN_ROOT_DIR_BEGIN

LABEL_NO_LOADERBIN:
	mov	dh, 2				; "No KERNEL."
	call	DispStrRealMode	; ��ʾ�ַ���
%ifdef	_BOOT_DEBUG_
	mov	ax, 4c00h			; ��
	int	21h					; ��û���ҵ� LOADER.BIN, �ص� DOS
%else
	jmp	$					; û���ҵ� LOADER.BIN, ��ѭ��������
%endif

LABEL_FILENAME_FOUND:				; �ҵ� LOADER.BIN (rootentry) ��������������
	mov	ax, RootDirSectors
	and	di, 0FFE0h					; di -> ��ǰ��Ŀ�Ŀ�ʼ/ָ���ڴ濪ʼ

	push	eax
	mov	eax, [es : di + 01Ch]		; ��
	mov	dword [dwKernelSize], eax	; ������ KERNEL.BIN �ļ���С
	pop	eax

	add	di, 01Ah					; di -> �״غ�
	xor ecx, ecx
	mov	cx, word [es:di]
	push	ecx						; ����˴��� FAT �е����(ֻ�����˵�16λ�����ļ�ϵͳ��ʱ��ע�Ᵽ���16λ)
	mov eax,	ecx								
	mul byte[Sectors_per_cluster]	; �ļ���һ���������� = DeltaSectorNo + ���*8
	add	eax, DeltaSectorNo			; ������ʱ cx ������ LOADER.BIN ����ʼ������ (�� 0 ��ʼ�������)
	mov ecx, eax
	mov	ax, BaseOfKernelFile
	mov	es, ax						; es <- BaseOfLoader
	mov	bx, OffsetOfKernelFile			; bx <- OffsetOfLoader	����, es:bx = BaseOfLoader:OffsetOfLoader = BaseOfLoader * 10h + OffsetOfLoader			
	mov eax, ecx						; ax <- Sector ��
									; ���ϴ���ֻ�ڵ�һ�ζ�ȡĿ¼ʱ���ã�����Ŀ¼����һֱ�������ģ����ѭ��ֱ������

LABEL_GOON_LOADING_FILE:
	push	eax			; ��
	push	ebx			; ��
	mov	ah, 0Eh			; �� ÿ��һ����(8������)������ "Loading  " �����һ����, �γ�������Ч��:
	mov	al, '.'			; ��
	mov	bl, 0Fh			; �� Loading ......
	int	10h				; ��
	pop	ebx				; ��
	pop	eax				; ��


	mov	[BlockNum_L32], eax
	mov [BufAddr_H16],	es
	mov	[BufAddr_L16],	bx
	mov word[BlockCount],	32	; ȡһ����

	call	ReadSector			; ���ݼ������FAT��ȡ����
	
	
	pop	eax						; ȡ���� Sector �� FAT �е����<--|
																 ;|
	call	GetFATEntry											 ;|
																 ;|
	cmp	eax, 0FFFFFFFh											 ;|
	jz	LABEL_FILE_LOADED										 ;|
	push	eax					;   ���� Sector �� FAT �е����---|
	
	mul byte[Sectors_per_cluster]	;   һ����8������
	
	add	eax, DeltaSectorNo
	add	bx, BytesPerCluster		; �ڴ������������һ���� ���ֵ65535���ں˴���64KʱesҪ+1000
	jc	.1						; ��� bx ���±�� 0��˵���ں˴��� 64K
	jmp	.2
.1:
	push	eax			; es += 0x1000  �� es ָ����һ����
	mov	ax, es
	add	ax, 1000h		; Ҫ�޸�Loader���ص�λ�ò�Ȼ�˴��Ḳ��Loader���ڴ�����
	mov	es, ax
	pop	eax
.2:
	jmp	LABEL_GOON_LOADING_FILE
LABEL_FILE_LOADED:

	mov	dh, 1				; "Ready."
	call	DispStrRealMode	; ��ʾ�ַ���
	
	; ��ʾ��������������
	;mov	ax, BaseOfKernelFile
	;mov es,ax			
	;mov bp,	8192
	;mov	cx, 256		; CX = ������
	;mov	ax, 01301h		; AH = 13,  AL = 01h
	;mov	bx, 0007h		; ҳ��Ϊ0(BH = 0) �ڵװ���(BL = 07h)
	;mov	dx, 1400h
	;int	10h				; int 10h
	;jmp $
	
	; ������
	mov ax,0600h
	mov cx,0000h
	mov dx,184fh
	mov bh,07h
	int 10h
	
	; ��ӡ�ֱ���ѡ����Ϣ
	mov ax,ds
	mov es,ax
	mov bp,ResolutionMessage
	mov ax,01301h
	mov bx, 0007h
	mov cx,49
	mov dh,0
	mov dl,0
	int 10h
	; ��ʾ�ֱ���ѡ��
	mov ax,ds
	mov es,ax
	mov bp,Resolution1
	mov ax,01301h
	mov bx, 0007h
	mov cx,25
	mov dh,1
	mov dl,0
.rel:
	int 10h
	inc dh
	add bp,25
	dec byte[NumOfResolutions]
	cmp byte[NumOfResolutions],0
	jnz .rel
	
	
	; �ֱ���ѡ��
	mov ah,0
	int 16h					; ��ȡ�������룬���ascii����AL��
	
	cmp al,'1'
	jnz re.1
	mov bx,0x141
	jmp re.f
re.1:	
	cmp al,'2'
	jnz re.2
	mov bx,0x118
	jmp re.f
re.2:	
	cmp al,'3'
	jnz re.3
	mov bx,0x14c
	jmp re.f
re.3:	
	cmp al,'4'
	jnz re.4
	mov bx,0x11B
	jmp re.f
re.4:	
	cmp al,'5'
	jnz re.5
	mov bx,0x167
	jmp re.f
re.5:	
	cmp al,'6'
	jnz re.d
	mov bx,0x14d
	jmp re.f
re.d:	
	mov bx,0x117
re.f:
	; ������ʾģʽ,BX��Ϊvesaģʽ��
	mov ax,04f02h
	
	or  bx,0x4000
	int 10h
	
	; ��ȡ��ģʽ���Դ����Ե�ַ
	mov ax, cs
	mov es,	ax
	mov di, _VESA_OFF
	
	and bx,0xbfff
	mov ax, 0x4f01
	mov cx, bx
	int 10h

	mov eax, [es:di + 40]

	cmp eax,0
	je  NoLinearAdd
	jmp goon
NoLinearAdd:
	mov eax, 0A0000h	
	; ������Ƶ��Ϣ
goon:	
	mov [_VideoLinearAdd], eax
	
	mov ax, [es:di + 18]
	mov [_ScreenX], ax
	mov ax, [es:di + 20]
	mov [_ScreenY], ax
	

	; �޸��Դ��������
	mov word[LABEL_DESC_VIDEO + 2], ax
	shr	eax,16
	mov byte[LABEL_DESC_VIDEO + 4], al
	mov byte[LABEL_DESC_VIDEO + 7], ah
	
;CPU��ʼ������

;����������CPU�������д���
Startup_Begin:
;�˴�CSӦ�ñ�IPI�����Զ�����Ϊ��ȷ�ĵ�ַ�������ظ�����
;��DS�ĵ�ַ����ȫ�ֱ����Ĵ���Ӧ������Ϊȫ�ֵ�ַ
;֮ǰû������DS����APд�뵽����ĵ�ַ
	mov	ax, 9000H
	mov	ds, ax
	mov	es, ax
	mov	ss, ax
;Ϊÿ��CPU���ò�ͬջ��ַ
	mov ax, word[_NoOfProcessors]
	mov	sp, BaseOfStack
	mov bx, 1000h
	mul bx
	add sp, ax
;����
Processor_Lock:
	lock bts DWORD[_SpinLock],0
	jc Processor_Lock;
	lock inc byte[_NoOfProcessors]
	
	; ���� GDTR
	lgdt	[GdtPtr]
	
	; ���ж�
	cli

	; �򿪵�ַ��A20
	in	al, 92h
	or	al, 00000010b
	out	92h, al

	; ׼���л�������ģʽ
	mov	eax, cr0
	or	eax, 1
	mov	cr0, eax
	
	; ���뱣��ģʽ
	jmp	dword SelectorFlatC:(BaseOfLoaderPhyAddr+LABEL_PM_START)
	
	hlt
Startup_End:

;============================================================================
;����
;----------------------------------------------------------------------------
wRootDirSizeForLoop	dw	RootDirSectors	; Root Directory ռ�õ�������
wSectorNo		dw	0		; Ҫ��ȡ��������

dwKernelSize		dd	0		; KERNEL.BIN �ļ���С

;============================================================================
;�������ݰ�DAP	���ã�AH=42H DL=�������� DS:SI=���ݰ���ַ INT 13H
;----------------------------------------------------------------------------
DiskAddressPacket:
PacketSize  	db	10h						; ��С��һ��Ϊ10H��Ҳ��������ʽ
Reserved		db	0						; ����λ��0
BlockCount		dw	32						; Ҫ��ȡ��������(��������Ӧ��Ϊһ����)		���ݲ�ͬ�����޸ģ�
BufAddr_L16		dw	0						; Ҫ������ڴ��ַ��16λ(����ƫ�Ƶ�ַ)
BufAddr_H16		dw  0						; Ҫ������ڴ��ַ��16λ(�λ���ַ)
BlockNum_L32	dd	0						; Ҫ��ȡ�ľ��������ŵ�32λ
BlockNum_H32	dd  0						; Ҫ��ȡ�ľ��������Ÿ�32λ

;============================================================================
;�ַ���
;----------------------------------------------------------------------------
KernelFileName		db	"KERNEL  BIN", 0	; KERNEL.BIN ֮�ļ���
; Ϊ�򻯴���, ����ÿ���ַ����ĳ��Ⱦ�Ϊ MessageLength
MessageLength		equ	9
LoadMessage:		db	"Loading  "
Message1			db	"Ready.   "
Message2			db	"No KERNEL"

ResolutionMessage 	db "Choose a resolution that mostly fits your screen:"
Resolution1			db "1. 1024x768  AMD         "
Resolution2			db "2. 1024x768  Intel/Nvidia"
Resolution3			db "3. 1366x768  AMD         "
Resolution4			db "4. 1366x768  Intel/Nvidia"
Resolution5			db "5. 1920x1080 AMD         "
Resolution6			db "6. 1920x1080 Intel/Nvidia"
NumOfResolutions    db 6
;============================================================================

;----------------------------------------------------------------------------
; ������: DispStrRealMode
;----------------------------------------------------------------------------
; ���л���:
;	ʵģʽ������ģʽ����ʾ�ַ����ɺ��� DispStr ��ɣ�
; ����:
;	��ʾһ���ַ���, ������ʼʱ dh ��Ӧ�����ַ������(0-based)
DispStrRealMode:
	mov	ax, MessageLength
	mul	dh
	add	ax, LoadMessage
	mov	bp, ax				; ��
	mov	ax, ds				; �� ES:BP = ����ַ
	mov	es, ax				; ��
	mov	cx, MessageLength	; CX = ������
	mov	ax, 01301h			; AH = 13,  AL = 01h
	mov	bx, 0007h			; ҳ��Ϊ0(BH = 0) �ڵװ���(BL = 07h)
	mov	dl, 0
	add	dh, 3				; �ӵ� 3 ��������ʾ
	int	10h					; int 10h
	ret

;----------------------------------------------------------------------------
; ������: ReadSector
;----------------------------------------------------------------------------
; ����:
;	�ӵ� ax �� Sector ��ʼ, �� cl �� Sector ���� es:bx ��
ReadSector:
	mov si,	DiskAddressPacket
	mov ah, 42h
	mov dl, 80h
.GoOnReading:
	int	13h
	jc	.GoOnReading		; �����ȡ���� CF �ᱻ��Ϊ 1, ��ʱ�Ͳ�ͣ�ض�, ֱ����ȷΪֹ
	ret

;----------------------------------------------------------------------------
; ������: GetFATEntry
;----------------------------------------------------------------------------
; ����:
;	����ax��ֵ����FAT�е�ƫ�������ҵ�FAT�ȡ��FAT���ֵ����eax��
;	��Ҫע�����, �м���Ҫ�� FAT �������� es:bx ��, ���Ժ���һ��ʼ������ es �� bx
GetFATEntry:
	push	es
	push	bx
	push	eax
	mov	ax, BaseOfKernelFile		; ��
	sub	ax, 0100h					; �� �� BaseOfKernelFile �������� 4K �ռ����ڴ�� FAT
	mov	es, ax						; ��
	pop	eax

	mov dl,	4						; һ��FAT��ռ�ĸ��ֽ�
	mul dl							; ���FAT����ֽ�ƫ���������FAT1Ŀ¼��

	mov edx,eax						; ��eax��λ��dx��������ĳ���
	shr	edx,16						; ���� ax ���� FATEntry �� FAT �е�ƫ����. ���������� FATEntry ���ĸ�������(FATռ�ò�ֹһ������)
	div	word[Bytes_per_sector]		; dx:ax / Bytes_per_sector  ==>	ax <- ��   (FATEntry ���ڵ���������� FAT ��˵��������)
									; dx <- ���� (FATEntry �������ڵ�ƫ��)��
	push	dx
	mov	bx, 0						; bx <- 0	����, es:bx = (BaseOfLoader - 100):00 = (BaseOfLoader - 100) * 10h					
	add	eax, SectorNoOfFAT1			; �˾�ִ��֮��� ax ���� FATEntry ���ڵ�������

	mov	[BlockNum_L32], eax
	mov [BufAddr_H16],	es
	mov	[BufAddr_L16],	bx
	mov word[BlockCount], 1
	call	ReadSector				; ȡ��FAT���ݣ��ļ����ڵ���һ�أ�
	
	pop	dx
	mov ax,	dx
	add	bx, ax
	mov	eax, [es:bx]
	
LABEL_GET_FAT_ENRY_OK:

	pop	bx
	pop	es
	ret
;----------------------------------------------------------------------------
; �Ӵ��Ժ�Ĵ����ڱ���ģʽ��ִ�� ----------------------------------------------------
; 32 λ�����. ��ʵģʽ���� ---------------------------------------------------------
[SECTION .s32]

ALIGN	32

[BITS	32]

LABEL_PM_START:
	
	mov	ax, SelectorVideo
	mov	gs, ax

	mov	ax, SelectorFlatRW
	mov	ds, ax
	mov	es, ax
	mov	fs, ax
	mov	ss, ax
	mov eax, Dword[NoOfProcessors]
	mov ebx, 1024
	mul ebx
	mov	esp, TopOfStack
	add esp, eax
	
	mov ecx,1Bh			;IA32_APIC_BASE
	rdmsr
	bt eax,8
	jnc AP_Processor
	
;BSP���룺
	;���Ƴ�ʼ�����뵽20000h����AP��ȡ
	mov esi, Startup_Begin + BaseOfLoaderPhyAddr
	mov edi, 20000H
	mov ecx, Startup_End - Startup_Begin;
	rep movsb
	
	;BSP����IPI-SIPI-SIPI����
	mov DWORD [0FEE00000H + 300H],000c4500H
	mov ecx,0FFFFFFFFH
	rep nop
	mov ecx,0FFFFFFFFH
	rep nop
	mov ecx,0FFFFFFFFH
	rep nop
	mov ecx,0FFFFFFFFH
	rep nop
	mov DWORD [0FEE00000H + 300H],000c4620H
	mov ecx,0FFFFFFFFH
	rep nop
	mov ecx,0FFFFFFFFH
	rep nop
	mov DWORD [0FEE00000H + 300H],000c4620H
	mov ecx,0FFFFFFFFH
	rep nop
	mov ecx,0FFFFFFFFH
	rep nop
	jmp BSP_Processor
	
AP_Processor:
	lock btr DWORD[SpinLock],0
	hlt
BSP_Processor:
	lock btr DWORD[SpinLock],0

	;push	szMemChkTitle
	;call	DispStr
	;add	esp, 4

	call	DispMemInfo

	call	SetupPaging

	call	InitKernel
	
	;***************************************************************
	; ��¼�ں˴�С���ڴ��ַ
	;***************************************************************
	mov dword 	[BOOT_PARAM_ADDR], BOOT_PARAM_MAGIC
	mov eax,	[dwMemSize]
	mov [BOOT_PARAM_ADDR + 4],eax
	mov eax,	BaseOfKernelFile
	shl	eax,	4
	add eax,	OffsetOfKernelFile
	mov [BOOT_PARAM_ADDR + 8], eax	; phy-addr of kernel
	mov eax,[VideoLinearAdd]
	mov [BOOT_PARAM_ADDR + 12],eax
	xor eax,eax
	mov ax,[ScreenX]
	mov [BOOT_PARAM_ADDR + 16],ax
	mov ax,[ScreenY]
	mov [BOOT_PARAM_ADDR + 20],ax
	mov ax,[NoOfProcessors]
	mov [BOOT_PARAM_ADDR + 24],ax
	
	;***************************************************************
	jmp	SelectorFlatC:KernelEntryPointPhyAddr	; ��ʽ�����ں� *
	;***************************************************************
	jmp $
	; �ڴ濴��ȥ�������ģ�
	;              ��                                    ��
	;              ��                 .                  ��
	;              ��                 .                  ��
	;              ��                 .                  ��
	;              �ǩ�������������������������������������
	;              ����������������������������������������
	;              ��������������Page  Tables��������������
	;              ������������(��С��LOADER����)����������
	;    00101000h ���������������������������������������� PageTblBase
	;              �ǩ�������������������������������������
	;              ����������������������������������������
	;    00100000h ����������Page Directory Table���������� PageDirBase  <- 1M
	;              �ǩ�������������������������������������
	;              ����������������������������������������
	;       F0000h ����������������System ROM��������������
	;              �ǩ�������������������������������������
	;              ����������������������������������������
	;       E0000h ����������Expansion of system ROM ������
	;              �ǩ�������������������������������������
	;              ����������������������������������������
	;       C0000h ��������Reserved for ROM expansion������
	;              �ǩ�������������������������������������
	;              ���������������������������������������� B8000h �� gs
	;       A0000h ��������Display adapter reserved��������
	;              �ǩ�������������������������������������
	;              ����������������������������������������
	;       9FC00h ������extended BIOS data area (EBDA)����
	;              �ǩ�������������������������������������
	;              ����������������������������������������
	;       80000h ����������������KERNEL.BIN��������������
	;              �ǩ�������������������������������������
	;              ����������������������������������������
	;       30000h ������������������KERNEL���������������� 30400h �� KERNEL ��� (KernelEntryPointPhyAddr)
	;              �ǩ�������������������������������������
	;              ��                                    ��
	;        7E00h ��              F  R  E  E            ��
	;              �ǩ�������������������������������������
	;              ��������������������������������������					 ��
	;        7C00h ��������������BOOT  SECTOR(Overwrite)������������ ��
	;              �ǩ�������������������������������������
	;              ��                                    ��
	;         500h ��              LOADER.bin            ��
	;              �ǩ�������������������������������������
	;              ��������������������������������������					 ��	
	;         400h ����������ROM BIOS parameter area ����		 ��
	;              �ǩ�������������������������������������
	;              ���������������������
	;           0h ���������Int  Vectors�������
	;              ���������������������������������������� �� cs, ds, es, fs, ss
	;
	;
	;		����������		����������
	;		���������� ����ʹ�� 	���������� ����ʹ�õ��ڴ�
	;		����������		����������
	;		����������		����������
	;		��      �� δʹ�ÿռ�	������ ���Ը��ǵ��ڴ�
	;		����������		����������
	;
	; ע��KERNEL ��λ��ʵ�����Ǻ����ģ�����ͨ��ͬʱ�ı� LOAD.INC �е�
	;     KernelEntryPointPhyAddr �� MAKEFILE �в��� -Ttext ��ֵ���ı䡣
	;     ����� KernelEntryPointPhyAddr �� -Ttext ��ֵ����Ϊ 0x400400��
	;     �� KERNEL �ͻᱻ���ص��ڴ� 0x400000(4M) ��������� 0x400400��
	;

%include	"lib.inc"


; ��ʾ�ڴ���Ϣ --------------------------------------------------------------
DispMemInfo:
	push	esi
	push	edi
	push	ecx

	mov	esi, MemChkBuf
	mov	ecx, [dwMCRNumber] 	;for(int i=0;i<[MCRNumber];i++)//ÿ�εõ�һ��ARDS
.loop:					    ;{
	mov	edx, 5				;  for(int j=0;j<5;j++)//ÿ�εõ�һ��ARDS�еĳ�Ա
	mov	edi, ARDStruct		;  {//������ʾ:BaseAddrLow,BaseAddrHigh,LengthLow
.1:							;               LengthHigh,Type
	push	dword [esi]		;
	call	DispInt			;    DispInt(MemChkBuf[j*4]); // ��ʾһ����Ա
	pop	eax					;
	stosd					;    ARDStruct[j*4] = MemChkBuf[j*4];
	add	esi, 4				;
	dec	edx					;
	cmp	edx, 0				;
	jnz	.1					;  }
	call	DispReturn		;  printf("\n");
	cmp	dword [dwType], 1	;  if(Type == AddressRangeMemory)
	jne	.2					;  {
	mov	eax, [dwBaseAddrLow];
	add	eax, [dwLengthLow]	;
	cmp	eax, [dwMemSize]	;    if(BaseAddrLow + LengthLow > MemSize)
	jb	.2					;
	mov	[dwMemSize], eax	;    MemSize = BaseAddrLow + LengthLow;
.2:							;  }
	loop	.loop			;}
				  ;
	call	DispReturn		;printf("\n");
	push	szRAMSize		;
	call	DispStr			;printf("RAM size:");
	add	esp, 4				;
							;
	push	dword [dwMemSize] ;
	call	DispInt			;DispInt(MemSize);
	add	esp, 4				 ;

	pop	ecx
	pop	edi
	pop	esi
	ret
; ---------------------------------------------------------------------------

; ������ҳ���� --------------------------------------------------------------
SetupPaging:
	; �����ڴ��С����Ӧ��ʼ������PDE�Լ�����ҳ��
	xor	edx, edx
	mov	eax, 0FFFFFFFFh ;[dwMemSize]�����Կ���������ַӳ�䵽�ߵ�ַ��������ҳ����Ҫӳ��������ַ�ռ�
	mov	ebx, 400000h	; 400000h = 4M = 4096 * 1024, һ��ҳ���Ӧ���ڴ��С
	div	ebx
	mov	ecx, eax		; ��ʱ ecx Ϊҳ��ĸ�����Ҳ�� PDE Ӧ�õĸ���
	test	edx, edx
	jz	.no_remainder
	inc	ecx				; ���������Ϊ 0 ��������һ��ҳ��
.no_remainder:
	push	ecx			; �ݴ�ҳ�����

	; Ϊ�򻯴���, �������Ե�ַ��Ӧ��ȵ������ַ. ���Ҳ������ڴ�ն�.

	; ���ȳ�ʼ��ҳĿ¼
	mov	ax, SelectorFlatRW
	mov	es, ax
	mov	edi, PageDirBase	; �˶��׵�ַΪ PageDirBase
	xor	eax, eax
	mov	eax, PageTblBase | PG_P  | PG_USU | PG_RWW
.1:
	stosd
	add	eax, 4096		; Ϊ�˼�, ����ҳ�����ڴ�����������.
	loop	.1

	; �ٳ�ʼ������ҳ��
	pop	eax					; ҳ�����
	mov	ebx, 1024			; ÿ��ҳ�� 1024 �� PTE
	mul	ebx
	mov	ecx, eax			; PTE���� = ҳ����� * 1024
	mov	edi, PageTblBase	; �˶��׵�ַΪ PageTblBase
	xor	eax, eax
	mov	eax, PG_P  | PG_USU | PG_RWW
.2:
	stosd
	add	eax, 4096			; ÿһҳָ�� 4K �Ŀռ�
	loop	.2

	mov	eax, PageDirBase
	mov	cr3, eax
	mov	eax, cr0
	or	eax, 80000000h
	mov	cr0, eax
	
	nop
	ret
; ��ҳ����������� ----------------------------------------------------------

; InitKernel ---------------------------------------------------------------------------------
; �� KERNEL.BIN �����ݾ�����������ŵ��µ�λ��
; ����ÿһ�� Program Header������ Program Header �е���Ϣ��ȷ����ʲô�Ž��ڴ棬�ŵ�ʲôλ�ã��Լ��Ŷ��١�
; --------------------------------------------------------------------------------------------
InitKernel:
        xor   esi, esi
        mov   cx, word [BaseOfKernelFilePhyAddr+2Ch]	;`. ecx <- pELFHdr->e_phnum
        movzx ecx, cx									; ��Դ�����������ݿ�����Ŀ�Ĳ�������������ֵ0��չ��16λ����32λ
        mov   esi, [BaseOfKernelFilePhyAddr + 1Ch]		; esi <- pELFHdr->e_phoff
        add   esi, BaseOfKernelFilePhyAddr				;esi<-OffsetOfKernel+pELFHdr->e_phoff
.Begin:
        mov   eax, [esi + 0]
        cmp   eax, 0									; PT_NULL
        jz    .NoAction
        push  dword [esi + 010h]						;size ;`.
        mov   eax, [esi + 04h]							; |
        add   eax, BaseOfKernelFilePhyAddr				; | memcpy((void*)(pPHdr->p_vaddr),
        push  eax								   ;src ; |      uchCode + pPHdr->p_offset,
        push  dword [esi + 08h]					   ;dst ; |      pPHdr->p_filesz;
        call  MemCpy									; |
        add   esp, 12									;/
.NoAction:
        add   esi, 020h									; esi += pELFHdr->e_phentsize
        dec   ecx
        jnz   .Begin

        ret
; InitKernel ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

 [SECTION .data1]	 ; ���ݶ�
ALIGN	32
[BITS	32]
LABEL_DATA:				  
String3 db "Memory paging started !!!",0
Str3Len    equ $ - String3					   ;�ַ�������					  
OffsetStr3 equ BaseOfLoaderPhyAddr + String3	
_szRAMSize			db	"RAM size:", 0
_szReturn			db	0Ah, 0
; ����
_dwMCRNumber:			dd	0	; Memory Check Result
_dwDispPos:			dd	(80 * 0 + 0) * 2	; ��Ļ�� 0 ��, �� 0 �С�
_dwMemSize:			dd	0
_ARDStruct:			; Address Range Descriptor Structure
	_dwBaseAddrLow:		dd	0
	_dwBaseAddrHigh:	dd	0
	_dwLengthLow:		dd	0
	_dwLengthHigh:		dd	0
	_dwType:			dd	0
_PageTableNumber		dd	0
_MemChkBuf:	times	256	db	0
_VESA_OFF	times 256	db 0
_VideoLinearAdd  	dd	0
VESAMODE			dw  0
_ScreenX			dw	0
_ScreenY			dw	0
_NoOfProcessors		dw	0
_SpinLock			dw	0


;; ����ģʽ��ʹ����Щ����
szRAMSize			equ	BaseOfLoaderPhyAddr + _szRAMSize
szReturn			equ	BaseOfLoaderPhyAddr + _szReturn
dwDispPos			equ	BaseOfLoaderPhyAddr + _dwDispPos
dwMemSize			equ	BaseOfLoaderPhyAddr + _dwMemSize
dwMCRNumber			equ	BaseOfLoaderPhyAddr + _dwMCRNumber
ARDStruct			equ	BaseOfLoaderPhyAddr + _ARDStruct
	dwBaseAddrLow	equ	BaseOfLoaderPhyAddr + _dwBaseAddrLow
	dwBaseAddrHigh	equ	BaseOfLoaderPhyAddr + _dwBaseAddrHigh
	dwLengthLow		equ	BaseOfLoaderPhyAddr + _dwLengthLow
	dwLengthHigh	equ	BaseOfLoaderPhyAddr + _dwLengthHigh
	dwType			equ	BaseOfLoaderPhyAddr + _dwType
MemChkBuf			equ	BaseOfLoaderPhyAddr + _MemChkBuf
VESA_OFF			equ	BaseOfLoaderPhyAddr + _VESA_OFF
VideoLinearAdd		equ	BaseOfLoaderPhyAddr + _VideoLinearAdd
ScreenX				equ	BaseOfLoaderPhyAddr + _ScreenX
ScreenY				equ	BaseOfLoaderPhyAddr + _ScreenY
NoOfProcessors		equ BaseOfLoaderPhyAddr + _NoOfProcessors
SpinLock			equ BaseOfLoaderPhyAddr + _SpinLock

; ��ջ�������ݶε�ĩβ
StackSpace:	times	1024*16	db	0
TopOfStack	equ	BaseOfLoaderPhyAddr + $	; ջ��
; SECTION .data1 ֮���� ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

