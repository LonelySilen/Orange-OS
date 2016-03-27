	OEM                   db  'MSDOS5.0'            ;//8Bytes  
    Bytes_per_sector      dw   512  	 
	Sectors_per_cluster   db   32  
	Reserved_sectors      dw   2786
	Number_of_FATs        db   2  
	Root_entries          dw   0  
	Sectors_small         dw   0  
	Media_descriptor      db   0f8h  
	Sectors_per_FAT_small dw   0  
	Sectors_per_track     dw   63  
	Heads                 dw   255  
	Hidden_sectors        dd   63  
	Sectors               dd   61432497
	  
	Sectors_per_FAT       dd   14991
	Extended_flags        dw   0  
	Version               dw   0  
	Root_dir_1st_cluster  dd   2  
	FSInfo_sector         dw   1 
	Backup_boot_sector    dw   6  
	times 12 db 0  
	  
	BIOS_drive            db   80h  
	db 0  
	Ext_boot_signature    db   29h  
	Volume_serial_number  dd   3404242512 
	Volume_label          db   "Oscar's OS "       ;//11���ֽ�  
	File_system           db   'FAT32   '          ;//8���ֽ� 

; ע����x86��ϵ�а�little-endian��ʽ������ݣ����Դ˴����ֽ����ݲ��÷�ת˳��

; -------------------------------------------------------------------------
; ���� FAT32 ͷ��һЩ�������壬���ͷ��Ϣ�ı䣬����ĳ�������ҲҪ����Ӧ�ı�
; -------------------------------------------------------------------------
; Sectors_per_FAT
FATSz			equ	14991

; ��Ŀ¼ռ�ÿռ�:(һ��)

RootDirSectors		equ	32

; RootDirSectors = 	Hidden_sectors + Reserved_sectors + Sectors_per_FAT*Number_of_FATs
SectorNoOfRootDirectory	equ	32831

; FAT1 �ĵ�һ��������	= Reserved_sectors + Hidden_sectors
SectorNoOfFAT1		equ	2849

; �����0�ص�ַ��ʵ����0,1�ض���ʹ�ã����������˼��ٺ����������
; �ļ�Ŀ¼���ڵڶ��أ�������һ��Ϊ�ļ���
; DeltaSectorNo =  SectorNoOfRootDirectory - 2*32
DeltaSectorNo		equ	32767

BytesPerCluster		equ	  16384