#!/usr/bin/env bash

# Обновление системы и установка необходимых для компиляции ядра пакетов
yum update -y
yum install -y mc nano wget ncurses-devel openssl-devel bc install libelf-dev, libelf-devel
yum groupinstall -y "Development Tools"

# Формирование скрипта для компиляции нового ядра,
# который необходимо запустить вручную после развертывания
# тестового окружения
OUTFILE=kernel_compile.sh
(
cat <<- '_EOF_'
        #!/usr/bin/env bash

        cd /usr/src/kernels
        wget https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.19.61.tar.xz
        tar -xvf linux-4.19.61.tar.xz -C .
_EOF_
) > $OUTFILE
chmod +x $OUTFILE

shutdown -r now

# cp /boot/config* .config
# make oldconfig
# make
# make modules_install
# make install
