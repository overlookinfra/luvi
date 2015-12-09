#if !defined(_MSC_VER)
#define WITH_DAEMONIZE

#include <stdio.h>
#include <fcntl.h>
#include <string.h>
#include <unistd.h>
#include <sys/file.h>
#include <stdlib.h>
#include <sys/types.h>
#include <signal.h>
#include <time.h>
#include <errno.h>

static void daemonize(const char* pid_file,
               const char* log_file,
               char*const* cmd)
{
    int pid_fd, log_fd, null_fd, i;
    long max_fd;
    ssize_t buff_len;
    pid_t child_pid, my_pid;
    char buff[1024];
    time_t tod_time;
    struct tm tod_tm;
    FILE* logf;

    log_fd = open(log_file, O_WRONLY|O_APPEND|O_CREAT, 0777);
    if ( log_fd < 0 ) {
        fprintf(stderr, "open(%s): %s\n", log_file, strerror(errno));
        exit(1);
    }
    logf = fdopen(logf, "w");

    null_fd = open("/dev/null", O_RDONLY, 0777);
    if ( null_fd < 0 ) {
        fprintf(stderr, "open(/dev/null): %s\n", strerror(errno));
        exit(1);
    }

    pid_fd = open(pid_file, O_RDWR|O_CREAT, 0644);
    if ( pid_fd < 0 ) {
        fprintf(stderr, "open(%s): %s\n", pid_file, strerror(errno));
        exit(1);
    }
    
    if ( flock(pid_fd, LOCK_EX) < 0 ) {
        fprintf(stderr, "flock(%s): %s\n", pid_file, strerror(errno));
        exit(1);
    }

    buff_len = read(pid_fd, buff, sizeof(buff)-1);
    if ( buff_len < 0 ) {
        fprintf(stderr, "read(%s): %s\n", pid_file, strerror(errno));
        exit(1);
    }
    buff[buff_len] = '\0';
    if ( buff_len > 0 ) {
        int pid = atoi(buff);
        if ( pid > 0 ) {
            if ( kill(pid, 0) == 0 || EPERM == errno ) {
                fprintf(stderr, "Process already running with pid=%d\n", pid);
                exit(2);
            }
            if ( ESRCH != errno ) {
                fprintf(stderr, "kill(%d): %s\n", pid, strerror(errno));
                exit(1);
            }
        }
    }

    tod_time = time(NULL);
    gmtime_r(&tod_time, &tod_tm);
    strftime(buff, sizeof(buff)-1, "%Y-%m-%dT%H:%M:%SZ", &tod_tm);

    signal(SIGHUP, SIG_IGN);
    child_pid = fork();
    if ( child_pid < 0 ) {
        fprintf(stderr, "fork(): %s\n", strerror(errno));
        exit(1);
    }
    if ( 0 != child_pid ) {
        _exit(0);
    }
    child_pid = fork();
    if ( child_pid < 0 ) {
        fprintf(logf, "fork(): %s\n", strerror(errno));
        exit(1);
    }
    if ( 0 != child_pid ) {
        _exit(0);
    }

    // Write the PID:
    my_pid = getpid();
    fprintf(logf, "%s started '%s' with pid %d\n", buff, cmd[0], my_pid);
    if ( setsid() < 0 ) {
        fprintf(logf, "setsid(): %s\n", strerror(errno));
        exit(1);
    }
    if ( ftruncate(pid_fd, 0) < 0 ) {
        fprintf(logf, "truncate(%s): %s\n", pid_file, strerror(errno));
        exit(1);
    }
    if ( lseek(pid_fd, SEEK_SET, 0) < 0 ) {
        fprintf(logf, "seek(%s): %s\n", pid_file, strerror(errno));
        exit(1);
    }
    if ( fprintf(pid_fd, "%d\n", my_pid) < 0 ) {
        fprintf(logf, "print(%s): %s\n", pid_file, strerror(errno));
        exit(1);
    }
    if ( close(pid_fd) < 0 ) {
        fprintf(logf, "close(%s): %s\n", pid_file, strerror(errno));
        exit(1);
    }

    // NOTE: We MUST redirect this FD to /dev/null, otherwise the fd0
    // will be available for the next file descriptor created.
    if ( dup2(null_fd, STDIN_FILENO) < 0 ) {
        fprintf(logf, "dup2(%d, %d): %s\n", null_fd, STDIN_FILENO, strerror(errno));
        exit(1);
    }
    if ( dup2(log_fd, STDOUT_FILENO) < 0 ) {
        fprintf(logf, "dup2(%d, %d): %s\n", log_fd, STDOUT_FILENO, strerror(errno));
        exit(1);
    }
    if ( dup2(log_fd, STDERR_FILENO) < 0 ) {
        fprintf(logf, "dup2(%d, %d): %s\n", log_fd, STDERR_FILENO, strerror(errno));
        exit(1);
    }
    /* cleanup FDs */
    max_fd = sysconf(_SC_OPEN_MAX);
    for ( i=3; i < max_fd; i++ ) {
        close(i);
    }
    if ( execvp(cmd[0], cmd) < 0 ) {
        fprintf(logf, "execvp(%s): %s\n", cmd[0], strerror(errno));
        exit(1);
    }
}

/*
    char* cmd[] = {
        "sleep",
        "30",
        NULL
    };
    daemonize("/tmp/test.pid", "/tmp/test.log", cmd);
*/
static int Ldaemonize(lua_State* L) {
    int i;
    const char* pid_file = luaL_checkstring(L, 1);
    const char* log_file = luaL_checkstring(L, 2);
    const int cmd_len = lua_gettop(L) - 2;
    char** cmd = (char**)lua_newuserdata(L, (cmd_len+1)*sizeof(char*));
    for ( i=0; i < cmd_len; i++ ) {
        cmd[i] = luaL_checkstring(L, 3+i);
    }
    cmd[cmd_len] = NULL;
    daemonize(pid_file, log_file, cmd);
    return 0;
}

LUALIB_API int luaopen_daemonize(lua_State *L) {
  lua_pushcfunction(L, Ldaemonize);
  return 1;
}

#endif
