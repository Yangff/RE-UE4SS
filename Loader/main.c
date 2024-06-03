#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>

int __libc_start_main(
    int (*main)(int, char**, char**), int argc, char** argv, int (*init)(int, char**, char**), void (*fini)(void), void (*rtld_fini)(void), void* stack_end)
{

    // remove LD_PRELOAD from environ
    int nenv = 0;
    for (int i = 0; environ[i]; i++)
        nenv++;
    for (int i = 0; i < nenv; i++)
    {
        if (strncmp(environ[i], "LD_PRELOAD=", 11) == 0)
        {
            fprintf(stderr, "Found LD_PRELOAD @%d %s\n", i, environ[i]);
            environ[i] = environ[nenv - 1];
            nenv--;
        }
    }
    environ[nenv] = NULL;
    typeof(&__libc_start_main) orig = (typeof(&__libc_start_main))dlsym(RTLD_NEXT, "__libc_start_main");
    Dl_info dl_info;
    // find libUE4SS.so path using dlfcn
    if (dladdr((void*)__libc_start_main, &dl_info) == 0)
    {
        fprintf(stderr, "dladdr failed at early: %s\n", dlerror());
        return -1;
    }

    int path_len = strlen(dl_info.dli_fname);
    // copy until last '/'
    int i = path_len - 1;
    for (; i >= 0; i--)
    {
        if (dl_info.dli_fname[i] == '/')
            break;
    }
    char* path = (char*)malloc(i + 1 + strlen("libUE4SS.so") + 1);
    memcpy(path, dl_info.dli_fname, i + 1);
    // append libUE4SS.so
    memcpy(path + i + 1, "libUE4SS.so", strlen("libUE4SS.so") + 1);
    fprintf(stderr, "libUE4SS.so path: %s\n", path);
    void* handle = dlopen(path, RTLD_LAZY | RTLD_LOCAL | RTLD_DEEPBIND);
    if (!handle)
    {
        fprintf(stderr, "dlopen failed: %s\n", dlerror());
        return -1;
    }
    // call ue4ss's libc_start_main
    int __libc_start_main_proxied(
            typeof(&__libc_start_main) orig,
            int (*main)(int, char**, char**), int argc, char** argv, int (*init)(int, char**, char**), void (*fini)(void), void (*rtld_fini)(void), void* stack_end);
  
    typeof(&__libc_start_main_proxied) ue4ss_start_main = (typeof(&__libc_start_main_proxied))dlsym(handle, "__libc_start_main_proxied");
    return ue4ss_start_main(orig, main, argc, argv, init, fini, rtld_fini, stack_end);
}
