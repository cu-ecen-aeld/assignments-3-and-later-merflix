#include <stdio.h>
#include<syslog.h>
#include <string.h>

int main(int argc, char *argv[]) {
openlog("writer", LOG_PID|LOG_CONS, LOG_USER);

FILE *fp;
int output;
char mystring[100];


if (argc != 3) { 

syslog(LOG_ERR, "number of arguments shall be 2");
return 1 ;
}

sprintf(mystring,"%s%s%s%s\n","Writing ",argv[2]," to ",argv[1]);
printf (mystring);

syslog(LOG_DEBUG, "%s",mystring);




fp  = fopen (argv[1], "w");

if (fp==NULL)
{
    syslog(LOG_ERR, "cannot write to file");
    return 1 ;
}
output = fprintf (fp, "%s\n", argv[2]);
if (output==NULL)
{
    syslog(LOG_ERR, "cannot write to file");
    return 1 ;
}
fclose (fp);
closelog();
}

