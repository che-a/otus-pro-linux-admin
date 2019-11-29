## Занятие 15. Docker
### Содержание
1. [Описание занятия](#description)  
2. [Домашнее задание](#homework)  
3. [Справочная информация](#info)  
4. [Выполнение](#exec)  

## 1. Описание занятия <a name="description"></a>
### Цели
- Обсуждаем политики и методики резервного копирования.  
- Разбираем некоторые особенности утилит `rsync`, `dd`, `tar`.  
- Практика работы с `BorgBackup`.   

## 2. Домашнее задание  <a name="homework"></a>
### Постановка задачи
Настроить стенд `Vagrant` с двумя виртуальными машинами: server и client.

Настроить политику бэкапа директории `/etc` с клиента:
1) Полный бэкап - раз в день
2) Инкрементальный - каждые 10 минут
3) Дифференциальный - каждые 30 минут

Запустить систему на два часа. Для сдачи ДЗ приложить `list jobs`, `list files jobid=<id>` и сами конфиги bacula-*.

### Дополнительно
Настроить доп. опции - сжатие, шифрование, дедупликация   

## 3. Справочная информация <a name="info"></a>  

<details>
   <summary></summary>
   


</details>

## 4. Выполнение <a name="exec"></a>  

Лабораторный стенд, состоящий из двух объединенных в одну сеть машин, разворачивается из [Vagrantfile](https://github.com/che-a/OTUS_LinuxAdministrator/blob/master/tasks/14/Vagrantfile) с последующим минимальным провижинингом из сценария [provision.sh](https://github.com/che-a/OTUS_LinuxAdministrator/blob/master/tasks/14/provision.sh), суть которого заключается в настройке беспарольного `SSH`-доступа с машины `server` на машину `client1`.  Дальнейшая настройка на этих машинах сервера и клиента системы `Bacula` проводится средствами `Ansible`, для чего необходимо выполнить команду:
```bash
cd ansible-bacula/ && ansible-playbook playbooks/install_bacula.yml
```

Конфигурационные файлы `Bacula` представлены в виде `Jinja`-шаблонов и составлены из оригинальных [файлов](https://github.com/che-a/OTUS_LinuxAdministrator/tree/master/tasks/14/orig_conf_files), доступных сразу после установки `Bacula`.  

Сервер:  
- `bacula-dir.conf`, [файл](https://github.com/che-a/OTUS_LinuxAdministrator/blob/master/tasks/14/ansible-bacula/roles/bacula/templates/server_bacula-dir.conf.j2)  
- `bacula-sd.conf`, [файл](https://github.com/che-a/OTUS_LinuxAdministrator/blob/master/tasks/14/ansible-bacula/roles/bacula/templates/server_bacula-sd.conf.j2)  

Клиент:  
- `bacula-fd.conf`, [файл](https://github.com/che-a/OTUS_LinuxAdministrator/blob/master/tasks/14/ansible-bacula/roles/bacula/templates/client_bacula-fd.conf.j2)  

Время выполнения операций резрвного копирования определяется в следующем фрагменте кода [файла](https://github.com/che-a/OTUS_LinuxAdministrator/blob/master/tasks/14/ansible-bacula/roles/bacula/templates/server_bacula-dir.conf.j2) `bacula-dir.conf`:  
```console

```

Результаты выполнения команд в программе `bconsole`:
```bash
list jobs
```
```console

```

```bash
list files jobid=12
```
