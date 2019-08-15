## Занятие 2. Дисковая подсистема

### Содержание
1. [Описание занятия](#description)  
2. [Домашнее задание](#homework)  
3. [Выполнение](#exec)
   - [Сбор информации о дисках](#intro)
   - [Разметка дисков](#partitioning)
   - [Создание RAID 0/1 на разделах дисков](#raid-0-1)
   - [Создание файла конфигурации mdadm](#conf)
   - [Восстановление RAID после сбоя диска](#fail)
   - [Перенос работающей системы с одним диском на RAID](#transfer)  

## 1. Описание занятия <a name="description"></a>
### Цели
- перечислить виды RAID массивов и их отличия,  
- получить информацию о дисковой подсистеме на любом сервере с ОС Linux,  
- собрать программный рейд и восстановить его после сбоя  

### Краткое содержание  
- Задачи дисковой системы.  
- Программный и аппаратный RAID.  
- RAID 0/1/5/6/10/60.  
- Получение информации о дисковой системе системе с помощью `dmidecode`, `dmesg`, `smartctl`.  
- MBR и GPT. Команды `gdisk`, `fdisk`, `parted`, `partprobe`.

### Результаты  
- Студент может собрать различные типы RAID

## 2. Домашнее задание  <a name="homework"></a>
### Постановка задачи  
Системный администратор обязан уметь работать с дисковой подсистемой, делать это без ошибок, не допускать потерю данных. В этом задании необходимо продемонстрировать умение работать с software raid и инструментами для работы с работы с разделами(`parted`, `fdisk`, `lsblk`).
- добавить в `Vagrantfile` еще дисков;  
- собрать R0/R5/R10 - на выбор;  
- сломать/починить raid;  
- создать на рейде GPT раздел и 5 партиций.
В качестве проверки принимаются - измененный `Vagrantfile`, скрипт для создания рейда  
### Дополнительные задания  
- Vagrantfile, который сразу собирает систему с подключенным рейдом.  
- Перенесите работающую систему с одним диском на RAID 1. Даунтайм на загрузку с нового диска предполагается. В качестве проверки принимается вывод команды `lsblk` до и после и описание хода решения (можно воспользовать утилитой `script`).  
### Критерии оценки  
- &laquo;4&raquo; - сдан `Vagrantfile` и скрипт для сборки, который можно запустить на поднятом образе;  
- &laquo;5&raquo; - сделаны доп. задания.

## 3. Выполнение <a name="exec"></a>  
Суть выполненного мною задания состоит в:  
- автоматическом развертывании тестового окружения из [Vagrantfile](https://github.com/che-a/OTUS_LinuxAdministrator/blob/master/lesson_02/Vagrantfile) с подключенным RAID 0/1/5/6/10, уровень которого задается переменной `RAID_LEVEL` в сценарии [script.sh](https://github.com/che-a/OTUS_LinuxAdministrator/blob/master/lesson_02/script.sh);  
- последующей ручной имитацией сбоя диска в RAID и восстановлением RAID;  
- автоматическом переносе &laquo;живой&raquo; системы на созданный ранее RAID.  

### Сбор информации о дисках  <a name="intro"></a>  
Работа с дисками начинается со сбора информации с использованием следующих команд:
```bash
lsblk
sudo lshw -short | grep disk
sudo fdisk -l /dev/sda
df -h -x devtmpfs -x tmpfs
blkid
```
<details>
   <summary>Вывод вышеперечисленных команд:</summary>
	
```bash
lsblk
```
```console
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0   40G  0 disk 
└─sda1   8:1    0   40G  0 part /
sdb      8:16   0    4G  0 disk 
sdc      8:32   0    4G  0 disk 
sdd      8:48   0  256M  0 disk 
sde      8:64   0  256M  0 disk 
sdf      8:80   0  256M  0 disk 
sdg      8:96   0  256M  0 disk 
```
```bash
sudo lshw -short | grep disk
```
```console
/0/100/1.1/0.0.0    /dev/sda   disk        42GB VBOX HARDDISK
/0/100/d/0          /dev/sdb   disk        4294MB VBOX HARDDISK
/0/100/d/1          /dev/sdc   disk        4294MB VBOX HARDDISK
/0/100/d/2          /dev/sdd   disk        268MB VBOX HARDDISK
/0/100/d/3          /dev/sde   disk        268MB VBOX HARDDISK
/0/100/d/4          /dev/sdf   disk        268MB VBOX HARDDISK
/0/100/d/5          /dev/sdg   disk        268MB VBOX HARDDISK
```
```bash
sudo fdisk -l /dev/sda
```
```console

Disk /dev/sda: 42.9 GB, 42949672960 bytes, 83886080 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk label type: dos
Disk identifier: 0x0009ef88

   Device Boot      Start         End      Blocks   Id  System
/dev/sda1   *        2048    83886079    41942016   83  Linux
```
```bash
df -h -x devtmpfs -x tmpfs
```
```console
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1        40G   13G   28G  31% /
```
```bash
blkid 
```
```console
/dev/sda1: UUID="8ac075e3-1124-4bb6-bef7-a6811bf8b870" TYPE="xfs"
```
</details>

Прежде чем собирать диски в программный RAID желательно произвести предварительную проверку их состояния с помощью технологии S.M.A.R.T., но, т.к. в данном случае диск `/dev/sdb` не является физическим устройством, то эта информация недоступна.
```bash
sudo smartctl --all --health /dev/sdb
```
```console
smartctl 6.5 2016-05-07 r4318 [x86_64-linux-3.10.0-957.12.2.el7.x86_64] (local build)
Copyright (C) 2002-16, Bruce Allen, Christian Franke, www.smartmontools.org

=== START OF INFORMATION SECTION ===
Device Model:     VBOX HARDDISK
Serial Number:    VB58808702-c85b843c
Firmware Version: 1.0
User Capacity:    16 106 127 360 bytes [16,1 GB]
Sector Size:      512 bytes logical/physical
Device is:        Not in smartctl database [for details use: -P showall]
ATA Version is:   ATA/ATAPI-6 published, ANSI INCITS 361-2002
Local Time is:    Tue Aug  6 21:10:15 2019 UTC
SMART support is: Unavailable - device lacks SMART capability.

A mandatory SMART command failed: exiting. To continue, add one or more '-T permissive' options.
```
<details>
   <summary>Пример вывода информации S.M.A.R.T. реального исправного диска:</summary>

```console
smartctl 6.6 2017-11-05 r4594 [x86_64-linux-4.19.0-5-amd64] (local build)
Copyright (C) 2002-17, Bruce Allen, Christian Franke, www.smartmontools.org

=== START OF INFORMATION SECTION ===
Model Family:     Western Digital Red
Device Model:     WDC WD10EFRX-68PJCN0
Serial Number:    WD-WCC4JJLTTXEV
LU WWN Device Id: 5 0014ee 2b569345d
Firmware Version: 82.00A82
User Capacity:    1 000 203 804 160 bytes [1,00 TB]
Sector Sizes:     512 bytes logical, 4096 bytes physical
Rotation Rate:    5400 rpm
Device is:        In smartctl database [for details use: -P show]
ATA Version is:   ACS-2 (minor revision not indicated)
SATA Version is:  SATA 3.0, 6.0 Gb/s (current: 6.0 Gb/s)
Local Time is:    Wed Aug  7 00:33:38 2019 MSK
SMART support is: Available - device has SMART capability.
SMART support is: Enabled

=== START OF READ SMART DATA SECTION ===
SMART overall-health self-assessment test result: PASSED

General SMART Values:
Offline data collection status:  (0x00)	Offline data collection activity
					was never started.
					Auto Offline Data Collection: Disabled.
Self-test execution status:      (   0)	The previous self-test routine completed
					without error or no self-test has ever
					been run.
Total time to complete Offline
data collection: 		(13800) seconds.
Offline data collection
capabilities: 			 (0x7b) SMART execute Offline immediate.
					Auto Offline data collection on/off support.
					Suspend Offline collection upon new
					command.
					Offline surface scan supported.
					Self-test supported.
					Conveyance Self-test supported.
					Selective Self-test supported.
SMART capabilities:            (0x0003)	Saves SMART data before entering
					power-saving mode.
					Supports SMART auto save timer.
Error logging capability:        (0x01)	Error logging supported.
					General Purpose Logging supported.
Short self-test routine
recommended polling time: 	 (   2) minutes.
Extended self-test routine
recommended polling time: 	 ( 157) minutes.
Conveyance self-test routine
recommended polling time: 	 (   5) minutes.
SCT capabilities: 	       (0x303d)	SCT Status supported.
					SCT Error Recovery Control supported.
					SCT Feature Control supported.
					SCT Data Table supported.

SMART Attributes Data Structure revision number: 16
Vendor Specific SMART Attributes with Thresholds:
ID# ATTRIBUTE_NAME          FLAG     VALUE WORST THRESH TYPE      UPDATED  WHEN_FAILED RAW_VALUE
  1 Raw_Read_Error_Rate     0x002f   200   200   051    Pre-fail  Always       -       2
  3 Spin_Up_Time            0x0027   138   132   021    Pre-fail  Always       -       4066
  4 Start_Stop_Count        0x0032   100   100   000    Old_age   Always       -       699
  5 Reallocated_Sector_Ct   0x0033   200   200   140    Pre-fail  Always       -       0
  7 Seek_Error_Rate         0x002e   200   200   000    Old_age   Always       -       0
  9 Power_On_Hours          0x0032   093   093   000    Old_age   Always       -       5286
 10 Spin_Retry_Count        0x0032   100   100   000    Old_age   Always       -       0
 11 Calibration_Retry_Count 0x0032   100   100   000    Old_age   Always       -       0
 12 Power_Cycle_Count       0x0032   100   100   000    Old_age   Always       -       699
192 Power-Off_Retract_Count 0x0032   200   200   000    Old_age   Always       -       177
193 Load_Cycle_Count        0x0032   199   199   000    Old_age   Always       -       3802
194 Temperature_Celsius     0x0022   111   101   000    Old_age   Always       -       32
196 Reallocated_Event_Count 0x0032   200   200   000    Old_age   Always       -       0
197 Current_Pending_Sector  0x0032   200   200   000    Old_age   Always       -       0
198 Offline_Uncorrectable   0x0030   100   253   000    Old_age   Offline      -       0
199 UDMA_CRC_Error_Count    0x0032   200   200   000    Old_age   Always       -       1
200 Multi_Zone_Error_Rate   0x0008   100   253   000    Old_age   Offline      -       0

SMART Error Log Version: 1
No Errors Logged

SMART Self-test log structure revision number 1
Num  Test_Description    Status                  Remaining  LifeTime(hours)  LBA_of_first_error
# 1  Short offline       Completed without error       00%        36         -

SMART Selective self-test log data structure revision number 1
 SPAN  MIN_LBA  MAX_LBA  CURRENT_TEST_STATUS
    1        0        0  Not_testing
    2        0        0  Not_testing
    3        0        0  Not_testing
    4        0        0  Not_testing
    5        0        0  Not_testing
Selective self-test flags (0x0):
  After scanning selected spans, do NOT read-scan remainder of disk.
If Selective self-test is pending on power-up, resume after 0 minute delay.

```
</details>
<details>
   <summary>Пример вывода информации S.M.A.R.T. реального неисправного диска:</summary>

```console
smartctl 6.6 2016-05-31 r4324 [x86_64-linux-4.9.0-9-amd64] (local build)
Copyright (C) 2002-16, Bruce Allen, Christian Franke, www.smartmontools.org

=== START OF INFORMATION SECTION ===
Model Family:     Seagate Barracuda 7200.10
Device Model:     ST3160815AS
Serial Number:    9RA0AHCY
Firmware Version: 3.AAC
User Capacity:    160 041 885 696 bytes [160 GB]
Sector Size:      512 bytes logical/physical
Device is:        In smartctl database [for details use: -P show]
ATA Version is:   ATA/ATAPI-7 (minor revision not indicated)
Local Time is:    Mon Aug 12 16:47:32 2019 MSK
SMART support is: Available - device has SMART capability.
SMART support is: Enabled

=== START OF READ SMART DATA SECTION ===
SMART overall-health self-assessment test result: FAILED!
Drive failure expected in less than 24 hours. SAVE ALL DATA.
See vendor-specific Attribute list for failed Attributes.

General SMART Values:
Offline data collection status:  (0x82)	Offline data collection activity
					was completed without error.
					Auto Offline Data Collection: Enabled.
Self-test execution status:      (   0)	The previous self-test routine completed
					without error or no self-test has ever 
					been run.
Total time to complete Offline 
data collection: 		(  430) seconds.
Offline data collection
capabilities: 			 (0x5b) SMART execute Offline immediate.
					Auto Offline data collection on/off support.
					Suspend Offline collection upon new
					command.
					Offline surface scan supported.
					Self-test supported.
					No Conveyance Self-test supported.
					Selective Self-test supported.
SMART capabilities:            (0x0003)	Saves SMART data before entering
					power-saving mode.
					Supports SMART auto save timer.
Error logging capability:        (0x01)	Error logging supported.
					General Purpose Logging supported.
Short self-test routine 
recommended polling time: 	 (   1) minutes.
Extended self-test routine
recommended polling time: 	 (  54) minutes.

SMART Attributes Data Structure revision number: 10
Vendor Specific SMART Attributes with Thresholds:
ID# ATTRIBUTE_NAME          FLAG     VALUE WORST THRESH TYPE      UPDATED  WHEN_FAILED RAW_VALUE
  1 Raw_Read_Error_Rate     0x000f   112   089   006    Pre-fail  Always       -       47673471
  3 Spin_Up_Time            0x0003   097   097   000    Pre-fail  Always       -       0
  4 Start_Stop_Count        0x0032   100   100   020    Old_age   Always       -       341
  5 Reallocated_Sector_Ct   0x0033   001   001   036    Pre-fail  Always   FAILING_NOW 65453
  7 Seek_Error_Rate         0x000f   089   060   030    Pre-fail  Always       -       807870030
  9 Power_On_Hours          0x0032   041   041   000    Old_age   Always       -       51938
 10 Spin_Retry_Count        0x0013   100   100   097    Pre-fail  Always       -       0
 12 Power_Cycle_Count       0x0032   100   100   020    Old_age   Always       -       107
187 Reported_Uncorrect      0x0032   001   001   000    Old_age   Always       -       313
189 High_Fly_Writes         0x003a   100   100   000    Old_age   Always       -       0
190 Airflow_Temperature_Cel 0x0022   070   052   045    Old_age   Always       -       30 (Min/Max 26/30)
194 Temperature_Celsius     0x0022   030   048   000    Old_age   Always       -       30 (0 18 0 0 0)
195 Hardware_ECC_Recovered  0x001a   110   054   000    Old_age   Always       -       208712500
197 Current_Pending_Sector  0x0012   001   001   000    Old_age   Always       -       11166
198 Offline_Uncorrectable   0x0010   001   001   000    Old_age   Offline      -       11166
199 UDMA_CRC_Error_Count    0x003e   200   200   000    Old_age   Always       -       0
200 Multi_Zone_Error_Rate   0x0000   100   253   000    Old_age   Offline      -       0
202 Data_Address_Mark_Errs  0x0032   226   123   000    Old_age   Always       -       130

SMART Error Log Version: 1
ATA Error Count: 439 (device log contains only the most recent five errors)
	CR = Command Register [HEX]
	FR = Features Register [HEX]
	SC = Sector Count Register [HEX]
	SN = Sector Number Register [HEX]
	CL = Cylinder Low Register [HEX]
	CH = Cylinder High Register [HEX]
	DH = Device/Head Register [HEX]
	DC = Device Command Register [HEX]
	ER = Error register [HEX]
	ST = Status register [HEX]
Powered_Up_Time is measured from power on, and printed as
DDd+hh:mm:SS.sss where DD=days, hh=hours, mm=minutes,
SS=sec, and sss=millisec. It "wraps" after 49.710 days.

Error 439 occurred at disk power-on lifetime: 51939 hours (2164 days + 3 hours)
  When the command that caused the error occurred, the device was active or idle.

  After command completion occurred, registers were:
  ER ST SC SN CL CH DH
  -- -- -- -- -- -- --
  84 51 4f a1 e4 1c e0  Error: ICRC, ABRT 79 sectors at LBA = 0x001ce4a1 = 1893537

  Commands leading to the command that caused the error were:
  CR FR SC SN CL CH DH DC   Powered_Up_Time  Command/Feature_Name
  -- -- -- -- -- -- -- --  ----------------  --------------------
  25 03 f0 00 e4 1c e0 00      00:58:17.540  READ DMA EXT
  25 03 10 f0 e3 1c e0 00      00:58:17.537  READ DMA EXT
  25 03 f0 00 e3 1c e0 00      00:58:17.536  READ DMA EXT
  25 03 10 f0 e2 1c e0 00      00:58:17.533  READ DMA EXT
  25 03 f0 00 e2 1c e0 00      00:58:17.562  READ DMA EXT

Error 438 occurred at disk power-on lifetime: 51939 hours (2164 days + 3 hours)
  When the command that caused the error occurred, the device was active or idle.

  After command completion occurred, registers were:
  ER ST SC SN CL CH DH
  -- -- -- -- -- -- --
  84 51 2f c1 a8 1a e0  Error: ICRC, ABRT 47 sectors at LBA = 0x001aa8c1 = 1747137

  Commands leading to the command that caused the error were:
  CR FR SC SN CL CH DH DC   Powered_Up_Time  Command/Feature_Name
  -- -- -- -- -- -- -- --  ----------------  --------------------
  25 03 f0 00 a8 1a e0 00      00:58:07.398  READ DMA EXT
  25 03 10 f0 a7 1a e0 00      00:58:07.398  READ DMA EXT
  25 03 f0 00 a7 1a e0 00      00:58:07.394  READ DMA EXT
  25 03 10 f0 a6 1a e0 00      00:58:07.393  READ DMA EXT
  25 03 f0 00 a6 1a e0 00      00:58:07.390  READ DMA EXT

Error 437 occurred at disk power-on lifetime: 51939 hours (2164 days + 3 hours)
  When the command that caused the error occurred, the device was active or idle.

  After command completion occurred, registers were:
  ER ST SC SN CL CH DH
  -- -- -- -- -- -- --
  84 51 9f 51 4f 0b e0  Error: ICRC, ABRT 159 sectors at LBA = 0x000b4f51 = 741201

  Commands leading to the command that caused the error were:
  CR FR SC SN CL CH DH DC   Powered_Up_Time  Command/Feature_Name
  -- -- -- -- -- -- -- --  ----------------  --------------------
  25 03 f0 00 4f 0b e0 00      00:57:00.524  READ DMA EXT
  25 03 10 f0 4e 0b e0 00      00:57:00.520  READ DMA EXT
  25 03 f0 00 4e 0b e0 00      00:57:00.520  READ DMA EXT
  25 03 10 f0 4d 0b e0 00      00:57:00.516  READ DMA EXT
  25 03 f0 00 4d 0b e0 00      00:57:00.515  READ DMA EXT

Error 436 occurred at disk power-on lifetime: 51939 hours (2164 days + 3 hours)
  When the command that caused the error occurred, the device was active or idle.

  After command completion occurred, registers were:
  ER ST SC SN CL CH DH
  -- -- -- -- -- -- --
  84 51 9f 51 41 0b e0  Error: ICRC, ABRT 159 sectors at LBA = 0x000b4151 = 737617

  Commands leading to the command that caused the error were:
  CR FR SC SN CL CH DH DC   Powered_Up_Time  Command/Feature_Name
  -- -- -- -- -- -- -- --  ----------------  --------------------
  25 03 f0 00 41 0b e0 00      00:56:59.140  READ DMA EXT
  25 03 10 f0 40 0b e0 00      00:56:59.139  READ DMA EXT
  25 03 f0 00 40 0b e0 00      00:56:59.135  READ DMA EXT
  25 03 10 f0 3f 0b e0 00      00:56:59.135  READ DMA EXT
  25 03 f0 00 3f 0b e0 00      00:56:59.131  READ DMA EXT

Error 435 occurred at disk power-on lifetime: 51939 hours (2164 days + 3 hours)
  When the command that caused the error occurred, the device was active or idle.

  After command completion occurred, registers were:
  ER ST SC SN CL CH DH
  -- -- -- -- -- -- --
  84 51 af 41 1d 0a e0  Error: ICRC, ABRT 175 sectors at LBA = 0x000a1d41 = 662849

  Commands leading to the command that caused the error were:
  CR FR SC SN CL CH DH DC   Powered_Up_Time  Command/Feature_Name
  -- -- -- -- -- -- -- --  ----------------  --------------------
  25 03 f0 00 1d 0a e0 00      00:56:53.765  READ DMA EXT
  25 03 10 f0 1c 0a e0 00      00:56:53.765  READ DMA EXT
  25 03 f0 00 1c 0a e0 00      00:56:53.761  READ DMA EXT
  25 03 10 f0 1b 0a e0 00      00:56:53.761  READ DMA EXT
  25 03 f0 00 1b 0a e0 00      00:56:53.757  READ DMA EXT

SMART Self-test log structure revision number 1

SMART Selective self-test log data structure revision number 1
 SPAN  MIN_LBA  MAX_LBA  CURRENT_TEST_STATUS
    1        0        0  Not_testing
    2        0        0  Not_testing
    3        0        0  Not_testing
    4        0        0  Not_testing
    5        0        0  Not_testing
Selective self-test flags (0x0):
  After scanning selected spans, do NOT read-scan remainder of disk.
If Selective self-test is pending on power-up, resume after 0 minute delay.
```
</details>


### Разметка дисков <a name="partitioning"></a>  


### Создание RAID 0/1 на разделах дисков <a name="raid-0-1"></a>

Сборка двух экземпляров RAID 0:
```bash
mdadm --create --verbose /dev/md0 --force --level=0 --raid-devices=2 /dev/sdb2 /dev/sdc2
mdadm --create --verbose /dev/md1 --force --level=0 --raid-devices=2 /dev/sdb4 /dev/sdc4
```
Сборка трех экземпляров RAID 1:
```bash
mdadm --create --metadata=1.2 --verbose /dev/md2 --force --level=1 --raid-devices=2 /dev/sdb3 /dev/sdc3
mdadm --create --metadata=1.2 --verbose /dev/md3 --force --level=1 --raid-devices=2 /dev/sdb5 /dev/sdc5
mdadm --create --metadata=1.2 --verbose /dev/md4 --force --level=1 --raid-devices=2 /dev/sdb6 /dev/sdc6
```
```bash
cat /proc/mdstat
```
```console
Personalities : [raid0] [raid1]
md4 : active raid1 sdc6[1] sdb6[0]
      2747328 blocks super 1.2 [2/2] [UU]
      [===========>.........]  resync = 57.2% (1573760/2747328) finish=0.1min speed=174862K/sec

md3 : active raid1 sdc5[1] sdb5[0]
      130048 blocks super 1.2 [2/2] [UU]
        resync=DELAYED

md2 : active raid1 sdc3[1] sdb3[0]
      261120 blocks super 1.2 [2/2] [UU]

md1 : active raid0 sdc4[1] sdb4[0]
      1044480 blocks super 1.2 512k chunks

md0 : active raid0 sdc2[1] sdb2[0]
      1044480 blocks super 1.2 512k chunks

unused devices: <none>
```
<details>
   <summary>Подробная информация о созданных RAID</summary>

```bash
lsblk
```
```console
NAME    MAJ:MIN RM  SIZE RO TYPE  MOUNTPOINT
sda       8:0    0   40G  0 disk
└─sda1    8:1    0   40G  0 part  /
sdb       8:16   0    4G  0 disk
├─sdb1    8:17   0    1M  0 part
├─sdb2    8:18   0  512M  0 part
│ └─md0   9:0    0 1020M  0 raid0
├─sdb3    8:19   0  256M  0 part
│ └─md2   9:2    0  255M  0 raid1
├─sdb4    8:20   0  512M  0 part
│ └─md1   9:1    0 1020M  0 raid0
├─sdb5    8:21   0  128M  0 part
│ └─md3   9:3    0  127M  0 raid1
└─sdb6    8:22   0  2,6G  0 part
  └─md4   9:4    0  2,6G  0 raid1
sdc       8:32   0    4G  0 disk
├─sdc1    8:33   0    1M  0 part
├─sdc2    8:34   0  512M  0 part
│ └─md0   9:0    0 1020M  0 raid0
├─sdc3    8:35   0  256M  0 part
│ └─md2   9:2    0  255M  0 raid1
├─sdc4    8:36   0  512M  0 part
│ └─md1   9:1    0 1020M  0 raid0
├─sdc5    8:37   0  128M  0 part
│ └─md3   9:3    0  127M  0 raid1
└─sdc6    8:38   0  2,6G  0 part
  └─md4   9:4    0  2,6G  0 raid1
sdd       8:48   0  256M  0 disk
sde       8:64   0  256M  0 disk
sdf       8:80   0  256M  0 disk
sdg       8:96   0  256M  0 disk
```
```bash
sudo mdadm -D /dev/md0
```
```console
/dev/md0:
           Version : 1.2
     Creation Time : Fri Aug  9 09:16:19 2019
        Raid Level : raid0
        Array Size : 1044480 (1020.00 MiB 1069.55 MB)
      Raid Devices : 2
     Total Devices : 2
       Persistence : Superblock is persistent

       Update Time : Fri Aug  9 09:16:19 2019
             State : clean
    Active Devices : 2
   Working Devices : 2
    Failed Devices : 0
     Spare Devices : 0

        Chunk Size : 512K

Consistency Policy : none

              Name : cheLesson2RAID:0  (local to host cheLesson2RAID)
              UUID : 651ca33d:f89bfa30:29f728ef:acd6aa83
            Events : 0

    Number   Major   Minor   RaidDevice State
       0       8       18        0      active sync   /dev/sdb2
       1       8       34        1      active sync   /dev/sdc2
```
```bash
sudo mdadm -D /dev/md4
```
```console
/dev/md4:
           Version : 1.2
     Creation Time : Fri Aug  9 09:16:19 2019
        Raid Level : raid1
        Array Size : 2747328 (2.62 GiB 2.81 GB)
     Used Dev Size : 2747328 (2.62 GiB 2.81 GB)
      Raid Devices : 2
     Total Devices : 2
       Persistence : Superblock is persistent

       Update Time : Fri Aug  9 09:16:36 2019
             State : clean
    Active Devices : 2
   Working Devices : 2
    Failed Devices : 0
     Spare Devices : 0

Consistency Policy : resync

              Name : cheLesson2RAID:4  (local to host cheLesson2RAID)
              UUID : a8131daa:fa8cc24c:8d9d4908:4b4fdb46
            Events : 17

    Number   Major   Minor   RaidDevice State
       0       8       22        0      active sync   /dev/sdb6
       1       8       38        1      active sync   /dev/sdc6
```
```bash
sudo mdadm --detail --scan --verbose
```
```console
ARRAY /dev/md0 level=raid0 num-devices=2 metadata=1.2 name=cheLesson2RAID:0 UUID=825cb19e:5bd8415f:fd98e4bb:7144b27f
   devices=/dev/sdb2,/dev/sdc2
ARRAY /dev/md1 level=raid0 num-devices=2 metadata=1.2 name=cheLesson2RAID:1 UUID=c40450c3:eab96268:94c2d342:bcf3b2c0
   devices=/dev/sdb4,/dev/sdc4
ARRAY /dev/md2 level=raid1 num-devices=2 metadata=1.2 name=cheLesson2RAID:2 UUID=118c3c22:a34ae45d:c79bc37e:5d86de00
   devices=/dev/sdb3,/dev/sdc3
ARRAY /dev/md3 level=raid1 num-devices=2 metadata=1.2 name=cheLesson2RAID:3 UUID=56ab36e7:89e24f90:d939f575:22e3915e
   devices=/dev/sdb5,/dev/sdc5
ARRAY /dev/md4 level=raid1 num-devices=2 metadata=1.2 name=cheLesson2RAID:4 UUID=81437f7d:b4e2bc0e:5a672738:dbf87ae5
   devices=/dev/sdb6,/dev/sdc6
```
```bash
blkid
```
```console
/dev/sda1: UUID="8ac075e3-1124-4bb6-bef7-a6811bf8b870" TYPE="xfs"
/dev/sdc2: UUID="651ca33d-f89b-fa30-29f7-28efacd6aa83" UUID_SUB="a3a8be2e-d727-ee94-f9ca-51d30cf5120a" LABEL="cheLesson2RAID:0" TYPE="linux_raid_member" PARTUUID="7174af66-b838-49ce-a537-433448162b74"
/dev/sdc3: UUID="8237d8b4-91dc-07a7-3795-a22976b309e0" UUID_SUB="b00887f3-6b50-ad1d-8875-98b5bdd31b0c" LABEL="cheLesson2RAID:2" TYPE="linux_raid_member" PARTUUID="83c6a80c-95b4-41ad-8093-677975954e98"
/dev/sdc4: UUID="10987d58-405b-1c16-0795-e8412648e8d5" UUID_SUB="99cfdefb-d92f-f37d-3631-15a6776c3219" LABEL="cheLesson2RAID:1" TYPE="linux_raid_member" PARTUUID="b12b4e86-9c9d-43b7-8898-cbf87901ccfd"
/dev/sdc5: UUID="6fea294f-f427-3284-6e37-1580598eab6c" UUID_SUB="461ba3c3-4023-30ad-b1fc-6eae3d20ec43" LABEL="cheLesson2RAID:3" TYPE="linux_raid_member" PARTUUID="bb97cc6f-49fa-44b3-9a5c-152570c12006"
/dev/sdc6: UUID="a8131daa-fa8c-c24c-8d9d-49084b4fdb46" UUID_SUB="3aee3801-bfe1-99a4-6060-b49cd10f7eea" LABEL="cheLesson2RAID:4" TYPE="linux_raid_member" PARTUUID="43a8ae85-8a4f-4237-a97f-00c35dc1d830"
/dev/sdb2: UUID="651ca33d-f89b-fa30-29f7-28efacd6aa83" UUID_SUB="d331a80c-fbcf-0123-6664-9fb97a58efbe" LABEL="cheLesson2RAID:0" TYPE="linux_raid_member" PARTUUID="9c61b841-a205-4217-9a14-d5c920afc5a0"
/dev/sdb3: UUID="8237d8b4-91dc-07a7-3795-a22976b309e0" UUID_SUB="d68490ea-742a-f11a-337e-f14b77259f49" LABEL="cheLesson2RAID:2" TYPE="linux_raid_member" PARTUUID="271fa1d5-9b7e-4611-a646-de66122ee645"
/dev/sdb4: UUID="10987d58-405b-1c16-0795-e8412648e8d5" UUID_SUB="ee24e2fb-f42d-3b86-0fad-4906ea88950c" LABEL="cheLesson2RAID:1" TYPE="linux_raid_member" PARTUUID="23a837bb-8346-46ed-9f9b-ddef29800a99"
/dev/sdb5: UUID="6fea294f-f427-3284-6e37-1580598eab6c" UUID_SUB="0d6c6fb1-d904-760e-1023-9786678d26b8" LABEL="cheLesson2RAID:3" TYPE="linux_raid_member" PARTUUID="2a737331-1592-4b74-b8b9-fab9b07354e0"
/dev/sdb6: UUID="a8131daa-fa8c-c24c-8d9d-49084b4fdb46" UUID_SUB="fb9f993a-b120-a687-0065-2fa986be91e8" LABEL="cheLesson2RAID:4" TYPE="linux_raid_member" PARTUUID="2d09e818-a1ad-4699-be53-52a7ee137c84"
```
</details>



### Восстановление RAID после сбоя диска <a name="fail"></a>
#### Восстановление RAID 1
Рассмотрим восстановление работоспособности RAID 1 на примере `/dev/md3`.
Сначала имитируем сбой одного из дисков массива, например, `/dev/sdb5`:
```bash
sudo mdadm /dev/md3 --fail /dev/sdb5
```
```console
mdadm: set /dev/sdb5 faulty in /dev/md3
```
```bash
cat /proc/mdstat | grep -A1  md3
```
```console
md3 : active raid1 sdc5[1] sdb5[0](F)
      130048 blocks super 1.2 [2/1] [_U]
```
Далее необходимо удалить &laquo;сбойный&raquo; диск из массива:
```bash
sudo mdadm /dev/md3 --remove /dev/sdb5
```
```console
mdadm: hot removed /dev/sdb5 from /dev/md3
```
```bash
cat /proc/mdstat |grep -A1 md3
```
```console
md3 : active raid1 sdc5[1]
      130048 blocks super 1.2 [2/1] [_U]
```
Представим, что мы вставили новый диск `/dev/sdb5` в сервер и теперь нам нужно 
добавить его в RAID. Делается это следующей командой:
```bash
sudo mdadm /dev/md3 --add /dev/sdb5
```
```console
mdadm: added /dev/sdb5
```
```bash
cat /proc/mdstat |grep -A1 md3
```
```console
md3 : active raid1 sdb5[2] sdc5[1]
      130048 blocks super 1.2 [2/2] [UU]
```
#### Восстановление RAID 10
```bash
sudo mdadm -D /dev/md10
```
```console
/dev/md10:
           Version : 1.2
     Creation Time : Fri Aug  9 19:16:24 2019
        Raid Level : raid10
        Array Size : 520192 (508.00 MiB 532.68 MB)
     Used Dev Size : 260096 (254.00 MiB 266.34 MB)
      Raid Devices : 4
     Total Devices : 4
       Persistence : Superblock is persistent

       Update Time : Fri Aug  9 19:16:53 2019
             State : clean 
    Active Devices : 4
   Working Devices : 4
    Failed Devices : 0
     Spare Devices : 0

            Layout : near=2
        Chunk Size : 512K

Consistency Policy : resync

              Name : cheLesson2RAID:10  (local to host cheLesson2RAID)
              UUID : e7670989:1a35547c:e19051ca:5135c5a7
            Events : 17

    Number   Major   Minor   RaidDevice State
       0       8       48        0      active sync set-A   /dev/sdd
       1       8       64        1      active sync set-B   /dev/sde
       2       8       80        2      active sync set-A   /dev/sdf
       3       8       96        3      active sync set-B   /dev/sdg
```
```bash
cat /proc/mdstat |grep -A1 md10
```
```console
md10 : active raid10 sdg[3] sdf[2] sde[1] sdd[0]
      520192 blocks super 1.2 512K chunks 2 near-copies [4/4] [UUUU]
```
Имитируем отказ диска:
```bash
sudo mdadm /dev/md10 --fail /dev/sdd
```
```console
mdadm: set /dev/sdd faulty in /dev/md10
```
```bash
cat /proc/mdstat | grep -A2 md10
```
```console
md10 : active raid10 sdg[3] sdf[2] sde[1] sdd[0](F)
      520192 blocks super 1.2 512K chunks 2 near-copies [4/3] [_UUU]
```
### Перенос работающей системы с одним диском на RAID <a name="transfer"></a>
Перенос работающей системы с диска `/dev/sda` на собранный в предыдущем задании RAID 0/1/5/6/10 произоводится ручным запуском сценария `finish.sh`, который автоматически создается при развертывании тестового окружения:
```bash
sudo -s
./finish.sh
```
```bash
reboot
```
