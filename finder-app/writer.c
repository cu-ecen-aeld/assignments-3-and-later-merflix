#include <stdio.h>
#include <syslog.h>


int main(int argc, char * argv[]){
	
	// init syslog
	openlog(NULL, LOG_CONS | LOG_PID, LOG_USER);

	if(argc != 3){
		syslog(LOG_ERR, "wrong number of arguments given");
		return 1;
	}
	
	// remove old content
	remove(argv[1]);
	
	FILE * f_pointer = fopen(argv[1], "w");
	if(f_pointer == NULL){
		syslog(LOG_ERR, "cannot open / create file: %s", argv[1]);
		return 1;
	}
	fprintf(f_pointer, argv[2]);
	syslog(LOG_DEBUG, "Writing %s to %s", argv[2], argv[1]);
	fclose(f_pointer);
	closelog();
	return 0;
}
