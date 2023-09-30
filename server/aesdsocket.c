  #include <sys/types.h>
  #include <sys/socket.h>
  #include <netinet/in.h>
  #include <arpa/inet.h>
  #include <stdio.h>
  #include <stdlib.h>
  #include <string.h>
  #include <unistd.h>
  #include <syslog.h>
  #include <stdbool.h>
  #include <netdb.h>
  #include<signal.h>
  #include <fcntl.h>

  #define BUF_SIZE 200000
  
  //***********
  //Signal part
  //*********** 
  bool sig_success =false;
  static void signal_handler (int signal_number )
  {
  if ((signal_number==SIGINT) || (signal_number == SIGTERM) ){
    sig_success = true;
  }
  }
  

  int main(void)
  {

  char *filename = "/var/tmp/aesdsocketdata";
  printf("fichier detruit\n");
  remove(filename);
  FILE *fd2 = fopen (filename, "w");
  fclose(fd2);
  //*****************
  //make it Demon !!
  //****************
  
   pid_t pid;
   /* Fork off the parent process */
    pid = fork();
    
    /* An error occurred */
    if (pid < 0)
        exit(EXIT_FAILURE);
    
     /* Success: Let the parent terminate */
    if (pid > 0)
        exit(EXIT_SUCCESS);
    
    /* On success: The child process becomes session leader */
    if (setsid() < 0)
        exit(EXIT_FAILURE);
  
    
    struct addrinfo hints,*result;
    struct addrinfo *servinfo;
    struct addrinfo  *rp;
    char buf[BUF_SIZE];
 
    const char port[4] = "9000";
    int status;
    
    struct sockaddr_in *addr4;
    struct sockaddr *addr;
    struct sigaction new_action;
    bool sig_success =false;
    printf("start :\n");
    //static char ipaddr[INET_ADDRSTRLEN];
    memset(&new_action,0,sizeof(struct sigaction));
      
    //*******************
    // signal handler
    //*******************
    new_action.sa_handler=signal_handler;
    
    if (sigaction(SIGTERM,&new_action,NULL) !=0){
    
    syslog(LOG_ERR, "Error registring SIGTERM");}
    
     if (sigaction(SIGINT,&new_action,NULL) !=0){
    
    syslog(LOG_ERR, "Error registring SIGINT");}
    
    
    openlog("aesdsocket", LOG_PID|LOG_CONS, LOG_USER);
    
     //*************************
     // Configuring local address  
     //****************************
    memset(&hints, 0, sizeof (hints));
  
    printf("start getaddr stuff :\n");

    hints.ai_family = AF_INET;    /* Allow IPv4 or IPv6 */
    hints.ai_socktype = SOCK_STREAM; /* Datagram socket */
    hints.ai_flags = AI_PASSIVE;    /* For wildcard IP address */

    if (status = getaddrinfo(0,port,&hints,&servinfo) != 0){
    syslog(LOG_ERR, "getaddrinfo error: %s\n",gai_strerror(status));
    printf("something wrong %d:\n",status);
    exit(EXIT_FAILURE);
    }
    
    //***************
    //Socket openning
    //***************
    
    int SocketFD = socket(servinfo->ai_family,servinfo->ai_socktype,servinfo->ai_protocol);
    if (SocketFD == -1) {
      perror("cannot create socket");
      syslog(LOG_ERR, "cannot open socket");
      exit(EXIT_FAILURE);
    }
   printf("before while :\n"); 
   
   
   //********************
   //    socket reuse 
   //*******************
    int reutiliser = 1;
    if (setsockopt(SocketFD, SOL_SOCKET, SO_REUSEADDR, &reutiliser, sizeof(reutiliser)) == -1) {
        syslog(LOG_ERR, "cannot reuse socket");
        close(SocketFD);
        exit(EXIT_FAILURE);
    }
   
   //***************
   //bind
   //***************
   printf("about to bind :\n");
    if (bind(SocketFD,servinfo->ai_addr, servinfo->ai_addrlen) == -1) {
      perror("bind failed");
      close(SocketFD);
      freeaddrinfo(servinfo);
      exit(EXIT_FAILURE);
    } 
   
  int ConnectFD = 0; 
  while (1){
    FILE *fp  = fopen (filename, "a");
    if (sig_success) {
      syslog(LOG_ERR, "Caught signal, exiting");
      printf("Caught signal, exiting");
      close(SocketFD);
      close(ConnectFD);
      freeaddrinfo(servinfo);
      exit(EXIT_SUCCESS);
      }
    
  printf("about to listen :\n");
    if (listen(SocketFD, 10) == -1) {
      perror("listen failed");
      close(SocketFD);
      freeaddrinfo(servinfo);
      exit(EXIT_FAILURE);
    }
    //***************
    //listen
    //***************
      struct sockaddr_storage client_address;
      socklen_t client_len = sizeof(client_address);
      
      socklen_t clientaddr_size = sizeof(struct sockaddr);
      ConnectFD = accept(SocketFD, (struct sockaddr*) &client_address, &client_len);

  printf("voici connectfd : %d\n",ConnectFD);
  

      if (ConnectFD == -1) {
        printf("accept failed");
        close(ConnectFD);
        close(SocketFD);
        
        freeaddrinfo(servinfo);
        exit(EXIT_FAILURE);
        
      }
      
      //***************
      //getname
      //***************
      char clientip[100] ;
      printf("trying to got pair name \n");
      int res = getnameinfo((struct sockaddr*) &client_address,client_len, clientip, sizeof(clientip),0,0,NI_NUMERICHOST);
      printf("got pair name \n");

	
	  printf("got pair address \n");
      printf ("%s\n",clientip);
      
      syslog(LOG_INFO,"Accepted connection from%s\n", clientip);
    
      //***************
      //receive data
      //***************  
    
      printf("voici connectfd : %d\n",ConnectFD);
  ssize_t r = recv( ConnectFD , buf , BUF_SIZE,0);
  printf("voici la donnee recu : %s\n",buf);
      /* perform read write operations ... 
      read(ConnectFD, buff, size)
      */
      printf("declaring log \n");
      
      
      printf("data logged:\n");
      

      int output = fprintf (fp, "%s\n", buf); 
      fclose(fp);
      printf ("longueur de la ligne :%ld",strlen(buf));	
      // traitement recv
      printf("data written in file:\n");	
      char *line=NULL;
      ssize_t nread = 0;
      size_t lent = 0;

  
      FILE *filename1 = fopen (filename, "r");
      
                         if (filename1 == NULL) {
                        printf("Error opening data file\n");
                        exit(-1);}
        
        printf("ready to read from file:\n");
        
        
        
        while (( nread = getline(&line, &lent, filename1)) > 0){
       
        printf("we are here\n");
        printf("%s\n",line);
        //line[strcspn(line, "\n")] = 0;
        printf ("longueur de la ligne :%ld",strlen(line));
        if (strlen(line) !=1) {send (ConnectFD,line,nread,0);};
        };
        
      if (shutdown(ConnectFD, SHUT_RDWR) == -1) {
        perror("shutdown failed");
        close(ConnectFD);
        freeaddrinfo(servinfo);
        exit(EXIT_FAILURE);
      }
      close(ConnectFD);
      //close(SocketFD);
    }

    close(SocketFD);
    freeaddrinfo(servinfo);
    closelog();
    return EXIT_SUCCESS; 
}

