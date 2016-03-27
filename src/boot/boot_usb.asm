
;%define	_BOOT_DEBUG_	; �� Boot Sector ʱһ��������ע�͵�!�����д򿪺��� nasm Boot.asm -o Boot.com ����һ��.COM�ļ����ڵ���

%ifdef	_BOOT_DEBUG_
	org  0100h			; ����״̬, ���� .COM �ļ�, �ɵ���
%else
	org  07c00h			; Boot ״̬, Bios ���� Boot Sector ���ص� 0:7C00 ������ʼִ��
%endif

;================================================================================================
%ifdef	_BOOT_DEBUG_
BaseOfStack		equ	0100h	; ����״̬�¶�ջ����ַ(ջ��, �����λ����͵�ַ����)
%else
BaseOfStack		equ	07c00h	; Boot״̬�¶�ջ����ַ(ջ��, �����λ����͵�ַ����)
%endif

%include	"load.inc"
;================================================================================================

	jmp short LABEL_START		; Start to boot.
	nop							; ��� nop ������

; ������ FAT32 ���̵�ͷ, ֮���԰���������Ϊ�����õ��˴��̵�һЩ��Ϣ
%include	"Fat32BPB.inc"

LABEL_START:	
	mov	ax, cs
	mov	ds, ax
	mov	es, ax
	mov	ss, ax
	mov	sp, BaseOfStack

	; ����
	mov	ax, 0600h			; AH = 6,  AL = 0h
	mov	bx, 0700h			; �ڵװ���(BL = 07h)
	mov	cx, 0				; ���Ͻ�: (0, 0)
	mov	dx, 0184fh			; ���½�: (80, 50)
	int	10h					; int 10h

	xor	ah, ah				; ��
	mov	dl, [BIOS_drive]	; �� Ӳ�̸�λ
	int	13h					; ��

	mov	dh, 0				; "Booting."
	call	DispStr			; ��ʾ�ַ���
	; ������ A �̵ĸ�Ŀ¼Ѱ�� LOADER.BIN
	mov	word [wSectorNo], SectorNoOfRootDirectory
LABEL_SEARCH_IN_ROOT_DIR_BEGIN:
	cmp	word [wRootDirSizeForLoop], 0	; ��
	jz	LABEL_NO_LOADERBIN				; �� �жϸ�Ŀ¼���ǲ����Ѿ�����
	dec	word [wRootDirSizeForLoop]		; �� ��������ʾû���ҵ� LOADER.BIN
	mov	ax, BaseOfLoader
	mov	es, ax					; es <- BaseOfLoader
	mov	bx, OffsetOfLoader		; bx <- OffsetOfLoader	����, es:bx = BaseOfLoader:OffsetOfLoader
	mov	ax, [wSectorNo]			; ax <- Root Directory �е�ĳ Sector ��
	mov [BlockNum_L32],	ax
	mov [BufAddr_H16],es
	mov [BufAddr_L16],bx

	call	ReadSector

	mov	si, LoaderFileName		; ds:si -> "LOADER  BIN"
	mov	di, OffsetOfLoader		; es:di -> BaseOfLoader:0100 = BaseOfLoader*10h+100
	cld
	mov	dx, 80h								; һ����Ӧ����80h��ѭ������
LABEL_SEARCH_FOR_LOADERBIN:
	cmp	dx, 0								; ��ѭ����������,
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
; ����Ҫ�ҵ� LOADER.BIN
LABEL_GO_ON:
	inc	di
	jmp	LABEL_CMP_FILENAME			;	����ѭ��

LABEL_DIFFERENT:
	and	di, 0FFE0h					; else ��	di &= E0 Ϊ������ָ����Ŀ��ͷ
	add	di, 20h						;      ��
	mov	si, LoaderFileName			;      �� di += 20h  ��һ��Ŀ¼��Ŀ
	jmp	LABEL_SEARCH_FOR_LOADERBIN	;      ��

LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR:
	add	word [wSectorNo], 1
	jmp	LABEL_SEARCH_IN_ROOT_DIR_BEGIN

LABEL_NO_LOADERBIN:
	mov	dh, 2				; "No LOADER."
	call	DispStr			; ��ʾ�ַ���
%ifdef	_BOOT_DEBUG_
	mov	ax, 4c00h			; ��
	int	21h					; ��û���ҵ� LOADER.BIN, �ص� DOS
%else
	jmp	$					; û���ҵ� LOADER.BIN, ��ѭ��������
%endif

LABEL_FILENAME_FOUND:				; �ҵ� LOADER.BIN (rootentry) ��������������
	mov	ax, RootDirSectors
	and	di, 0FFE0h					; di -> ��ǰ��Ŀ�Ŀ�ʼ/ָ���ڴ濪ʼ
	add	di, 01Ah					; di -> �״�
	mov	cx, word [es:di]
	push	cx						; ����˴��� FAT �е����(ֻ�����˵�16λ�����ļ�ϵͳ��ʱ��ע�Ᵽ���16λ)
	mov ax,	cx								
	mul byte[Sectors_per_cluster]	; �ļ���һ���������� = DeltaSectorNo + ���*8
	add	ax, DeltaSectorNo			; ������ʱ cx ������ LOADER.BIN ����ʼ������ (�� 0 ��ʼ�������)
	mov cx, ax
	mov	ax, BaseOfLoader
	mov	es, ax						; es <- BaseOfLoader
	mov	bx, OffsetOfLoader			; bx <- OffsetOfLoader	����, es:bx = BaseOfLoader:OffsetOfLoader = BaseOfLoader * 10h + OffsetOfLoader			
									; cx <- Sector ��
									; ���ϴ���ֻ�ڵ�һ�ζ�ȡĿ¼ʱ���ã�����Ŀ¼����һֱ�������ģ����ѭ��ֱ������

LABEL_GOON_LOADING_FILE:
	push	ax			; ��
	push	bx			; ��
	mov	ah, 0Eh			; �� ÿ��һ����(8������)������ "Booting  " �����һ����, �γ�������Ч��:
	mov	al, '.'			; ��
	mov	bl, 0Fh			; �� Booting ......
	int	10h				; ��
	pop	bx				; ��
	pop	ax				; ��


	mov	[BlockNum_L32], cx
	mov [BufAddr_H16],	es
	mov	[BufAddr_L16],	bx

	call	ReadSector			; 		���ݼ������FAT��ȡ����
	pop	ax						;       ȡ���˴��� FAT �е����<--|
																 ;|
	call	GetFATEntry											 ;|
																 ;|
	cmp	eax, 0FFFFFFFh											 ;|
	jz	LABEL_FILE_LOADED										 ;|
	push	ax					;       ������� FAT �е����  ---|
	
	mul byte[Sectors_per_cluster]						;   	һ����8������
	mov	dx, RootDirSectors
	add	ax, dx
	add	ax, DeltaSectorNo
	add	bx, BytesPerCluster		; �ڴ������������һ���� ע�������Ƕ���ĳ��������ܼӷ����ţ���������λ�ò���Ԥ��ֵ
	jmp	LABEL_GOON_LOADING_FILE
LABEL_FILE_LOADED:

	mov	dh, 1				; "Ready."
	call	DispStr			; ��ʾ�ַ���

	; ��ʾ��������������
	;mov	ax, BaseOfLoader
	;mov es,ax			
	;mov bp,	OffsetOfLoader
	;mov	cx, 1024		; CX = ������
	;mov	ax, 01301h		; AH = 13,  AL = 01h
	;mov	bx, 0007h		; ҳ��Ϊ0(BH = 0) �ڵװ���(BL = 07h)
	;mov	dx, 0300h
	;int	10h				; int 10h

; ****************************************************************************************
	jmp	BaseOfLoader:OffsetOfLoader	; ��һ����ʽ��ת���Ѽ��ص��ڴ��е� LOADER.BIN �Ŀ�ʼ��
									; ��ʼִ�� LOADER.BIN �Ĵ���
									; Boot Sector ��ʹ�����˽���
; ****************************************************************************************



;============================================================================
;����
;----------------------------------------------------------------------------
wRootDirSizeForLoop	dw	RootDirSectors	; Root Directory ռ�õ�������, ��ѭ���л�ݼ�����.
wSectorNo			dw	0				; Ҫ��ȡ��������
;============================================================================
;���̵�ַ���ݰ�DAP	���ã�AH=42H DL=�������� DS:SI=���ݰ���ַ INT 13H
;----------------------------------------------------------------------------
DiskAddressPacket:
PacketSize  	db	10h						; ��С��һ��Ϊ10H��Ҳ��������ʽ
Reserved		db	0						; ����λ��0
BlockCount		dw	8						; Ҫ��ȡ��������(��������Ӧ��Ϊһ����)
BufAddr_L16		dw	0						; Ҫ������ڴ��ַ��16λ(����ƫ�Ƶ�ַ)
BufAddr_H16		dw  0						; Ҫ������ڴ��ַ��16λ(�λ���ַ)
BlockNum_L32	dd	0						; Ҫ��ȡ�ľ��������ŵ�32λ
BlockNum_H32	dd  0						; Ҫ��ȡ�ľ��������Ÿ�32λ
;============================================================================
;�ַ���
;----------------------------------------------------------------------------
LoaderFileName	db	"LOADER  BIN", 0	; LOADER.BIN ֮�ļ���
; Ϊ�򻯴���, ����ÿ���ַ����ĳ��Ⱦ�Ϊ MessageLength
MessageLength	equ	9
BootMessage:	db	"Booting  "			; 9�ֽ�, �������ÿո���. ��� 0
Message1		db	"Ready.   "			; 9�ֽ�, �������ÿո���. ��� 1
Message2		db	"No LOADER"			; 9�ֽ�, �������ÿո���. ��� 2
;============================================================================


;----------------------------------------------------------------------------
; ������: DispStr
;----------------------------------------------------------------------------
; ����:
;	��ʾһ���ַ���, ������ʼʱ dh ��Ӧ�����ַ������(0-based)
DispStr:
	mov	ax, MessageLength
	mul	dh
	add	ax, BootMessage
	mov	bp, ax			; ��
	mov	ax, ds			; �� ES:BP = ����ַ
	mov	es, ax			; ��
	mov	cx, MessageLength	; CX = ������
	mov	ax, 01301h		; AH = 13,  AL = 01h
	mov	bx, 0007h		; ҳ��Ϊ0(BH = 0) �ڵװ���(BL = 07h)
	mov	dl, 0
	int	10h				; int 10h
	ret

;----------------------------------------------------------------------------
; ������: ReadSector
;----------------------------------------------------------------------------
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
	push	ax
	mov	ax, BaseOfLoader			; ��
	sub	ax, 0100h					; �� �� BaseOfLoader �������� 4K �ռ����ڴ�� FAT
	mov	es, ax						; ��
	pop	ax
	mov dl,	4						; һ��FAT��ռ�ĸ��ֽ�
	mul dl							; ���FAT����ֽ�ƫ���������FAT1Ŀ¼��

	xor	dx, dx						; ���� ax ���� FATEntry �� FAT �е�ƫ����. ���������� FATEntry ���ĸ�������(FATռ�ò�ֹһ������)
	div	word[Bytes_per_sector]		; dx:ax / Bytes_per_sector  ==>	ax <- ��   (FATEntry ���ڵ���������� FAT ��˵��������)
									; dx <- ���� (FATEntry �������ڵ�ƫ��)��
	push	dx
	mov	bx, 0						; bx <- 0	����, es:bx = (BaseOfLoader - 100):00 = (BaseOfLoader - 100) * 10h					
	add	ax, SectorNoOfFAT1			; �˾�ִ��֮��� ax ���� FATEntry ���ڵ�������

	mov	[BlockNum_L32], ax
	mov [BufAddr_H16],	es
	mov	[BufAddr_L16],	bx
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

times 	510-($-$$)	db	0	; ���ʣ�µĿռ䣬ʹ���ɵĶ����ƴ���ǡ��Ϊ512�ֽ�
dw 	0xaa55					; ������־
