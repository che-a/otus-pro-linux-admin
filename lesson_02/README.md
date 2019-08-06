## Занятие 2. Дисковая подсистема

### Содержание
1. [Описание занятия](#description)  
2. [Домашнее задание](#homework)  
3. [Выполнение](#exec)
   - [Сбор информации и подготовка дисков](#intro)
   - [Сборка системы с подключенным RAID-массивом](#exec1)  
   - [Перенос работающей системы с одним диском на RAID 1](#exec2)  

## 1. Описание занятия <a name="description"></a>
#### Цели
- перечислить виды RAID массивов и их отличия,  
- получить информацию о дисковой подсистеме на любом сервере с ОС Linux,  
- собрать программный рейд и восстановить его после сбоя  

#### Краткое содержание  
- Задачи дисковой системы.  
- Программный и аппаратный RAID.  
- RAID 0/1/5/6/10/60.  
- Получение информации о дисковой системе системе с помощью `dmidecode`, `dmesg`, `smartctl`.  
- MBR и GPT. Команды `gdisk`, `fdisk`, `parted`, `partprobe`.

#### Результаты  
- Студент может собрать различные типы RAID

## 2. Домашнее задание  <a name="homework"></a>
#### Постановка задачи  
Системный администратор обязан уметь работать с дисковой подсистемой, делать это без ошибок, не допускать потерю данных. В этом задании необходимо продемонстрировать умение работать с software raid и инструментами для работы с работы с разделами(`parted`, `fdisk`, `lsblk`).
- добавить в `Vagrantfile` еще дисков;  
- собрать R0/R5/R10 - на выбор;  
- сломать/починить raid;  
- создать на рейде GPT раздел и 5 партиций.
В качестве проверки принимаются - измененный `Vagrantfile`, скрипт для создания рейда  
#### Дополнительные задания  
- Vagrantfile, который сразу собирает систему с подключенным рейдом.  
- Перенесите работающую систему с одним диском на RAID 1. Даунтайм на загрузку с нового диска предполагается. В качестве проверки принимается вывод команды `lsblk` до и после и описание хода решения (можно воспользовать утилитой `script`).  
#### Критерии оценки  
- &laquo;4&raquo; - сдан `Vagrantfile` и скрипт для сборки, который можно запустить на поднятом образе;  
- &laquo;5&raquo; - сделаны доп. задания.

## 3. Выполнение <a name="exec"></a>  
Развертывание тестового окружения происходит из [Vagrantfile](https://github.com/che-a/OTUS_LinuxAdministrator/blob/master/lesson_02/Vagrantfile) с последующим провижинингом из сценария [script.sh](https://github.com/che-a/OTUS_LinuxAdministrator/blob/master/lesson_02/script.sh), который запускает обновление системы, установку необходимых пакетов, а также:  
- создает RAID 0 и RAID 1 на разделах дисков `/dev/sdb` и `/dev/sdc`;  
- последовательно создает и удаляет RAID 5, RAID 6 и RAID 10 на дисках `/dev/sdd`, `/dev/sde`, `/dev/sdf` и `/dev/sdg`.  

#### Сбор информации и подготовка дисков  <a name="intro"></a>  
Тестовое окружение имеет следующий набор дисков:
```console
lsblk

NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0   40G  0 disk 
└─sda1   8:1    0   40G  0 part /
sdb      8:16   0   15G  0 disk 
sdc      8:32   0   15G  0 disk 
sdd      8:48   0  256M  0 disk 
sde      8:64   0  256M  0 disk 
sdf      8:80   0  256M  0 disk 
sdg      8:96   0  256M  0 disk 
```
```console
sudo lshw -short | grep disk

/0/100/1.1/0.0.0    /dev/sda   disk        42GB VBOX HARDDISK
/0/100/d/0          /dev/sdb   disk        16GB VBOX HARDDISK
/0/100/d/1          /dev/sdc   disk        16GB VBOX HARDDISK
/0/100/d/2          /dev/sdd   disk        268MB VBOX HARDDISK
/0/100/d/3          /dev/sde   disk        268MB VBOX HARDDISK
/0/100/d/4          /dev/sdf   disk        268MB VBOX HARDDISK
/0/100/d/5          /dev/sdg   disk        268MB VBOX HARDDISK
```
```console

```
Прежде чем собирать диски в программный RAID желательно произвести предварительную проверку их состояния с помощью технологии S.M.A.R.T., но т.к. в данном случае диск `/dev/sdb` не является физическим устройством, то эта информация недоступна.
```console
sudo smartctl --all --health /dev/sdb

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
   <summary>Пример вывода информации S.M.A.R.T. реального устройства:</summary>
   
```console
df -h
```
</details>

#### Сборка системы с подключенным RAID-массивом <a name="exec1"></a>
Работа с дисками начинается со сбора информации:

Далее на дисках `/dev/sdb` и `/dev/sdc` необходимо создать разделы, чтобы на их основе организовать RAID.
Сперва необходимо уничтожить структуры данных GPT и MBR если такоые имеются:
```console
# sgdisk --zap-all /dev/sdb
```
Далее следует очистить таблицу разделов:
```console
# sgdisk -o /dev/sdb
```
```console
sgdisk -n 1:0:+1M --typecode=1:EF02 /dev/sdb
sgdisk -n 2:0:+512M --typecode=2:8300 /dev/sdb
sgdisk --largest-new=3 /dev/sdb

# копия таблицы разделов
sgdisk -R /dev/sdc /dev/sdb

# рандомизировать GUID дисков и разделов
sgdisk -G /dev/sdc

# переместить второй заголовок в конец диска
sgdisk --randomize-guids --move-second-header /dev/sdc
```
```console

```

```console
mdadm --create --verbose /dev/md0 --level=0 --raid-devices=2 /dev/sdb3 /dev/sdc3
mdadm --create --verbose /dev/md1 --level=1 --raid-devices=2 /dev/sdb2 /dev/sdc2
```
```console
cat /proc/mdstat
Personalities : [raid0] [raid1]
md1 : active raid1 sdc2[1] sdb2[0]
      5760960 blocks super 1.2 [2/2] [UU]
      [==========>..........]  resync = 53.3% (3074432/5760960) finish=0.8min speed=53969K/sec

md0 : active raid0 sdc1[1] sdb1[0]
      1044480 blocks super 1.2 512k chunks

unused devices: <none>
```
```console
lsblk
NAME    MAJ:MIN RM  SIZE RO TYPE  MOUNTPOINT
sda       8:0    0   40G  0 disk
└─sda1    8:1    0   40G  0 part  /
sdb       8:16   0    6G  0 disk
├─sdb1    8:17   0  512M  0 part
│ └─md0   9:0    0 1020M  0 raid0
└─sdb2    8:18   0  5,5G  0 part
  └─md1   9:1    0  5,5G  0 raid1
sdc       8:32   0    6G  0 disk
├─sdc1    8:33   0  512M  0 part
│ └─md0   9:0    0 1020M  0 raid0
└─sdc2    8:34   0  5,5G  0 part
  └─md1   9:1    0  5,5G  0 raid1
sdd       8:48   0  250M  0 disk
sde       8:64   0  250M  0 disk
sdf       8:80   0  250M  0 disk
sdg       8:96   0  250M  0 disk
```
```console
# mdadm -D /dev/md0
/dev/md0:
           Version : 1.2
     Creation Time : Sun Aug  4 17:01:47 2019
        Raid Level : raid0
        Array Size : 1044480 (1020.00 MiB 1069.55 MB)
      Raid Devices : 2
     Total Devices : 2
       Persistence : Superblock is persistent

       Update Time : Sun Aug  4 17:01:47 2019
             State : clean
    Active Devices : 2
   Working Devices : 2
    Failed Devices : 0
     Spare Devices : 0
     
        Chunk Size : 512K

Consistency Policy : none

              Name : machine01:0  (local to host machine01)
              UUID : 31e74539:cb076ad3:d4a2c89a:3a07b503
            Events : 0

    Number   Major   Minor   RaidDevice State
       0       8       17        0      active sync   /dev/sdb1
       1       8       33        1      active sync   /dev/sdc1
```
```console
```

#### Перенос работающей системы с одним диском на RAID 1 <a name="exec2"></a>
