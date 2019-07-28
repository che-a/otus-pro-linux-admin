#!/usr/bin/env bash

# Формирование скрипта для компиляции нового ядра,
# который необходимо запустить вручную после развертывания
# тестового окружения
OUTFILE=kernel_compile.sh
(
cat <<- '_EOF_'
    #!/usr/bin/env bash

    KERN="linux-4.19.61"
    # KERN="linux-5.2.4"

    # Подготовка исходных кодов для компиляции
    cd /usr/src/kernels
    wget https://cdn.kernel.org/pub/linux/kernel/v4.x/$KERN.tar.xz
    tar -xvf $KERN.tar.xz -C .
    rm ./$KERN.tar.xz

    # Использования файла конфигурации ядра текущей версии
    cd ./$KERN
    cp /boot/config-`uname -r` .config

    make oldconfig
    # make
    # make modules_install
    # make install
_EOF_
) > $OUTFILE
chmod +x $OUTFILE


# Обновление системы
yum update -y

# Установка дополнительных программ
yum install -y mc nano wget
# Установка необходимых для компиляции нового ядра пакетов
# yum install -y ncurses-devel openssl-devel bc install libelf-dev libelf-devel
# yum groupinstall -y "Development Tools"

shutdown -r now
