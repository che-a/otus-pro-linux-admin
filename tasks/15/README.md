## Занятие 15. Docker
### Содержание
1. [Описание занятия](#description)  
2. [Домашнее задание](#homework)  
3. [Справочная информация](#info)  
4. [Выполнение](#exec)  

## 1. Описание занятия <a name="description"></a>
### Цели
- разбираем как писать `Dockerfile`,  
- создаем `docker-compose`,  
- запускаем `docker swarm`.  

## 2. Домашнее задание  <a name="homework"></a>
### Постановка задачи
- Создайте свой кастомный образ `nginx` на базе `alpine`.  
- После запуска `nginx` должен отдавать кастомную страницу (достаточно изменить дефолтную страницу nginx).  
- Определите разницу между контейнером и образом. Вывод опишите в домашнем задании.  
- Ответьте на вопрос: можно ли в контейнере собрать ядро?  
- Собранный образ необходимо запушить в docker hub и дать ссылку на ваш репозиторий.  
### Дополнительно
- Создайте кастомные образы nginx и php, объедините их в docker-compose.  
- После запуска `nginx` должен показывать php info.  
- Все собранные образы должны быть в docker hub.  

## 3. Справочная информация <a name="info"></a>  

<details>
   <summary></summary>
   
[www.docker.com](https://www.docker.com/)  
[Введение в Docker](https://docs.docker.com/get-started/)  
[Документация](https://docs.docker.com/engine/docker-overview/)  
[Dockerfile reference](https://docs.docker.com/engine/reference/builder/)

`Контейнер` - это не что иное, как работающий процесс, к которому применены некоторые дополнительные функции инкапсуляции, чтобы сохранить его изолированным от хоста и других контейнеров. Одним из наиболее важных аспектов изоляции контейнера является то, что каждый контейнер взаимодействует со своей собственной частной файловой системой; эта файловая система предоставлена образом Docker.  
`Образ` включает в себя все необходимое для запуска приложения - код или двоичный файл, среды выполнения, зависимости и любые другие требуемые объекты файловой системы.

`docker images` -- список всех установленных образов  
`docker pull image` - скачать образ image  
`docker ps`  
`docker ps -a` - список контейнеров    
`docker run -d -p port:port container_name` — запуск контейнера;  
`docker stop container_name`  
`docker logs container_name` - вывод логов контейнеров  
`docker inspect container_name` - информация по запущенному контейнеру  
`docker build -t dockerhub_login/reponame:ver`  
`docker push/pull`  
`docker exec -it container_name bash` 

`Docker-файл` — инструкции для `Docker` по настройке и запуску приложений. В `Docker-файле` находится описание базового образа, на котором построен контейнер. Одни из самых популярных образов — Python, Ubuntu и Alpine.
С помощью дополнительных слоёв в Docker-файле можно добавить необходимое ПО. Например, можно указать, что Dockerу нужно добавить библиотеки NumPy, Pandas и Scikit-learn.

Несколько Docker-инструкций

`FROM` — задаёт родительский (главный) образ;  
`LABEL` — добавляет метаданные для образа. Хорошее место для размещения информации об авторе;  
`ENV` — создаёт переменную окружения;
`RUN` — запускает команды, создаёт слой образа. Используется для установки пакетов и библиотек внутри контейнера;  
`COPY`  — копирует файлы и директории в контейнер;  
`ADD`  — делает всё то же, что и инструкция COPY. Но ещё может распаковывать локальные .tar файлы;  
`CMD` — указывает команду и аргументы для выполнения внутри контейнера. Параметры могут быть переопределены. Использоваться может только одна инструкция CMD;  
`WORKDIR` — устанавливает рабочую директорию для инструкции CMD и ENTRYPOINT;  
`ARG` — определяет переменную для передачи Docker’у во время сборки;  
`ENTRYPOINT` — предоставляет команды и аргументы для выполняющегося контейнера. Суть его несколько отличается от CMD;  
`EXPOSE` — открывает порт;  
`VOLUME` — создаёт точку подключения директории для добавления и хранения постоянных данных.  


</details>

## 4. Выполнение <a name="exec"></a>  
### Создание образа <a name="create"></a>  
#### Создание образа  
- регистрация аккаунта на `Docker Hub`;  
- авторизация  
```bash
docker login --username 19111942
```
- создание образа  
```bash
docker build -t 19111942/otus-linuxadmin-les15:latest -f nginx/Dockerfile .
docker build -t 19111942/otus-linuxadmin-les15-php7:latest -f nginx-php5/Dockerfile .
```
- отправка образа на репозиторий в `Docker Hub`
```bash
docker push 19111942/otus-linuxadmin-les15:latest
docker push 19111942/otus-linuxadmin-les15-php7:latest
```
#### Использование образа  
- загрузка образа из репозитория с целью его дальнейшего запуска:
```bash
docker pull 19111942/otus-linuxadmin-les15:latest
docker pull 19111942/otus-linuxadmin-les15-php7:latest
```
- проверка списка установленных в системе образов
```bash
docker images
```
```console
REPOSITORY                       TAG                 IMAGE ID            CREATED             SIZE
19111942/otus-linuxadmin-les15   latest              42098ae0f0c3        10 minutes ago      7MB
alpine                           latest              965ea09ff2eb        5 weeks ago         5.55MB
```
- запуск контейнера из образа
```bash
docker run --name otus-linuxadmin-les15 -d -p 80:80 19111942/otus-linuxadmin-les15:latest
docker run --name otus-linuxadmin-les15-php7 -d -p 80:8080 19111942/otus-linuxadmin-les15-php5:latest
```
- останов контейнера
```bash
docker stop otus-linuxadmin-les15
docker stop otus-linuxadmin-les15-php7
```
