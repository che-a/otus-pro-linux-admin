## Занятие 3. Файловые системы и LVM

### Содержание
1. [Описание занятия](#description)  
2. [Домашнее задание](#homework)  
3. [Выполнение](#exec)  
    - [LVM. Уменьшение размера корневого тома, перенос каталогов на отдельные тома](#reduce)  
    - [LVM. Создание снапшота, восстановление со снапшота](#snap)  
    - [ZFS. Использование кэша и снапшотов](#zfs)  

## 1. Описание занятия <a name="description"></a>
### Цели
- LVM - облегчаем себе жизнь управления файловыми системами;  
- архитектура файловой системы Linux: суперблок, блоки, inodes, журналы;  
- разбираемся в многообразии файловых систем.

### Краткое содержание  
- LVM;  
- основные понятия;  
- управление и конфигурирование;  
- практические примеры;  
- LVM Snapshots;  
- LVM Thin Provision;  
- LVM Cache;  
- LVM MIrror;  
- Файловые системы;  
- Блок, суперблок, айноды;  
- настройки ядра;  
- Журналирование;  
- Иерархия.

### Результаты  
Студент понимает как устроена файловая система. Может управлять LVM томами и знает как правильно разбить диск под файловую структуру и выбрать фс для системы.  

## 2. Домашнее задание  <a name="homework"></a>
### Постановка задачи  
Работа с LVM на имеющемся образе `/dev/mapper/VolGroup00-LogVol00 38G 738M 37G 2% /`
- уменьшить том под `/` до 8G;  
- выделить том под `/home`;  
- выделить том под `/var`;  
- `/var` - сделать в mirror;  
- `/home` - сделать том для снапшотов;  
- прописать монтирование в `/etc/fstab`;  
- попробовать с разными опциями и разными файловыми системами (на выбор);  
- сгенерировать файлы в `/home/`;  
- снять снапшот;  
- удалить часть файлов;  
- восстановиться со снапшота;  
- залогировать работу можно с помощью утилиты `script`.

### Дополнительные задания  
На нашей куче дисков попробовать поставить btrfs/zfs - с кешем, снапшотами - разметить здесь каталог `/opt`.

### Критерии оценки  
Критерии оценки: основная часть обязательна, задание со звездочкой +1 балл.

## 3. Выполнение <a name="exec"></a>  
### LVM. Уменьшение размера корневого тома, перенос каталогов на отдельные тома <a name="reduce"></a>  
Необходимо уменьшить размер тома с корневым каталогом и файловой системой XFS до 8 ГБ, перенести каталоги `/var` и `/home` на отдельные тома, причем том для `/var` сдлеать зеркалирование.  

Учитывая тот факт, что файловая система XFS не поддерживает уменьшение размера тома, то алгоритм решения поставленной задачи будет следующим:  
- создать временный том для корневого каталога и перенести на него все данные с текущего;  
- загрузить систему, в которой корнем будет созданный выше временный том;  
- удалить несмонтированный корневой раздел и создать вместо него том меньшего размера;  
- создать отдельные тома для `/home` и `/var`;  
- скопировать данные из временного тома на созданные тома;  
- перезагрузить систему с примонтированными томами;  
- удалить временный том.  

Решение этой задачи автоматизировано с помощью сценария [lvm_reduce_move.sh](https://github.com/che-a/OTUS_LinuxAdministrator/blob/master/lesson_03/lvm_reduce_move.sh), который необходимо однократно запустить после развертывания тестового окружения:
```bash
sudo ./lvm_reduce_move.sh
```
Во время выполнения сценария будет дважды выполнена перезагрузка системы. Контролировать ход и завершение работы сценария можно, например, через превью менеджера виртуальных машин `Oracle VirtualBox` или по разрывам `SSH`-сессии. Структура сценария разделена на несколько этапов, что связано с необходимостью перезагрузки системы во время его выполнения. Текущий этап выполнения сценария записывается в файл, что позволяет после перезагрузки системы продолжить выполнение сценария. Автозагрузка сценария реализована средствами `systemd`.  

Начальное состояние тестового окружения:
```bash
df -h -x tmpfs -x devtmpfs
```
```console
Filesystem                       Size  Used Avail Use% Mounted on
/dev/mapper/VolGroup00-LogVol00   38G  816M   37G   3% /
/dev/sda2                       1014M   63M  952M   7% /boot
```
```bash
lsblk
```
```console
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk 
├─sda1                    8:1    0    1M  0 part 
├─sda2                    8:2    0    1G  0 part /boot
└─sda3                    8:3    0   39G  0 part 
  ├─VolGroup00-LogVol00 253:0    0 37.5G  0 lvm  /
  └─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
sdb                       8:16   0   10G  0 disk 
sdc                       8:32   0    2G  0 disk 
sdd                       8:48   0    1G  0 disk 
sde                       8:64   0    1G  0 disk 
```

Конечное состояние тестового окружения:
```bash
df -h -x tmpfs -x devtmpfs
```
```console
Filesystem                       Size  Used Avail Use% Mounted on
/dev/mapper/VolGroup00-LogVol00  8.0G  677M  7.4G   9% /
/dev/mapper/VolGroup00-lv_home   2.0G   33M  2.0G   2% /home
/dev/mapper/VG01-lv_var          922M  142M  716M  17% /var
/dev/sda2                       1014M   61M  954M   6% /boot
```
```bash
lsblk
```
```console
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk 
├─sda1                    8:1    0    1M  0 part 
├─sda2                    8:2    0    1G  0 part /boot
└─sda3                    8:3    0   39G  0 part 
  ├─VolGroup00-LogVol00 253:0    0    8G  0 lvm  /
  ├─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
  └─VolGroup00-lv_home  253:8    0    2G  0 lvm  /home
sdb                       8:16   0   10G  0 disk 
sdc                       8:32   0    2G  0 disk 
├─VG01-lv_var_rmeta_0   253:3    0    4M  0 lvm  
│ └─VG01-lv_var         253:7    0  952M  0 lvm  /var
└─VG01-lv_var_rimage_0  253:4    0  952M  0 lvm  
  └─VG01-lv_var         253:7    0  952M  0 lvm  /var
sdd                       8:48   0    1G  0 disk 
├─VG01-lv_var_rmeta_1   253:5    0    4M  0 lvm  
│ └─VG01-lv_var         253:7    0  952M  0 lvm  /var
└─VG01-lv_var_rimage_1  253:6    0  952M  0 lvm  
  └─VG01-lv_var         253:7    0  952M  0 lvm  /var
sde                       8:64   0    1G  0 disk 
```

### LVM. Создание снапшота, восстановление со снапшота <a name="snap"></a>  
Необходимо сгенерировать файлы в `/home/`, снять снапшот, удалить часть файлов, восстановиться со снапшота.  

Выполнение этой части задания автоматизировано с помощью сценария [lvm_snapshot_home.sh](https://github.com/che-a/OTUS_LinuxAdministrator/blob/master/lesson_03/lvm_snapshot_home.sh), но т.к. корректное восстановление тома из снапшота производится только на размонтированный раздел, то указанный сценарий необходимо запустить из консоли тестового окружения под пользователем `root` (использование `su` или `sudo` не подходит), чтобы было возможным размонтирование каталога `/home`. Соответственно, сеансы работы с системой других пользователей должны быть завершены.  
```bash
w
```
```console
 09:40:20 up 29 min,  2 users,  load average: 0.00, 0.01, 0.05
USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU WHAT
root     tty1                      09:25   14:44   0.04s  0.04s -bash
vagrant  pts/0    10.0.2.2         09:28    4.00s  0.06s  0.20s sshd: vagrant [priv] 
```
```bash
./lvm_snapshot_home.sh
```
```console
Rounding up size to full physical extent 128.00 MiB
Logical volume "home_snap" created.
Merging of volume VolGroup00/home_snap started.
VolGroup00/lv_home: Merged: 100.00%
```

<details>
   <summary>Вывод содержимого файла отчета:</summary>

```bash
cat report.log
```
```console
********************************************************************************
**** Исходное состояние::
********************************************************************************
==== lsblk ====
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk 
├─sda1                    8:1    0    1M  0 part 
├─sda2                    8:2    0    1G  0 part /boot
└─sda3                    8:3    0   39G  0 part 
  ├─VolGroup00-LogVol00 253:0    0    8G  0 lvm  /
  ├─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
  └─VolGroup00-lv_home  253:2    0    2G  0 lvm  /home
sdb                       8:16   0   10G  0 disk 
sdc                       8:32   0    2G  0 disk 
├─VG01-lv_var_rmeta_0   253:3    0    4M  0 lvm  
│ └─VG01-lv_var         253:7    0  952M  0 lvm  /var
└─VG01-lv_var_rimage_0  253:4    0  952M  0 lvm  
  └─VG01-lv_var         253:7    0  952M  0 lvm  /var
sdd                       8:48   0    1G  0 disk 
├─VG01-lv_var_rmeta_1   253:5    0    4M  0 lvm  
│ └─VG01-lv_var         253:7    0  952M  0 lvm  /var
└─VG01-lv_var_rimage_1  253:6    0  952M  0 lvm  
  └─VG01-lv_var         253:7    0  952M  0 lvm  /var
sde                       8:64   0    1G  0 disk 
==== lvs -v ====
  LV       VG         #Seg Attr       LSize   Maj Min KMaj KMin Pool Origin Data%  Meta%  Move Cpy%Sync Log Convert LV UUID                                LProfile
  lv_var   VG01          1 rwi-aor--- 952.00m  -1  -1  253    7                                100.00               hcVQrX-4voe-if6k-jW8V-PZO9-pW62-FeHWMF         
  LogVol00 VolGroup00    1 -wi-ao----   8.00g  -1  -1  253    0                                                     yVRfXr-YQoA-x4m8-kRwR-NdvF-O2ZZ-ylw5Lv         
  LogVol01 VolGroup00    1 -wi-ao----   1.50g  -1  -1  253    1                                                     IAjIC6-ScnM-tvH6-7BTy-TN31-hd82-bgDSzd         
  lv_home  VolGroup00    1 -wi-ao----   2.00g  -1  -1  253    2                                                     j4lARa-6US5-9huS-Exdr-DT0y-R298-DZjIqM         
==== ls -al /home ====
total 0
drwxr-xr-x.  3 root    root     21 Sep  5 09:10 .
drwxr-xr-x. 18 root    root    239 Sep  5 09:10 ..
drwx------.  3 vagrant vagrant 152 Sep  5 09:24 vagrant
********************************************************************************
**** Создание тестовых файлов::
********************************************************************************
==== lsblk ====
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk 
├─sda1                    8:1    0    1M  0 part 
├─sda2                    8:2    0    1G  0 part /boot
└─sda3                    8:3    0   39G  0 part 
  ├─VolGroup00-LogVol00 253:0    0    8G  0 lvm  /
  ├─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
  └─VolGroup00-lv_home  253:2    0    2G  0 lvm  /home
sdb                       8:16   0   10G  0 disk 
sdc                       8:32   0    2G  0 disk 
├─VG01-lv_var_rmeta_0   253:3    0    4M  0 lvm  
│ └─VG01-lv_var         253:7    0  952M  0 lvm  /var
└─VG01-lv_var_rimage_0  253:4    0  952M  0 lvm  
  └─VG01-lv_var         253:7    0  952M  0 lvm  /var
sdd                       8:48   0    1G  0 disk 
├─VG01-lv_var_rmeta_1   253:5    0    4M  0 lvm  
│ └─VG01-lv_var         253:7    0  952M  0 lvm  /var
└─VG01-lv_var_rimage_1  253:6    0  952M  0 lvm  
  └─VG01-lv_var         253:7    0  952M  0 lvm  /var
sde                       8:64   0    1G  0 disk 
==== lvs -v ====
  LV       VG         #Seg Attr       LSize   Maj Min KMaj KMin Pool Origin Data%  Meta%  Move Cpy%Sync Log Convert LV UUID                                LProfile
  lv_var   VG01          1 rwi-aor--- 952.00m  -1  -1  253    7                                100.00               hcVQrX-4voe-if6k-jW8V-PZO9-pW62-FeHWMF         
  LogVol00 VolGroup00    1 -wi-ao----   8.00g  -1  -1  253    0                                                     yVRfXr-YQoA-x4m8-kRwR-NdvF-O2ZZ-ylw5Lv         
  LogVol01 VolGroup00    1 -wi-ao----   1.50g  -1  -1  253    1                                                     IAjIC6-ScnM-tvH6-7BTy-TN31-hd82-bgDSzd         
  lv_home  VolGroup00    1 -wi-ao----   2.00g  -1  -1  253    2                                                     j4lARa-6US5-9huS-Exdr-DT0y-R298-DZjIqM         
==== ls -al /home ====
total 80
drwxr-xr-x.  3 root    root    292 Sep  5 09:25 .
drwxr-xr-x. 18 root    root    239 Sep  5 09:10 ..
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file1
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file10
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file11
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file12
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file13
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file14
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file15
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file16
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file17
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file18
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file19
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file2
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file20
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file3
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file4
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file5
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file6
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file7
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file8
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file9
drwx------.  3 vagrant vagrant 152 Sep  5 09:24 vagrant
********************************************************************************
**** После создания снапшота::
********************************************************************************
==== lsblk ====
NAME                         MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                            8:0    0   40G  0 disk 
├─sda1                         8:1    0    1M  0 part 
├─sda2                         8:2    0    1G  0 part /boot
└─sda3                         8:3    0   39G  0 part 
  ├─VolGroup00-LogVol00      253:0    0    8G  0 lvm  /
  ├─VolGroup00-LogVol01      253:1    0  1.5G  0 lvm  [SWAP]
  ├─VolGroup00-lv_home-real  253:8    0    2G  0 lvm  
  │ ├─VolGroup00-lv_home     253:2    0    2G  0 lvm  /home
  │ └─VolGroup00-home_snap   253:10   0    2G  0 lvm  
  └─VolGroup00-home_snap-cow 253:9    0  128M  0 lvm  
    └─VolGroup00-home_snap   253:10   0    2G  0 lvm  
sdb                            8:16   0   10G  0 disk 
sdc                            8:32   0    2G  0 disk 
├─VG01-lv_var_rmeta_0        253:3    0    4M  0 lvm  
│ └─VG01-lv_var              253:7    0  952M  0 lvm  /var
└─VG01-lv_var_rimage_0       253:4    0  952M  0 lvm  
  └─VG01-lv_var              253:7    0  952M  0 lvm  /var
sdd                            8:48   0    1G  0 disk 
├─VG01-lv_var_rmeta_1        253:5    0    4M  0 lvm  
│ └─VG01-lv_var              253:7    0  952M  0 lvm  /var
└─VG01-lv_var_rimage_1       253:6    0  952M  0 lvm  
  └─VG01-lv_var              253:7    0  952M  0 lvm  /var
sde                            8:64   0    1G  0 disk 
==== lvs -v ====
  LV        VG         #Seg Attr       LSize   Maj Min KMaj KMin Pool Origin  Data%  Meta%  Move Cpy%Sync Log Convert LV UUID                                LProfile
  lv_var    VG01          1 rwi-aor--- 952.00m  -1  -1  253    7                                 100.00               hcVQrX-4voe-if6k-jW8V-PZO9-pW62-FeHWMF         
  LogVol00  VolGroup00    1 -wi-ao----   8.00g  -1  -1  253    0                                                      yVRfXr-YQoA-x4m8-kRwR-NdvF-O2ZZ-ylw5Lv         
  LogVol01  VolGroup00    1 -wi-ao----   1.50g  -1  -1  253    1                                                      IAjIC6-ScnM-tvH6-7BTy-TN31-hd82-bgDSzd         
  home_snap VolGroup00    1 swi-a-s--- 128.00m  -1  -1  253   10      lv_home 0.00                                    faynnc-JyTu-p1cb-Bcku-QH0v-SrBh-79beKN         
  lv_home   VolGroup00    1 owi-aos---   2.00g  -1  -1  253    2                                                      j4lARa-6US5-9huS-Exdr-DT0y-R298-DZjIqM         
==== ls -al /home ====
total 80
drwxr-xr-x.  3 root    root    292 Sep  5 09:25 .
drwxr-xr-x. 18 root    root    239 Sep  5 09:10 ..
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file1
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file10
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file11
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file12
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file13
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file14
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file15
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file16
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file17
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file18
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file19
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file2
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file20
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file3
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file4
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file5
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file6
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file7
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file8
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file9
drwx------.  3 vagrant vagrant 152 Sep  5 09:24 vagrant
********************************************************************************
**** Удаление части тестовых файлов::
********************************************************************************
==== lsblk ====
NAME                         MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                            8:0    0   40G  0 disk 
├─sda1                         8:1    0    1M  0 part 
├─sda2                         8:2    0    1G  0 part /boot
└─sda3                         8:3    0   39G  0 part 
  ├─VolGroup00-LogVol00      253:0    0    8G  0 lvm  /
  ├─VolGroup00-LogVol01      253:1    0  1.5G  0 lvm  [SWAP]
  ├─VolGroup00-lv_home-real  253:8    0    2G  0 lvm  
  │ ├─VolGroup00-lv_home     253:2    0    2G  0 lvm  /home
  │ └─VolGroup00-home_snap   253:10   0    2G  0 lvm  
  └─VolGroup00-home_snap-cow 253:9    0  128M  0 lvm  
    └─VolGroup00-home_snap   253:10   0    2G  0 lvm  
sdb                            8:16   0   10G  0 disk 
sdc                            8:32   0    2G  0 disk 
├─VG01-lv_var_rmeta_0        253:3    0    4M  0 lvm  
│ └─VG01-lv_var              253:7    0  952M  0 lvm  /var
└─VG01-lv_var_rimage_0       253:4    0  952M  0 lvm  
  └─VG01-lv_var              253:7    0  952M  0 lvm  /var
sdd                            8:48   0    1G  0 disk 
├─VG01-lv_var_rmeta_1        253:5    0    4M  0 lvm  
│ └─VG01-lv_var              253:7    0  952M  0 lvm  /var
└─VG01-lv_var_rimage_1       253:6    0  952M  0 lvm  
  └─VG01-lv_var              253:7    0  952M  0 lvm  /var
sde                            8:64   0    1G  0 disk 
==== lvs -v ====
  LV        VG         #Seg Attr       LSize   Maj Min KMaj KMin Pool Origin  Data%  Meta%  Move Cpy%Sync Log Convert LV UUID                                LProfile
  lv_var    VG01          1 rwi-aor--- 952.00m  -1  -1  253    7                                 100.00               hcVQrX-4voe-if6k-jW8V-PZO9-pW62-FeHWMF         
  LogVol00  VolGroup00    1 -wi-ao----   8.00g  -1  -1  253    0                                                      yVRfXr-YQoA-x4m8-kRwR-NdvF-O2ZZ-ylw5Lv         
  LogVol01  VolGroup00    1 -wi-ao----   1.50g  -1  -1  253    1                                                      IAjIC6-ScnM-tvH6-7BTy-TN31-hd82-bgDSzd         
  home_snap VolGroup00    1 swi-a-s--- 128.00m  -1  -1  253   10      lv_home 0.00                                    faynnc-JyTu-p1cb-Bcku-QH0v-SrBh-79beKN         
  lv_home   VolGroup00    1 owi-aos---   2.00g  -1  -1  253    2                                                      j4lARa-6US5-9huS-Exdr-DT0y-R298-DZjIqM         
==== ls -al /home ====
total 40
drwxr-xr-x.  3 root    root    152 Sep  5 09:25 .
drwxr-xr-x. 18 root    root    239 Sep  5 09:10 ..
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file1
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file10
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file2
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file3
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file4
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file5
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file6
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file7
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file8
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file9
drwx------.  3 vagrant vagrant 152 Sep  5 09:24 vagrant
********************************************************************************
**** После восстановления из снапшота::
********************************************************************************
==== lsblk ====
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk 
├─sda1                    8:1    0    1M  0 part 
├─sda2                    8:2    0    1G  0 part /boot
└─sda3                    8:3    0   39G  0 part 
  ├─VolGroup00-LogVol00 253:0    0    8G  0 lvm  /
  ├─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
  └─VolGroup00-lv_home  253:2    0    2G  0 lvm  /home
sdb                       8:16   0   10G  0 disk 
sdc                       8:32   0    2G  0 disk 
├─VG01-lv_var_rmeta_0   253:3    0    4M  0 lvm  
│ └─VG01-lv_var         253:7    0  952M  0 lvm  /var
└─VG01-lv_var_rimage_0  253:4    0  952M  0 lvm  
  └─VG01-lv_var         253:7    0  952M  0 lvm  /var
sdd                       8:48   0    1G  0 disk 
├─VG01-lv_var_rmeta_1   253:5    0    4M  0 lvm  
│ └─VG01-lv_var         253:7    0  952M  0 lvm  /var
└─VG01-lv_var_rimage_1  253:6    0  952M  0 lvm  
  └─VG01-lv_var         253:7    0  952M  0 lvm  /var
sde                       8:64   0    1G  0 disk 
==== lvs -v ====
  LV       VG         #Seg Attr       LSize   Maj Min KMaj KMin Pool Origin Data%  Meta%  Move Cpy%Sync Log Convert LV UUID                                LProfile
  lv_var   VG01          1 rwi-aor--- 952.00m  -1  -1  253    7                                100.00               hcVQrX-4voe-if6k-jW8V-PZO9-pW62-FeHWMF         
  LogVol00 VolGroup00    1 -wi-ao----   8.00g  -1  -1  253    0                                                     yVRfXr-YQoA-x4m8-kRwR-NdvF-O2ZZ-ylw5Lv         
  LogVol01 VolGroup00    1 -wi-ao----   1.50g  -1  -1  253    1                                                     IAjIC6-ScnM-tvH6-7BTy-TN31-hd82-bgDSzd         
  lv_home  VolGroup00    1 -wi-ao----   2.00g  -1  -1  253    2                                                     j4lARa-6US5-9huS-Exdr-DT0y-R298-DZjIqM         
==== ls -al /home ====
total 80
drwxr-xr-x.  3 root    root    292 Sep  5 09:25 .
drwxr-xr-x. 18 root    root    239 Sep  5 09:10 ..
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file1
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file10
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file11
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file12
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file13
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file14
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file15
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file16
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file17
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file18
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file19
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file2
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file20
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file3
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file4
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file5
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file6
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file7
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file8
-rw-r--r--.  1 root    root     37 Sep  5 09:25 file9
drwx------.  3 vagrant vagrant 152 Sep  5 09:24 vagrant
```
</details>

### ZFS. Использование кэша и снапшотов <a name="zfs"></a>  
В этой части домашнего задания (&laquo;поставить btrfs/zfs - с кешем, снапшотами - разметить здесь каталог `/opt` &raquo;) рассматривается установка и использование [OpenZFS](http://open-zfs.org/wiki/Main_Page).
