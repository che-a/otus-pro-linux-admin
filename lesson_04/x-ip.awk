#!/bin/gawk -f

BEGIN   {
        yearsum = 0 ; costsum = 0
        newcostsum = 0 ; newcount = 0
        }
        {
        yearsum += $3
        costsum += $5
        }
$3 > 2000 {newcostsum += $5 ; newcount ++}
END     {
        printf "Средний возраст машин (в годах) %4.1f \n", \
                2010 - (yearsum/NR)
        printf "Средняя цена машин $%7.2f\n", \
                costsum/NR
        printf "Средняя цена самых новых машин $%7.2f\n", \
                newcostsum/newcount
        }
