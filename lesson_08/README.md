## Инициализация системы. Systemd и SysV
### Содержание
1. [Описание занятия](#description)  
2. [Домашнее задание](#homework)  
3. [Справочная информация](#info)  
4. [Выполнение](#exec)  
    - [Задача 1](#task1)  
    - [Задача 2](#task2)
    - [Задача 3](#task3)   

## 1. Описание занятия <a name="description"></a>
### Цели
- Учимся писать сценарии автозагрузки демонов.  
- Изучаем разницу между systemd и SysV.  
- Учимся обращаться с `systemctl` и `journalctl`.  

### Краткое содержание    
- Init,  
- SysV services,  
- Systemd.   

### Результаты  
Студент может написать свой systemd-модуль.

## 2. Домашнее задание  <a name="homework"></a>
### Постановка задачи 

Управление автозагрузкой сервисов происходит через systemd. Вместо cron'а тоже используется systemd. И много других возможностей. В ДЗ нужно написать свой systemd-unit.
1. Написать сервис, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова. Файл и слово должны задаваться в `/etc/sysconfig`.  
2. Из `epel` установить `spawn-fcgi` и переписать `init`-скрипт на unit-файл. Имя сервиса должно так же называться.
3. Дополнить юнит-файл apache `httpd` возможностью запустить несколько инстансов сервера с разными конфигами.  
#### Дополнительно
4. Скачать демо-версию Atlassian Jira и переписать основной скрипт запуска на unit-файл.  

Задание необходимо сделать с использованием Vagrantfile и proviosioner shell (или ansible, на Ваше усмотрение). 

## 3. Справочная информация <a name="info"></a>  

<details>
    <summary></summary>

#### System V

`who -r` - Уровень запуска,  

`/etc/rc.local` - выполняется после того, как отработают все init-скрипты;  
`/etc/inittab` -   
`service sshd status` -  

#### systemd

`/usr/lib/systemd/system` - каталог системных модулей;  
`/etc/systemd/system` - каталог системной конфигурации;  
`/etc/systemd/systemd.conf` - основной конфигурационный файл;  

`systemctl cat unit` - просмотр исходного кода модуля unit;  
`systemctl list-jobs` - список текущих заданий;  
`systemctl list-units` - список активных модулей;  
`systemctl list-units --all` - список всех модулей;  
`systemctl list-units --full` - список активных модулей с отображением их полных имен;  

`systemctl reload unit` - перезагружает только конфигурацию модуля `unit`;  
`systemctl deamon-reload` - перезагружает конфигурацию всех модулей.  

`journalctl _SYSTEMD_UNIT=` - полный журнал модуля;  

```bash
systemd-analyze time
```
```console
Startup finished in 424ms (kernel) + 1.390s (initrd) + 7.598s (userspace) = 9.413s
```
```bash
systemd-analyze blame
```
```
          3.235s network.service
          2.579s dev-sda1.device
          2.572s sshd-keygen.service
          1.034s tuned.service
           939ms systemd-hwdb-update.service
           911ms postfix.service
           609ms swapfile.swap
           522ms systemd-vconsole-setup.service
           483ms chronyd.service
           472ms polkit.service
           464ms systemd-logind.service
           404ms rpcbind.service
           403ms rhel-dmesg.service
           380ms gssproxy.service
           319ms auditd.service
           240ms systemd-udevd.service
           190ms systemd-tmpfiles-setup.service
```

</details>

## 4. Выполнение <a name="exec"></a>  
Для демонстрации выполнения этого домашнего задания необходимо развернуть тестовое окружение из [Vagrantfile](https://github.com/che-a/OTUS_LinuxAdministrator/blob/master/lesson_08/Vagrantfile). С целью не создавать монстроподобные сценарии провижининга, которые в себе содержат команды по созданию и редактированию множества файлов, все необходимые конфигурационные файлы собраны в каталог [include](https://github.com/che-a/OTUS_LinuxAdministrator/tree/master/lesson_08/include), откуда они рекурсивно копируются в файловую систему виртуальной машины при работе сценария провижининга [script.sh](https://github.com/che-a/OTUS_LinuxAdministrator/blob/master/lesson_08/script.sh).
```console
include/
├── etc
│   ├── sysconfig
│   │   ├── generator
│   │   ├── httpd-inst1
│   │   ├── httpd-inst2
│   │   └── watcher
│   └── systemd
│       └── system
│           ├── generator.service
│           ├── generator.timer
│           ├── httpd@.service
│           ├── spawn-fcgi.service
│           ├── watcher.service
│           └── watcher.timer
└── opt
    ├── generator.sh
    └── watcher.sh
```


### Задача 1 <a name="task1"></a>  
Сценарий [generator.sh](https://github.com/che-a/OTUS_LinuxAdministrator/blob/master/lesson_08/include/opt/generator.sh) запускается с определенными параметрами через `systemd`-модуль [generator.service](https://github.com/che-a/OTUS_LinuxAdministrator/blob/master/lesson_08/include/etc/systemd/system/generator.service) `systemd`-таймером [generator.timer](https://github.com/che-a/OTUS_LinuxAdministrator/blob/master/lesson_08/include/etc/systemd/system/generator.timer) и записывает ключевое слово в свой лог. Аналогичным образом действует сценарий [watcher.sh](https://github.com/che-a/OTUS_LinuxAdministrator/blob/master/lesson_08/include/opt/watcher.sh), который каждые 30 секунд подсчитывает количество ключевых слов в логе генератора и посылает сообщение с этой информацией в системный лог.

```bash
sudo tail -f /var/log/generator.log  
```
```console
Sun Nov 17 20:07:41 UTC 2019 - ALERT! Need to do homework faster !!!
Sun Nov 17 20:08:18 UTC 2019 - ALERT! Need to do homework faster !!!
Sun Nov 17 20:08:48 UTC 2019 - ALERT! Need to do homework faster !!!
Sun Nov 17 20:09:18 UTC 2019 - ALERT! Need to do homework faster !!!
Sun Nov 17 20:09:48 UTC 2019 - ALERT! Need to do homework faster !!!
Sun Nov 17 20:10:18 UTC 2019 - ALERT! Need to do homework faster !!!
Sun Nov 17 20:10:48 UTC 2019 - ALERT! Need to do homework faster !!!
Sun Nov 17 20:11:18 UTC 2019 - ALERT! Need to do homework faster !!!
Sun Nov 17 20:11:48 UTC 2019 - ALERT! Need to do homework faster !!!
```

```bash
sudo tail -f /var/log/messages 
```
```console
Nov 17 20:10:18 localhost systemd: Started Log generator for watcher.
Nov 17 20:10:18 localhost root: Sun Nov 17 20:10:18 UTC 2019: I found 5 word(s), Che!
Nov 17 20:10:34 localhost systemd: Created slice User Slice of vagrant.
Nov 17 20:10:34 localhost systemd-logind: New session 4 of user vagrant.
Nov 17 20:10:34 localhost systemd: Started Session 4 of user vagrant.
Nov 17 20:10:48 localhost systemd: Started Log generator for watcher.
Nov 17 20:10:48 localhost systemd: Started My watcher service.
Nov 17 20:10:48 localhost root: Sun Nov 17 20:10:48 UTC 2019: I found 6 word(s), Che!
Nov 17 20:11:04 localhost systemd: Started Session 5 of user vagrant.
Nov 17 20:11:04 localhost systemd-logind: New session 5 of user vagrant.
Nov 17 20:11:18 localhost systemd: Started Log generator for watcher.
Nov 17 20:11:18 localhost systemd: Started My watcher service.
Nov 17 20:11:18 localhost root: Sun Nov 17 20:11:18 UTC 2019: I found 7 word(s), Che!
Nov 17 20:11:48 localhost systemd: Started Log generator for watcher.
Nov 17 20:11:48 localhost systemd: Started My watcher service.
Nov 17 20:11:48 localhost root: Sun Nov 17 20:11:48 UTC 2019: I found 9 word(s), Che!
```

### Задача 2 <a name="task2"></a>  
Собственно, состояние получившегося`systemd`-модуля [spawn-fcgi](https://github.com/che-a/OTUS_LinuxAdministrator/blob/master/lesson_08/include/etc/systemd/system/spawn-fcgi.service):
```bash
systemctl status spawn-fcgi.service
```
```console
● spawn-fcgi.service - Spawn-fcgi startup service by Otus
   Loaded: loaded (/etc/systemd/system/spawn-fcgi.service; enabled; vendor preset: disabled)
   Active: active (running) since Sun 2019-11-17 20:07:58 UTC; 27min ago
 Main PID: 4639 (php-cgi)
   CGroup: /system.slice/spawn-fcgi.service
           ├─4639 /usr/bin/php-cgi
           ├─4657 /usr/bin/php-cgi
           ├─4658 /usr/bin/php-cgi
           ├─4659 /usr/bin/php-cgi
           ├─4660 /usr/bin/php-cgi
           ├─4661 /usr/bin/php-cgi
           ├─4662 /usr/bin/php-cgi
           ├─4663 /usr/bin/php-cgi
           ├─4664 /usr/bin/php-cgi
           ├─4665 /usr/bin/php-cgi
           ├─4666 /usr/bin/php-cgi
           ├─4667 /usr/bin/php-cgi
           ├─4668 /usr/bin/php-cgi
           ├─4669 /usr/bin/php-cgi
           ├─4670 /usr/bin/php-cgi
           ├─4671 /usr/bin/php-cgi
           ├─4672 /usr/bin/php-cgi
           ├─4673 /usr/bin/php-cgi
           ├─4674 /usr/bin/php-cgi
           ├─4675 /usr/bin/php-cgi
           ├─4676 /usr/bin/php-cgi
           ├─4677 /usr/bin/php-cgi
           ├─4678 /usr/bin/php-cgi
           ├─4679 /usr/bin/php-cgi
           ├─4680 /usr/bin/php-cgi
           ├─4681 /usr/bin/php-cgi
           ├─4682 /usr/bin/php-cgi
           ├─4683 /usr/bin/php-cgi
           ├─4684 /usr/bin/php-cgi
           ├─4685 /usr/bin/php-cgi
           ├─4686 /usr/bin/php-cgi
           ├─4687 /usr/bin/php-cgi
           └─4688 /usr/bin/php-cgi
```

### Задача 3 <a name="task3"></a>  

