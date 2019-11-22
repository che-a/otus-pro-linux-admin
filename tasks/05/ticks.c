#include <stdio.h> 
#include <string.h> 
#include <stdlib.h> 
#include <unistd.h> 
#include <time.h> 
#include <sys/times.h> 

main () 
{ 
    clock_t ct0, ct1; 
    struct tms tms0, tms1; 
    int i; 

    if ((ct0 = times (&tms0)) == -1) 
        perror ("times"); 

    printf ("_SC_CLK_TCK = %ld\n", sysconf (_SC_CLK_TCK)); 

    for (i = 0; i < 10000000; i++) 
        ; 

    if ((ct1 = times (&tms1)) == -1) 
        perror ("times"); 

    printf ("ct0 = %ld, times: %ld %ld %ld %ld\n", ct0, tms0.tms_utime,
        tms0.tms_cutime, tms0.tms_stime, tms0.tms_cstime); 
    printf ("ct1 = %ld, times: %ld %ld %ld %ld\n", ct1, tms1.tms_utime,
        tms1.tms_cutime, tms1.tms_stime, tms1.tms_cstime); 
    printf ("ct1 - ct0 = %ld\n", ct1 - ct0); 
}
