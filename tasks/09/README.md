## Автоматизация администрирования. Ansible
### Содержание
1. [Описание занятия](#description)  
2. [Домашнее задание](#homework)  
3. [Справочная информация](#info)  
    - [Ссылки на полезные ресурсы](#links)
4. [Выполнение](#exec)  
    - [Описание лабораторного стенда](#stand)  
    - [Результаты](#result)   

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

<details>
    <summary></summary>
    
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

`ansible -m setup srv` - просомтр информации о хостах.   
`ansible-lint playbook.yml` - отдельная программа для проверки корректности синтаксиса `playbook`-файла.  

Если нужны переменные окружения и пайпы, то необходимо использовать модуль `shell`.  

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

</details>

#### Ссылки на полезные ресурсы <a name="links"></a>
[Ansible Documentation](https://docs.ansible.com/ansible/latest/index.html) — официальная документация по `Ansible`;  
[Galaxy](https://galaxy.ansible.com/) — готовые модули;  
[ansible.cfg](https://raw.githubusercontent.com/ansible/ansible/devel/examples/ansible.cfg) — пример конфигурации файла `ansible.cfg` от разработчиков;  


## 4. Выполнение <a name="exec"></a>  

### Описание лабораторного стенда <a name="stand"></a>  
Лабораторный стенд разворачивается из [Vagrantfile](https://github.com/che-a/OTUS_LinuxAdministrator/blob/master/tasks/09/Vagrantfile) с последующим провижинингом из сценария [provision.sh](https://github.com/che-a/OTUS_LinuxAdministrator/blob/master/tasks/09/provision.sh) и состоит из трех виртуальных машин:  
- `ansible`, подготовленный для оркестрации остальных виртуальных машин сервер `Ansible`;  
- `srv1`, виртуальная машина с ОС `CentOS 7`;  
- `srv2`, виртуальная машина с ОС `Debian 10`.  

Для `ansible` настроен `SSH`-додступ по ключам к `srv1` и `srv2`, ввод пароля не требуется, к машинам возможно обращение по имени хоста.  
Т.о. `Ansible`-сервер готов сразу после своего развертывания, в чем можно убедиться выполнив следующую команду:
```bash
cd ansible-nginx/
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

### Результаты <a name="result"></a>  
#### Файловая структура Ansible-роли
```console
ansible-nginx/
├── ansible.cfg
├── inventories
│   └── staging
│       └── hosts
├── playbooks
│   └── install_nginx.yml
└── roles
    └── nginx
        ├── defaults
        │   └── main.yml
        ├── files
        ├── handlers
        │   └── main.yml
        ├── meta
        │   └── main.yml
        ├── tasks
        │   ├── centos.yml
        │   ├── debian.yml
        │   └── main.yml
        ├── templates
        │   ├── index.html.j2
        │   └── nginx.conf.j2
        ├── tests
        │   ├── inventory
        │   └── test.yml
        └── vars
            └── main.yml
```

#### Развертывание nginx
```bash
cd ansible-nginx/
ansible-playbook playbooks/install_nginx.yml
```
```console

PLAY [Install NGINX] **********************************************************************************************************************************************************************************************

TASK [Gathering Facts] ********************************************************************************************************************************************************************************************
ok: [srv2]
ok: [srv1]

TASK [nginx : Install EPEL repository] ****************************************************************************************************************************************************************************
skipping: [srv2]
changed: [srv1]

TASK [nginx : Install NGINX package using yum] ********************************************************************************************************************************************************************
skipping: [srv2]
changed: [srv1]

TASK [nginx : Replace standard HTML file] *************************************************************************************************************************************************************************
skipping: [srv2]
changed: [srv1]

TASK [nginx : Install NGINX package using apt] ********************************************************************************************************************************************************************
skipping: [srv1]
[WARNING]: Updating cache and auto-installing missing dependency: python-apt

changed: [srv2]

TASK [nginx : Replace standard HTML file] *************************************************************************************************************************************************************************
skipping: [srv1]
changed: [srv2]

TASK [nginx : Replace standard nginx.conf file] *******************************************************************************************************************************************************************
changed: [srv2]
changed: [srv1]

RUNNING HANDLER [nginx : restart nginx] ***************************************************************************************************************************************************************************
changed: [srv2]
changed: [srv1]

PLAY RECAP ********************************************************************************************************************************************************************************************************
srv1                       : ok=6    changed=5    unreachable=0    failed=0    skipped=2    rescued=0    ignored=0   
srv2                       : ok=5    changed=4    unreachable=0    failed=0    skipped=3    rescued=0    ignored=0   

```
#### Работа nginx на нестандартном порте
```bash
ansible srv -m shell -a "ss -tnulp | grep nginx" -b
```
```console
[WARNING]: Platform linux on host srv2 is using the discovered Python interpreter at /usr/bin/python, but future installation of another Python interpreter could change this. See
https://docs.ansible.com/ansible/2.9/reference_appendices/interpreter_discovery.html for more information.

srv2 | CHANGED | rc=0 >>
tcp     LISTEN   0        128              0.0.0.0:8080          0.0.0.0:*       users:(("nginx",pid=3010,fd=6),("nginx",pid=3009,fd=6))                        

srv1 | CHANGED | rc=0 >>
tcp    LISTEN     0      128       *:8080                  *:*                   users:(("nginx",pid=5761,fd=6),("nginx",pid=5760,fd=6))
```
#### Использование языка шаблонов Jinja2
- `http://localhost:8081/`, [ссылка](http://localhost:8081/) — проверка работы `nginx` на `srv1`;  
- `http://localhost:8082/`, [ссылка](http://localhost:8082/) — проверка работы `nginx` на `srv2`; 

####  Состояние systemd

```bash
ansible srv -a "systemctl status nginx.service" 
```
```console
[WARNING]: Platform linux on host srv2 is using the discovered Python interpreter at /usr/bin/python, but future installation of another Python interpreter could change this. See
https://docs.ansible.com/ansible/2.9/reference_appendices/interpreter_discovery.html for more information.

srv2 | CHANGED | rc=0 >>
? nginx.service - A high performance web server and a reverse proxy server
   Loaded: loaded (/lib/systemd/system/nginx.service; enabled; vendor preset: enabled)
   Active: active (running) since Thu 2019-11-21 22:39:29 GMT; 13min ago
     Docs: man:nginx(8)
  Process: 328 ExecStartPre=/usr/sbin/nginx -t -q -g daemon on; master_process on; (code=exited, status=0/SUCCESS)
  Process: 332 ExecStart=/usr/sbin/nginx -g daemon on; master_process on; (code=exited, status=0/SUCCESS)
 Main PID: 333 (nginx)
    Tasks: 2 (limit: 545)
   Memory: 3.3M
   CGroup: /system.slice/nginx.service
           ??333 nginx: master process /usr/sbin/nginx -g daemon on; master_process on;
           ??334 nginx: worker process

srv1 | CHANGED | rc=0 >>
* nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; vendor preset: disabled)
   Active: active (running) since Thu 2019-11-21 22:39:29 UTC; 13min ago
  Process: 2336 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 2324 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 2319 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 2338 (nginx)
   CGroup: /system.slice/nginx.service
           |-2338 nginx: master process /usr/sbin/ngin
           `-2339 nginx: worker proces

```
