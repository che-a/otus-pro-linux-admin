# OTUS_LinuxAdministration
В этом репозитории находятся выполненные мною задания по курсу "Администрирование Linux" на платформе OTUS.

Задания находятся в отдельных подкаталогах типа `lesson_xx`, в каждом из которых есть файл `README.md` с детальным описанием условия задачи и хода ее выполнения.

### Содержание <hr>
1. Занятие 1. С  чего начинается Linux
+ [Домашнее задание](#lesson_01)
+ [Выполнение](https://github.com/che-a/OTUS_LinuxAdministration/blob/master/lesson_01/README.md)
2. Занятие 2. Дисковая подсистема
+ [Домашнее задание](#lesson_02)
+ [Выполнение](https://github.com/che-a/OTUS_LinuxAdministration/blob/master/lesson_02/README.md)
3. Занятие 3. Файловые системы и LVM
+ [Домашнее задание](#lesson_03)
+ [Выполнение](https://github.com/che-a/OTUS_LinuxAdministration/blob/master/lesson_03/README.md)


### Занятие 1. С  чего начинается Linux <a name="lesson_01"></a> <hr>
**Домашнее задание**. Сборка ядра.
- Взять любую версию ядра с kernel.org.
- Подложить файл конфигурации ядра.
- Собрать ядро (попутно доставляя необходимые пакеты).
- Прислать результирующий файл конфигурации.
- Прислать список доустановленных пакетов (взять его можно из /var/log/yum.log).

### Занятие 2. Дисковая подсистема <a name="lesson_02"></a> <hr>
**Домашнее задание**. Работа с mdadm.
- добавить в Vagrantfile еще дисков;
- сломать/починить raid;
- собрать R0/R5/R10 - на выбор;
- создать на рейде GPT раздел и 5 партиций;
- в качестве проверки принимаются: измененный Vagrantfile, скрипт для создания рейда;
- доп. задание: Vagrantfile, который сразу собирает систему с подключенным рейдом;
- перенесети работающую систему с одним диском на RAID 1. Даунтайм на загрузку с нового диска предполагается.

### Занятие 3. Файловые системы и LVM <a name="lesson_03"></a> <hr>
**Домашнее задание**. Работа с LVM.
На имеющемся образе /dev/mapper/VolGroup00-LogVol00 38G 738M 37G 2% /
- уменьшить том под / до 8G
- выделить том под /home
- выделить том под /var
- /var - сделать в mirror
- /home - сделать том для снэпшотов
- прописать монтирование в fstab
    - попробовать с разными опциями и разными файловыми системами ( на выбор)
    - сгенерить файлы в /home/
    - снять снэпшот
    - удалить часть файлов
    - восстановится со снэпшота
    - залоггировать работу можно с помощью утилиты script
- на нашей куче дисков попробовать поставить btrfs/zfs - с кешем, снэпшотами - разметить здесь каталог /opt
