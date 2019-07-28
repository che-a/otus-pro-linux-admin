
## Занятие 1. С чего начинается Linux ##

#### Цели занятия
- объяснить как работает ядро,
- обновить ядро.

#### Краткое содержание:
- версии Linux;
- ядро Linux;
- функции, виды и версии ядер;
- многозадачность;
- syscalls;
- обновление ядра;
- ручная сборка ядра.

## Домашнее задание: *делаем собственную сборку ядра*.
- Взять любую версию ядра с kernel.org
- Подложить файл конфигурации ядра
- Собрать ядро (попутно доставляя необходимые пакеты)
- Прислать результирующий файл конфигурации
- Прислать списк доустановленных пакетов, взять его можно из /var/log/yum.log
- Устанавливать будем на следующем занятии =)

#### Критерии оценки:
- Ядро собрано
- Прислан результирующий файл конфигурации
- Прислан список доустановленных пакетов


## Выполнение задания
#### Файлы для преподавателя  
Результирующий файл конфигурации — [config-4.19.61](https://github.com/che-a/OTUS_LinuxAdministrator/blob/master/lesson_01/config-4.19.61)  
Список доустановленных пакетов — [yum.log](https://github.com/che-a/OTUS_LinuxAdministrator/blob/master/lesson_01/yum.log)

#### Ход выполнения
Развертывание тестового окружения происходит из [Vagrantfile](https://github.com/che-a/OTUS_LinuxAdministrator/blob/master/lesson_01/Vagrantfile) с последующим провижинингом из сценария [script.sh](https://github.com/che-a/OTUS_LinuxAdministrator/blob/master/lesson_01/script.sh), который подготавливает систему (инициирует обновление и установку необходимых пакетов), а также генерирует внутри виртуальной машины bash-скрипт, который собирает и устанавливает новое ядро.
```console
# Обновление системы и установка утилит
yum update -y
yum install -y mc nano wget

# Установка необходимых пакетов для сборки нового ядра
yum install -y bc elfutils-libelf-devel openssl-devel
yum groupinstall -y "Development Tools"
```
Текущая версия ядра:
```console
uname -r
3.10.0-957.12.2.el7.x86_64
```
Далее на официальном сайте [kernel.org](https://www.kernel.org/) берётся любая версия нового ядра, в данном случае -- это ядро версии [4.19.61](https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.19.61.tar.xz).
```bash
KERN="linux-4.19.61"
# KERN="linux-5.2.4"

# Подготовка исходных кодов для сборки ядра
cd /usr/src/kernels
wget https://cdn.kernel.org/pub/linux/kernel/v4.x/$KERN.tar.xz
tar -xvf $KERN.tar.xz -C .
rm ./$KERN.tar.xz
```
Собственно, сборка нового ядра:
```bash
# Переносим конфигурацию старого ядра для сборки нового
cd ./$KERN
cp /boot/config-`uname -r` .config

# Сборка нового ядра
make oldconfig &&
make &&
make modules_install &&
make install
```
Конфигурирование загрузчика GRUB для возможности загрузки системы с новым ядром:
```bash
sed -i 's/GRUB_DEFAULT=.*/GRUB_DEFAULT=0/' /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg
```
В итоге новое ядро собрано и установлено:
```console
uname -r
4.19.61
```
Выполнение сборки нового ядра представляет из себя достаточно длительный процесс. При выполнении этого домашнего задания на сборку нового ядра потребовалось 3 часа 3 минуты.
