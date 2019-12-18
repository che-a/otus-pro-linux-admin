## Занятие 19. LDAP. Централизованная авторизация и аутентификация
### Содержание
1. [Описание занятия](#description)  
2. [Домашнее задание](#homework)  
3. [Выполнение](#exec)  

## 1. Описание занятия <a name="description"></a>
### Цели
- Что такое `LDAP` и зачем он нужен.  
- Разбираем базовую настройку `LDAP` на примере.  

## 2. Домашнее задание  <a name="homework"></a>
### Постановка задачи
1) Установить `FreeIPA`.  
2) Написать `Ansible-playbook` для конфигурации клиента.  

### Дополнительное задание
3) Настроить авторизацию по `SSH`-ключам.  

В `git` - результирующий playbook.  


## 3. Выполнение <a name="exec"></a>  
#### Лабораторный стенд

Развернутый из [Vagrantfile]() стенд состоит из следующих машин:  
- `mgmt.linux.otus` — `Ansible`-сервер, `FreeIPA`-клиент;    
- `ns1.linux.otus` — сервер имен, `FreeIPA`-клиент;  
- `ipa.linux.otus` — `FreeIPA`-сервер;  
 
  
#### Порядок развертывания стенда
Развертывание стенда производится в два этапа:
1) Командой `vagrant up` создается готовый к дальнейшей `Ansible`-оркестрации стенд. Сервером `Ansible` выступает `mgmt.linux.otus`, на котором настроен беспарольный `SSH`-доступ для пользователя `vagrant` к остальным виртуальным машинам.  
Первичной настройкой каждой ВМ занимается сценарий [provision.sh](https://github.com/che-a/OTUS_LinuxAdministrator/blob/master/tasks/19/files_all_vms/opt/provision.sh), который на каждой машине запускается через `systemd`-модуль. Это необходимо для того, чтобы после перезагрузки системы продолжать настройку с нужного места, а не начинать с начала.

2) Настройка сервера и клинетов `FreeIPA` с помощью `Ansible`:
```bash
vagrant ssh mgmt
```
```bash
cd ansible && ansible-playbook playbooks/freeipa.yml
```
#### Проверка работоспособности сервера
```bash
ipactl status
```
```console
Directory Service: RUNNING
krb5kdc Service: RUNNING
kadmin Service: RUNNING
named Service: RUNNING
httpd Service: RUNNING
ipa-custodia Service: RUNNING
ntpd Service: RUNNING
pki-tomcatd Service: RUNNING
ipa-otpd Service: RUNNING
ipa-dnskeysyncd Service: RUNNING
ipa: INFO: The ipactl command was successful
```

```bash
echo '12345678' | kinit admin && klist
```
```console
Ticket cache: KEYRING:persistent:0:0
Default principal: admin@LINUX.OTUS

Valid starting       Expires              Service principal
12.12.2019 11:19:53  13.12.2019 11:19:49  krbtgt/LINUX.OTUS@LINUX.OTUS
```

```bash
ipa user-find admin
```
```console
---------------------
Найден 1 пользователь
---------------------
  Логин пользователя: admin
  Фамилия: Administrator
  Домашний каталог: /home/admin
  Оболочка входа: /bin/bash
  Principal alias: admin@LINUX.OTUS
  UID: 218200000
  ID группы: 218200000
  Учетная запись отключена: False
------------------------------
Количество вернутых значений 1
------------------------------
```
#### Веб-интерфейс


