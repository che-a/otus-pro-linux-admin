## Инициализация системы. Systemd и SysV
### Содержание
1. [Описание занятия](#description)  
2. [Домашнее задание](#homework)  
3. [Справочная информация](#info)  
4. [Выполнение](#exec)  
    - 4.1 [Вход в систему без пароля](#nopass)  
    - 4.2 [LVM, переименование VG](#lvm)
    - 4.3 [Добавление модуля в initrd](#initrd)   

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
Студент может написать свой systemd unit.

## 2. Домашнее задание  <a name="homework"></a>
### Постановка задачи 
Systemd
Цель: Управление автозагрузкой сервисов происходит через systemd. Вместо cron'а тоже используется systemd. И много других возможностей. В ДЗ нужно написать свой systemd-unit.
1. Написать сервис, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова. Файл и слово должны задаваться в /etc/sysconfig
2. Из epel установить spawn-fcgi и переписать init-скрипт на unit-файл. Имя сервиса должно так же называться.
3. Дополнить юнит-файл apache httpd возможностьб запустить несколько инстансов сервера с разными конфигами
4*. Скачать демо-версию Atlassian Jira и переписать основной скрипт запуска на unit-файл
Задание необходимо сделать с использованием Vagrantfile и proviosioner shell (или ansible, на Ваше усмотрение) 

## 3. Справочная информация <a name="info"></a>  
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
## 4. Выполнение <a name="exec"></a>  

### 4.1 Вход в систему без пароля  <a name="nopass"></a>  


### 4.2 LVM, переименование VG  <a name="lvm"></a>  


### 4.3 Добавление модуля в initrd  <a name="initrd"></a>  

