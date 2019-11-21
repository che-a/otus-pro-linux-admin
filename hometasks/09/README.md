## Автоматизация администрирования. Ansible
### Содержание
1. [Описание занятия](#description)  
2. [Домашнее задание](#homework)  
3. [Справочная информация](#info)  
    - [Ссылки на полезные ресурсы](#links)
4. [Выполнение](#exec)  
    - [Описание лабораторного стенда](#stand)  
    - [Задача 2](#task2)   

## 1. Описание занятия <a name="description"></a>
### Цели
- Автоматизируем рутинные задачи администрирования.  
- Изучаем `Ansible` - хосты, модули, плейбуки, роли, переменные.  
- Знакомимся с другими инструментами - `chef`, `puppet`, `salt`.

### Результаты  
- Уастники осваивают популярный и полезный инструмент администратора - `Ansible`.  
- Могут с помощью него изменить конфиги, установить дополнительный софт и другие действия.  

## 2. Домашнее задание  <a name="homework"></a>
### Постановка задачи 
Подготовить стенд на `Vagrant` как минимум с одним сервером. На этом сервере, используя `Ansible`, необходимо развернуть `nginx` со следующими условиями:
- необходимо использовать модуль `yum` / `apt`;  
- конфигурационные файлы должны быть взяты из шаблона `jinja2` с перемененными;  
- после установки `nginx` должен быть в режиме `enabled` в `systemd`;  
- должен быть использован `notify` для старта `nginx` после установки;  
- сайт должен слушать на нестандартном порту - 8080, для этого использовать переменные в `Ansible`.  
#### Дополнительно
- Сделать все это с использованием `Ansible`-роли.  

#### Критерии оценки:  
Ставим 5 если создан `playbook`;  
Ставим 6 если написана роль.  

## 3. Справочная информация <a name="info"></a>  



`Инвентарный файл` — это файл, в котором описываются устройства, к которым `Ansible` будет подключаться. По умолчанию он находится в `/etc/ansible/hosts`.

Но можно создавать свой инвентарный файл и использовать его. Для этого нужно, либо указать его при запуске ansible, используя опцию -i <путь>, либо указать файл в конфигурационном файле Ansible.

Часто инвентарный файл размещают в каталоге inventories, который создают в корне каталога с playbook. Это дает возможность хранить информацию про хосты вместе с остальной информацией в системе контроля версий.

`ansible-doc --list` — список доступных модулей;  
`ansible-galaxy init roles/модуль`— уставновить `модуль`;  

`ansible-inventory --graph`  
`ansible-inventory --list`  


`ansible centos -m yum -a "name=tree state=present" -b` — установить пакет `tree`;  
`ansible all -m file -a "path=/etc/otus state=touch" -b` — создать файл `/etc/otus`;  
`ansible -m setup all` — всевозможная информация о хостах;  
`ansible-playbook playbooks/nginx.yml --list-hosts` — список хостов, с которым будет работать `playbook`;  
`ansible centos -m yum -a "name=nginx state=absent" -b` — удаление пакета;  
`ansible-playbook playbook.yml --list-tags` — список тегов;  
`ansible-playbook playbook.yml --list-tasks` — список задач;  
`ansible-galaxy init roles/nginx` — создание своей роли;  

Если нужны переменные окружения и пайпы, то необходимо использовать модуль `shell`.  
```bash
ansible srv -m shell -a "cat /proc/cpuinfo | grep -i │ name"
```
```console
srv1 | CHANGED | rc=0 >> 
model name      : Intel(R) Xeon(R) CPU           E5450  @ 3.00GHz

srv2 | CHANGED | rc=0 >>
model name      : Intel(R) Xeon(R) CPU           E5450  @ 3.00GHz

srv3 | CHANGED | rc=0 >>
model name      : Intel(R) Xeon(R) CPU           E5450  @ 3.00GHz

srv4 | CHANGED | rc=0 >>
model name      : Intel(R) Xeon(R) CPU           E5450  @ 3.00GHz
```

`ansible -m setup srv` - просомтр информации о хостах.   
`ansible-lint playbook.yml` - отдельная программа для проверки корректности синтаксиса `playbook`-файла.  


```bash
```
```console
```
```bash
```
```

```


Для настройки `Ansible` используется файл конфигурации `ansible.cfg`, который может находиться в следующих местах:  
- `./ansible.cfg` — текущий каталог;  
- `~/.ansible.cfg` — домашний каталог;  
- `/etc/ansible/ansible.cfg` — каталог, созданный при установке через менеджер пакетов.  

Наиболее часто используемые параметры файла конфигурации `ansible.cfg`:  
- `inventory` — путь к `inventory`-файлу, содержащему список ip-адресов (или имен) хостов для подключения;  
- `library` — путь к модулям `Ansible`;  
- `forks` — кол-во потоков, которые может создать `Ansible`;  
- `sudo_user` — пользователь, от которого запускаются команды/инструкции на удаленных хостах;  
- `remote_port` — порт для подключения по протоколу `SSH`;  
- `host_key_checking` — включить/отключить проверку `SSH`–ключа на удаленном хосте;  
- `timeout` — таймаут подключения по `SSH`;  
- `log_path` — путь к файлу логов.  

#### Ссылки на полезные ресурсы <a name="links"></a>
[Ansible Documentation](https://docs.ansible.com/ansible/latest/index.html) — официальная документация по `Ansible`;  
[Galaxy](https://galaxy.ansible.com/) — готовые модули;  
[ansible.cfg](https://raw.githubusercontent.com/ansible/ansible/devel/examples/ansible.cfg) — пример конфигурации файла `ansible.cfg` от разработчиков;  


## 4. Выполнение <a name="exec"></a>  

### Описание лабораторного стенда <a name="stand"></a>  
Лабораторный стенд разворачивается из [Vagrantfile](https://github.com/che-a/OTUS_LinuxAdministrator/blob/master/hometasks/09/Vagrantfile) с последующим провижинингом из сценария [provision.sh](https://github.com/che-a/OTUS_LinuxAdministrator/blob/master/hometasks/09/provision.sh) и состоит из трех виртуальных машин:  
- `ansible`, подготовленный для оркестрации остальных виртуальных машин сервер `Ansible`;  
- `srv1`, виртуальная машина с ОС `CentOS 7`;  
- `srv2`, виртуальная машина с ОС `Debian 10`.  

В стенде настроен `SSH`-додступ по ключам с `ansible` на `srv1` и `srv2`, ввод пароля не требуется, к машинам возможно обращение по имени хоста. Т.о. `Ansible`-сервер готов сразу после своего развертывания, в чем можно убедиться выполнив следующую команду:
```bash
ansible srv -m ping
```
```console
[WARNING]: Platform linux on host srv2 is using the discovered Python interpreter at /usr/bin/python, but future installation of another Python interpreter could change this. See
https://docs.ansible.com/ansible/2.9/reference_appendices/interpreter_discovery.html for more information.

srv2 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    }, 
    "changed": false, 
    "ping": "pong"
}
srv1 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    }, 
    "changed": false, 
    "ping": "pong"
}
```


```console

```






```bash
```
```console

```

### Задача 2 <a name="task2"></a>  

```bash
```
```console

```
  
```bash
```
```console

```

```bash

```
```console

```
