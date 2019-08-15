## Занятие 2. Дисковая подсистема

### Содержание
1. [Описание занятия](#description)  
2. [Домашнее задание](#homework)  
3. [Выполнение](#exec)
   - [Сбор информации о дисках](#smartctl)  
   - [Создание RAID 0/1/5/6/10](#raid)  
   - [Перенос работающей системы на RAID](#transfer)  
   - [Восстановление RAID](#fail)

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

Файл сценария провижининга [script.sh](https://github.com/che-a/OTUS_LinuxAdministrator/blob/master/lesson_02/script.sh) содержит подробные комментарии о назначении выполняемых команд, поэтому далее описываются только те действия, которые не включены в указанный скрипт.  
Сценарий [script.sh](https://github.com/che-a/OTUS_LinuxAdministrator/blob/master/lesson_02/script.sh) состоит из нескольких функций, каждая из которых объединяет логически связанные команды, что упрощает отладку.  
Для отслеживания изменения состояния дисковой подсистемы производится логирование вывода информационных команд в файл [report.log]().

### Сбор информации о дисках  <a name="smartctl"></a>  
Работа с дисками начинается со сбора информации о них с использованием следующих команд:
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

### Создание RAID 0/1/5/6/10 <a name="raid"></a>
Выбор нужного уровня RAID происходит перед запуском тестового окружения путем редатирования значения переменной `RAID_LEVEL` в файле [script.sh](https://github.com/che-a/OTUS_LinuxAdministrator/blob/master/lesson_02/script.sh).


### Перенос работающей системы с одним диском на RAID <a name="transfer"></a>
Перенос работающей системы с диска `/dev/sda` на собранный в предыдущем задании RAID 0/1/5/6/10 произоводится ручным запуском сценария `finish.sh`, который автоматически создается при развертывании тестового окружения:
```bash
sudo -s
./finish.sh
```
```bash
reboot
```

### Восстановление RAID <a name="fail"></a>
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
