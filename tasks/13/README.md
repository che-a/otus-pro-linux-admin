## Занятие 13. Мониторинг и алертинг
### Содержание
1. [Описание занятия](#description)  
2. [Домашнее задание](#homework)  
3. [Справочная информация](#info)  
4. [Выполнение](#exec)  
    - [Результаты](#result)   

## 1. Описание занятия <a name="description"></a>
### Цели
- Изучаем `Zabbix`.
- Знакомимся с `Prometheus`.  

## 2. Домашнее задание  <a name="homework"></a>
### Постановка задачи
Настроить дашборд с 4-мя графиками:  
- память,  
- процессор,  
- диск,  
- сеть.

Настроить на одной из систем:  
- `Zabbix` (использовать screen (комплексный экран)),  
- `Prometheus` - `Grafana`.  
В качестве результата прислать скриншот экрана - дашборд должен содержать в названии имя приславшего.  

### Дополнительно
Использовать системы, примеры которых не рассматривались на занятии, список возможных систем был приведен в презентации.  

### Критерии оценки  
5 - основное задание,  
6 - дополнительное задание.  

## 3. Справочная информация <a name="info"></a>  

<details>
    <summary></summary>



</details>

### Ссылки
[Cacti](https://www.cacti.net/) —  
[Grafana](https://grafana.com/) —  
[Icinga](https://icinga.com/products/user-experience/) —  
[Prometheus](https://prometheus.io/) —  
[Zabbix](https://www.zabbix.com/ru/) —  

## 4. Выполнение <a name="exec"></a>  
Лабораторный стенд разворачивается из [Vagrantfile](https://github.com/che-a/OTUS_LinuxAdministrator/blob/master/tasks/10/Vagrantfile) с автоматическим провижинингом из сценария [script.sh](https://github.com/che-a/OTUS_LinuxAdministrator/blob/master/tasks/10/script.sh), запускаемого с параметром `--provision`.


[http://localhost:8080/](http://localhost:8080/) — Веб-интерфейс Zabbix
[http://localhost:8082/](http://localhost:8082/) — Веб-сервер

### Результаты <a name="result"></a>  
#### Zabbix
