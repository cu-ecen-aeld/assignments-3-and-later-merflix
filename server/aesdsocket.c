//--------------------------------------------------------------------------------
// aesdsocket.c                                                         26.09.2023
//
// Telnet is an old network protocol that is used to connect to remote systems over
// a TCP/IP network. It connects to servers and network equipment over port 23
//
// Usage:
//   Once the script is running, open a console and type: telnet localhost 9000
// main.cpp
// gcc -Wall -Werror tcp-ip-server.c -o server   OK
//--------------------------------------------------------------------------------
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <string.h>
#include <syslog.h>
#include <signal.h>
#include <stdbool.h>

#define DATA_FILE "/var/tmp/aesdsocketdata"

bool stop_server = false;

static void sigintHandler(int sig)
{
    write(STDERR_FILENO, "Caught SIGINT!\n", 15);
    stop_server = true;
}

void sigtermHandler(int sig)
{
    write(STDERR_FILENO, "Caught SIGTERM!\n", 16);
    stop_server = true;
}


int main()
{
    if (signal(SIGINT, sigintHandler) == SIG_ERR)
        exit(EXIT_FAILURE);

    if (signal(SIGTERM, sigtermHandler) == SIG_ERR)
        exit(EXIT_FAILURE);


    printf("Creating server socket...\n");
    int listening = socket(AF_INET, SOCK_STREAM, 0);
    if (listening == -1)
    {
        fprintf(stderr, "Can't create a socket!");
        return -1;
    }

    struct sockaddr_in hint;
    hint.sin_family = AF_INET;
    hint.sin_port = htons(9000); // socket address 
                                 // htons translates an unsigned integer into a network byte

    inet_pton(AF_INET, "0.0.0.0", &hint.sin_addr); // transforms an IP address from text form into binary form

    printf("Binding socket to sockaddr...\n");
    if (bind(listening, (struct sockaddr *)&hint, sizeof(hint)) == -1) 
    {
        fprintf(stderr, "Can't bind to IP/port");
        return -1;
    }

    printf("Mark the socket for listening...\n");
    if (listen(listening, SOMAXCONN) == -1)
    {
        fprintf(stderr, "Can't listen !");
        return -1;
    }

    struct sockaddr_in client;
    socklen_t clientSize = sizeof(client);

    printf("Accept client call...\n");
    int clientSocket = accept(listening, (struct sockaddr *)&client, &clientSize);
    
    // Logs IP address
    syslog(LOG_INFO, "Accepted connection from %s \n", inet_ntoa(client.sin_addr) );

    printf("Received call...\n");
    if (clientSocket == -1)
    {
        fprintf(stderr, "Problem with client connecting!");
        return -1;
    }

    printf("Client address: %s  and port: %d\n", inet_ntoa(client.sin_addr), client.sin_port );

    close(listening);

    FILE *fp;
    fp = fopen(DATA_FILE, "aw"); // open for writing and append 

    int total_bytesRecv = 0;
    char full_content[100*4096];
    char buf[4096];
    while (1) {

        if(stop_server == true) break;

        // clear buffer
        memset(buf, 0, 4096);

        // wait for a message
        int bytesRecv = recv(clientSocket, buf, 4096, 0);
        if (bytesRecv == -1)
        {
           fprintf(stderr, "There was a connection issue.");
        }
        if (bytesRecv == 0)
        {
            printf("The client disconnected\n");
            syslog(LOG_INFO, "Closed connection from %s \n", inet_ntoa(client.sin_addr) );
            if(stop_server == true) break;
        }
        
        // display message
       // std::cout << "Received: " << std::string(buf, 0, bytesRecv);
        printf("Received: %s", buf);
        fprintf(fp, "%s", buf); // fills up / append buf to DATA_FILE
        fflush(fp);

        // return message
        strcat(full_content, buf); // append last packet to what exist
        total_bytesRecv += (bytesRecv+1);
        //send(clientSocket, buf, bytesRecv+1, 0);
        send(clientSocket, full_content, total_bytesRecv, 0);
    }
    
    // close socket
    close(clientSocket);
    fclose(fp);

    if(stop_server) {
        if( remove(DATA_FILE) == 0) printf("File %s removed, server stopped\n", DATA_FILE);
    }
    
    return 0;

}

