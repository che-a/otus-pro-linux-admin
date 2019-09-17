#!/usr/bin/env bash

# Файлы сценария, который имитирует работу веб-сервера в части формирования
# лог-файла access.log
SRV="fake_web"
MAIN_DIR="/opt/"
SRV_DIR=$MAIN_DIR$SRV"/"
SRV_NAME=$SRV".sh"
SRV_NAME_FULL=$SRV_DIR$SRV_NAME
UNIT_NAME=$SRV".service"
UNIT_NAME_FULL="/etc/systemd/system/"$UNIT_NAME

# Исходный и конечный лог-файлы. Исходный файл служит источником строк для
# формирования конечного лог-файла имитатором веб-сервера
SOURCE_LOG_NAME="access.log"
SOURCE_LOG_NAME_FULL=$SRV_DIR$SOURCE_LOG_NAME
LOG_NAME=$SRV".log"
LOG_NAME_FULL=$SRV_DIR$LOG_NAME

# Сценарий, который анализирует лог-файл веб-сервера и
# отправляет статистику на почту
SCRIPT="stat_to_mail"
SCRIPT_DIR=$MAIN_DIR$SCRIPT"/"
SCRIPT_NAME=$SCRIPT".sh"
SCRIPT_NAME_FULL=$SCRIPT_DIR$SCRIPT_NAME

# По условию задания в проекте необходимо использовать утилиту find. В данном
# задании find ищет файл EXPORT_FILE, содержащий в себе несколько переменных,
# значения которых передаются сценарию по сбору статистики лог-файла
TMP_DIR="/tmp/"
EXPORT_FILE="export.txt"
EXPORT_DIR=$TMP_DIR$SCRIPT"/"
EXPORT_FILE_FULL=$EXPORT_DIR$EXPORT_FILE

# Файл, в который будет записываться номер последней прочитанной строки
# лог-файла имитатора веб-сервера
STR_NUM_FILE="num_str.txt"
STR_NUM_FILE_FULL=$SCRIPT_DIR$STR_NUM_FILE


# Первичная подготовка системы
function prepare_system {
    mkdir -p ~root/.ssh
    cp ~vagrant/.ssh/auth* ~root/.ssh

    mkdir -p {$SRV_DIR,$SCRIPT_DIR}
    cp /vagrant/access*.log $SRV_DIR
    cp /vagrant/script.sh $SCRIPT_NAME_FULL
    ln -sf $SCRIPT_NAME_FULL $SCRIPT_DIR$SCRIPT
    echo "1" > $STR_NUM_FILE_FULL
    chown -R vagrant: {$SRV_DIR,$SCRIPT_DIR}

    ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
    yum install -y mailx nano tree tmux

    # Переменные и их значения, передеваемые через файл
    mkdir -p $EXPORT_DIR && chown -R vagrant: $EXPORT_DIR
    (
        echo 'SCRIPT_DIR='$SCRIPT_DIR
        echo 'LOG_NAME_FULL='$LOG_NAME_FULL
        echo 'STR_NUM_FILE_FULL'=$STR_NUM_FILE_FULL
    ) > $EXPORT_FILE_FULL
}

# Создание сценария, имитирующего при своем запуске веб-сервер
function create_fake_srv_script {
(
cat <<- '_EOF_'
#!/usr/bin/env bash

function read_file {
    local Z=

    while read LINE; do
        #Z=`LC_TIME=en_US date "+%d/%b/%Y:%T %z"`
        Z=`date "+%d/%b/%Y:%T %z"`
        echo $LINE | sed "s#../.../....:..:..:.. .[0-9][0-9][0-9][0-9]#$Z#" >> OutputLog
        sleep `shuf -i 1-10 -n 1`
        #sleep 0.1
    done < SourceLog
}

while [ true ]; do
    read_file
done

_EOF_
) > $SRV_NAME_FULL

    sed -i "s#OutputLog#$LOG_NAME_FULL#" $SRV_NAME_FULL
    sed -i "s#SourceLog#$SOURCE_LOG_NAME_FULL#" $SRV_NAME_FULL

    chown -R vagrant: $SRV_NAME_FULL
    chmod +x $SRV_NAME_FULL
}

# Автозагрузка имитатора веб-сервера
function create_systemd_unit {

    touch $UNIT_NAME_FULL
    chmod 664 $UNIT_NAME_FULL

cat > $UNIT_NAME_FULL <<'_EOF_'
[Unit]
Description=Fake Web Server
After=network.target

[Service]
Type=simple
ExecStart=
Restart=always
User=vagrant

[Install]
WantedBy=multi-user.target
_EOF_

    sed -i "s#ExecStart=#ExecStart=$SRV_NAME_FULL#" $UNIT_NAME_FULL

    systemctl enable $UNIT_NAME
    systemctl start $UNIT_NAME
}

# Настройка cron
function cron_tuning {

su vagrant <<'_EOF_'
# Запуск сценария каждую минуту -- удобно для отладки и демонстрации
crontab -l | { cat; echo "*/1 * * * * /opt/stat_to_mail/stat_to_mail"; } | crontab -
# Запуск сценария каждый час, согласно условия задания, а здесь:
#   в каждую 10-ую минуту каждого часа
# crontab -l | { cat; echo "10 * * * * /opt/stat_to_mail/stat_to_mail"; } | crontab -
_EOF_

}


prepare_system
create_fake_srv_script
create_systemd_unit
cron_tuning
