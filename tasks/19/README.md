## Занятие 19. LDAP. Централизованная авторизация и аутентификация
### Содержание
1. [Описание занятия](#description)  
2. [Домашнее задание](#homework)  
3. [Справочные сведения](#info)
4. [Выполнение](#exec)  

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

## 3. Справочные сведения <a name="info"></a>  

[FreeIPA](https://www.freeipa.org/page/Main_Page)


## 4. Выполнение <a name="exec"></a>  

Развернутый из [Vagrantfile]() командой `vagrant up` стенд состоит из следующих машин:  
- `ipa-srv.linux.otus` -- машина с установленным сервером `FreeIPA`; [веб-интерфейс](http://localhost:8080)
- `client.linux.otus` -- машина, готовая для установки на нее с помощью `Ansible` клиента `FreeIPA`.  


```bash
ipa-server-install  --hostname=ipa.linux.otus \
                    --domain=linux.otus \
                    --realm=LINUX.OTUS \
                    --ds-password=password1234 \
                    --admin-password=password1234 \
                    --mkhomedir \
                    --setup-dns \
                    --forwarder=77.88.8.8 \
                    --auto-reverse \
                    --unattended
```
```bash
ipa-server-install -a password1234 --hostname=ipa.linux.otus -r LINUX.OTUS -p password1234 -n linux.otus -U
```
