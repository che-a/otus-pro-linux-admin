#!/usr/bin/env bash

function menu {
    local ITEM_[1]="RAID 0"
    local ITEM_[2]="RAID 1"
    local ITEM_[3]="RAID 5"
    local ITEM_[4]="RAID 6"
    local ITEM_[5]="RAID 10"
    local ITEM_[0]="Выход из программы"

    clear
    for i in {0..5}; do
        echo ${ITEM_[$i]}
    done


    #echo "
    #Эта программа генерирует Vagrantfile и запускает тестовое окружение
    #с подключенным RAID выбранного типа:
#        1. RAID 0
#        2. RAID 1
#        3. RAID 5
#        4. RAID 6
#        5. RAID 10
#        0. Выход
#    "
    #read -p "Введите номер [0-5] > "

    case $REPLY in
        1)  echo "1. $ITEM_1"
            exit
            ;;
        2)  echo "2. $ITEM_2"
            exit
            ;;
        3)  echo "3. $ITEM_3"
            exit
            ;;
        4)  echo "4. $ITEM_4"
            exit
            ;;
        5)  echo "5. $ITEM_5"
            exit
            ;;
        0)  echo "0. $ITEM_0"
            exit
            ;;
        *)  echo "Неверный номер." >&2
            exit 1
            ;;
    esac
}
function prnt_info {
    echo "Usage: choose_raid.sh [-h] | [-r raid_level] [-f file ]"
    echo "  -f, --file          output file"
    echo "  -h, --help          help"
    echo "  -r, --raid          raid level"
    return
}

menu

#echo "Position parameters:"
#echo "Count parameters: $#"
#echo "\$0 = $0"
#echo "\$1 = $1"
#echo "\$2 = $2"
#echo "\$3 = $3"
#echo "\$4 = $4"
#echo "\$5 = $5"

#clear
#prnt_info
