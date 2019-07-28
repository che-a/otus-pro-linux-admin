#!/usr/bin/env bash

# Формирование скрипта для сборки нового ядра, который необходимо
# запустить вручную после развертывания тестового окружения
OUTFILE=new_kern_compile.sh
(
cat <<- '_EOF_'
    #!/usr/bin/env bash

    KERN="linux-4.19.61"
    # KERN="linux-5.2.4"
    LOG_FILE="new_kern_compile.log"
    echo "Исходное ядро:     "`uname -r` > $LOG_FILE

    # Подготовка исходных кодов для сборки ядра
    cd /usr/src/kernels
    wget https://cdn.kernel.org/pub/linux/kernel/v4.x/$KERN.tar.xz
    tar -xvf $KERN.tar.xz -C .
    rm ./$KERN.tar.xz

    # Переносим конфигурацию старого ядра для сборки нового
    cd ./$KERN
    cp /boot/config-`uname -r` .config

    # Сборка нового ядра
    echo "Начало сборки    : "`date +"%x %R %Z"` >> $LOG_FILE
    make oldconfig &&
    make &&
    make modules_install &&
    make install
    echo "Завершение сборки: "`date +"%x %R %Z"` >> $LOG_FILE

    # Правим загрузчик GRUB
    sed -i 's/GRUB_DEFAULT=.*/GRUB_DEFAULT=0/' /etc/default/grub
    grub2-mkconfig -o /boot/grub2/grub.cfg

    shutdown -r now
_EOF_
) > $OUTFILE
chmod +x $OUTFILE


# Обновление системы и установка утилит
yum update -y
yum install -y mc nano wget

# Установка необходимых пакетов для сборки нового ядра
yum install -y bc elfutils-libelf-devel openssl-devel
yum groupinstall -y "Development Tools"

shutdown -r now
