#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <errno.h>
#include <syslog.h>
#include <signal.h>
#include <unistd.h>
#include <netdb.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#define PORT 9000
#define FILE_PATH "/var/tmp/aesdsocketdata"

#define BUFFER_SIZE 1024
#define PACKET_SIZE 20 * 1024

bool accept_conn_loop = true;

int accept_conn(int sockfd, struct sockaddr *addr_cli) {
    int addrlen = sizeof(*addr_cli);
    return accept(sockfd, addr_cli, (socklen_t *)(&addrlen));
}

static void signal_handler(int sig_no) {
    if ((sig_no == SIGINT) || (sig_no == SIGTERM)) {
        syslog(LOG_INFO, "Caught signal, exiting");
        accept_conn_loop = false;
    }
}

void get_ipcli(const struct sockaddr *addr_cli, char *s_ipcli) {
    struct sockaddr_in *pV4Addr = (struct sockaddr_in *)addr_cli;
    struct in_addr ipcli = pV4Addr->sin_addr;
    char str_ipcli[INET_ADDRSTRLEN];
    inet_ntop(AF_INET, &ipcli, str_ipcli, INET_ADDRSTRLEN);
    strcpy(s_ipcli, str_ipcli);
}

void socket_daemon() {
    // PID: Process ID
    // SID: Session ID
    pid_t pid, sid;
    pid = fork();
    if (pid < 0) {
        exit(EXIT_FAILURE);
    }
    if (pid > 0) {
        exit(EXIT_SUCCESS);
    }
    
    sid = setsid();
    if (sid < 0) {
        exit(EXIT_FAILURE);
    }
    if ((chdir("/")) < 0) {
        exit(EXIT_FAILURE);
    }

    close(STDIN_FILENO);
    close(STDOUT_FILENO);
    close(STDERR_FILENO);
}

int main(int argc, char **argv)
{
    char port[5];
    memset(port, 0, sizeof port);
    sprintf(port, "%d", PORT);

    struct addrinfo* addr_info = NULL;
    struct addrinfo hints;
    memset(&hints, 0, sizeof hints);
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_flags = AI_PASSIVE;

    int sockfd = socket(AF_INET, SOCK_STREAM, 0);
    if(sockfd==-1)
        exit(-1);

    int rc_bind = getaddrinfo(NULL, port, &hints, &addr_info); 
    if(rc_bind == 0)
        rc_bind = bind(sockfd, addr_info->ai_addr, sizeof(struct addrinfo));

    if(rc_bind==-1)
        exit(-1);

    openlog("syslog_socket_assignment", LOG_PID, LOG_USER);

    struct sigaction new_action;
    memset((void *)&new_action, 0, sizeof(struct sigaction));
    new_action.sa_handler = signal_handler;
    if ((sigaction(SIGTERM, &new_action, NULL) != 0) || (sigaction(SIGINT, &new_action, NULL) != 0)) {
        return 0;
    }

    if (argc == 2 && strcmp(argv[1], "-d") == 0) {
        socket_daemon();
    }

    int rc_listen = listen(sockfd, 50);
    if(rc_listen==-1)
        exit(-1);

    int data_fd = open(FILE_PATH, O_RDWR | O_CREAT | O_TRUNC, S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH);
    if(data_fd==-1)
        exit(-1);

    while (accept_conn_loop) {
        struct sockaddr addr_cli;
        int connfd = accept_conn(sockfd, &addr_cli);
        if (connfd == -1) {
            shutdown(sockfd, SHUT_RDWR);
            continue;
        }

        char str_ipcli[BUFFER_SIZE];
        get_ipcli(&addr_cli, str_ipcli);
        syslog(LOG_INFO, "Accepted connection from %s", str_ipcli);

        while (true) {
            /// receive data - write to file
            char recv_buff[BUFFER_SIZE + 1];
            memset((void *)recv_buff, 0, BUFFER_SIZE + 1);
            int rc_recvdata = recv(connfd, recv_buff, BUFFER_SIZE, 0);
            if(rc_recvdata==-1)
                exit(-1);
            int rc_writefile = write(data_fd, (const void *)recv_buff, rc_recvdata);
            if(rc_writefile==-1)
                exit(-1);

            char *pch = strstr(recv_buff, "\n");
            if (pch != NULL)
                break;
        }

        int data_size = lseek(data_fd, 0L, SEEK_CUR);
        char send_buff[BUFFER_SIZE];
        lseek(data_fd, 0L, SEEK_SET);
        do {
            int rc_readfile = read(data_fd, send_buff, BUFFER_SIZE);
            if(rc_readfile==-1)
                exit(-1);
            int rc_senddata = send(connfd, send_buff, rc_readfile, 0);
            if(rc_senddata==-1)
                exit(-1);
            data_size -= rc_readfile;
            memset(send_buff, 0, BUFFER_SIZE);
        } while (data_size > 0);

        syslog(LOG_INFO, "Closed connection from %s", str_ipcli);
    }

    /// shutdown
    close(data_fd);
    closelog();
    remove(FILE_PATH);

    return 0;
}
  
