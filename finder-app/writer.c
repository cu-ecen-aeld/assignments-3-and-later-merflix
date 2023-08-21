// writer.c         21.08.2023
#include <syslog.h>
#include <stdio.h>
int main(int argc, char* argv[]) {
    openlog("Logs", LOG_PID, LOG_USER);

    if(argc != 3) { 
        //printf("Not enough arguments!\n");
        syslog(LOG_ERR, "Not enough arguments!\n");
        return 1;
    }

    char* fname= argv[1];
    char* msg= argv[2];
    FILE *pf = fopen(fname, "w");

    if(pf == NULL){
        //printf("The file %s could not be created!\n", fname);
        syslog(LOG_ERR, "The file %s could not be created!\n", fname);
        return 1;
    }
    fprintf(pf, "%s\n", msg);
    fclose(pf);

    closelog();
    return 0;
}

