#import <Foundation/Foundation.h>
#include <spawn.h>
#include <sys/wait.h>
#include <unistd.h>
#include <errno.h>
extern char **environ;

__attribute__((visibility("default")))
int idterm_execute(const char *command) {
    if (!command || !*command) return EINVAL;
    char *const argv[] = {"sh", "-c", (char *)command, NULL};
    pid_t pid = 0;
    int rc = posix_spawn(&pid, "/bin/sh", NULL, NULL, argv, environ);
    if (rc != 0) return rc;
    int status = 0;
    if (waitpid(pid, &status, 0) < 0) return errno;
    if (WIFEXITED(status)) return WEXITSTATUS(status);
    return 128 + WTERMSIG(status);
}
__attribute__((constructor))
static void idterm_loaded(void) { NSLog(@"[IDTermDylib] loaded; shell bridge ready"); }