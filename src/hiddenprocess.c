#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/resource.h>
#include <sched.h>
#include <errno.h>
#include <signal.h>
#include <time.h>

#define FILE_NAME "process.txt"
#define BUFFER_SIZE 4096

typedef struct
{
    pid_t pid;
    pid_t ppid;
    pid_t pgid;
    pid_t sid;
    uid_t uid;
    gid_t gid;
    int priority;
    int nice;
    int policy;
    char state;
    unsigned long utime;
    unsigned long stime;
    long num_threads;
    unsigned long vsize;
    long rss;
    unsigned long startstack;
} PCB_Info;

// Lire le statut du processus depuis /proc
int read_proc_stat(PCB_Info *pcb)
{
    char path[256];
    FILE *fp;

    snprintf(path, sizeof(path), "/proc/%d/stat", pcb->pid);
    fp = fopen(path, "r");
    if (!fp)
    {
        perror("Échec d'ouverture de /proc/pid/stat");
        return -1;
    }

    fscanf(fp, "%*d %*s %c %d %d %d %*d %*d %*u %*u %*u %*u %*u %lu %lu %*d %*d %d %d %ld %*d %*u %lu %ld %*u %*u %*u %lu",
           &pcb->state, &pcb->ppid, &pcb->pgid, &pcb->sid,
           &pcb->utime, &pcb->stime, &pcb->priority, &pcb->nice , &pcb->num_threads,
           &pcb->vsize, &pcb->rss , &pcb->startstack);

    fclose(fp);
    return 0;
}

int read_proc_status(PCB_Info *pcb)
{
    char path[256];
    char line[256];
    FILE *fp;

    snprintf(path, sizeof(path), "/proc/%d/status", pcb->pid);
    fp = fopen(path, "r");
    if (!fp)
    {
        perror("Échec d'ouverture de /proc/pid/status");
        return -1;
    }

    while (fgets(line, sizeof(line), fp))
    {
        if (sscanf(line, "Uid:\t%d", &pcb->uid) == 1)
            continue;
        if (sscanf(line, "Gid:\t%d", &pcb->gid) == 1)
            continue;
    }

    fclose(fp);
    return 0;
}

void get_pcb_info(PCB_Info *pcb)
{
    pcb->pid = getpid();
    pcb->ppid = getppid();
    pcb->pgid = getpgid(0);
    pcb->sid = getsid(0);
    pcb->uid = getuid();
    pcb->gid = getgid();

    errno = 0;
    pcb->nice = getpriority(PRIO_PROCESS, 0);
    if (errno != 0)
    {
        pcb->nice = 0;
    }

    pcb->policy = sched_getscheduler(0);

    read_proc_stat(pcb);
    read_proc_status(pcb);
}

void write_pcb_to_file(FILE *file, PCB_Info *pcb)
{
    const char *policy_name;
    time_t current_time = time(NULL);
    char time_str[64];

    strftime(time_str, sizeof(time_str), "%Y-%m-%d %H:%M:%S", localtime(&current_time));

    switch (pcb->policy)
    {
    case SCHED_OTHER:
        policy_name = "SCHED_OTHER (Normal)";
        break;
    case SCHED_FIFO:
        policy_name = "SCHED_FIFO (Temps réel FIFO)";
        break;
    case SCHED_RR:
        policy_name = "SCHED_RR (Temps réel Round-Robin)";
        break;
    case SCHED_BATCH:
        policy_name = "SCHED_BATCH (Traitement par lots)";
        break;
    case SCHED_IDLE:
        policy_name = "SCHED_IDLE (Très basse priorité)";
        break;
    default:
        policy_name = "INCONNU";
        break;
    }
    
    fprintf(file, "==================================================\n");
    fprintf(file, "BLOC DE CONTRÔLE DE PROCESSUS (PCB) - INFORMATIONS\n");
    fprintf(file, "==================================================\n");
    fprintf(file, "Dernière mise à jour: %s\n", time_str);
    fprintf(file, "==================================================\n");
    fprintf(file, "Identification du processus:\n");
    fprintf(file, "|  PID (ID du processus): %d\n", pcb->pid);
    fprintf(file, "|  PPID (ID du processus parent): %d\n", pcb->ppid);
    fprintf(file, "|  PGID (ID du groupe de processus): %d\n", pcb->pgid);
    fprintf(file, "|  SID (ID de session): %d\n\n", pcb->sid);
    fprintf(file, "État du processus:\n");
    fprintf(file, "|  État: %c\n", pcb->state);
    fprintf(file, "|  (R=En cours, S=En sommeil, D=Attente disque, Z=Zombie)\n\n");
    fprintf(file, "Propriété du processus:\n");
    fprintf(file, "|  UID (ID utilisateur): %d\n", pcb->uid);
    fprintf(file, "|  GID (ID groupe): %d\n\n", pcb->gid);
    fprintf(file, "Informations d'ordonnancement:\n");
    fprintf(file, "|  Priorité: %d\n", pcb->priority);
    fprintf(file, "|  Valeur Nice: %d\n", pcb->nice);
    fprintf(file, "|  Politique d'ordonnancement: %s\n\n", policy_name);

    fprintf(file, "Temps CPU (en ticks d'horloge):\n");
    fprintf(file, "|  Temps utilisateur: %lu\n", pcb->utime);
    fprintf(file, "|  Temps système: %lu\n\n", pcb->stime);

    fprintf(file, "Informations mémoire:\n");
    fprintf(file, "|  Taille mémoire virtuelle: %lu octets\n", pcb->vsize);
    fprintf(file, "|  Taille ensemble résidant: %ld pages\n", pcb->rss);
    fprintf(file, "|  Pointeur de Pile : %lu \n\n", pcb->startstack);
    
    fprintf(file, "Informations sur les threads:\n");
    fprintf(file, "|  Nombre de threads: %ld\n\n", pcb->num_threads);
    fprintf(file, "==================================================\n");

    fflush(file);
}

int main()
{
    char FILE_PATH[256];
    PCB_Info pcb;

    snprintf(FILE_PATH, sizeof(FILE_PATH), "%s/%s", "/root", FILE_NAME);

    // Ouvrir le fichier en mode écriture pour effacer l'ancien contenu
    FILE *file = fopen(FILE_PATH, "w");

    if (file == NULL)
    {
        perror("Échec d'ouverture du fichier");
        return EXIT_FAILURE;
    }

    printf("Processus Caché Démarré - Enregistrement PCB vers %s\n", FILE_PATH);
    printf("Le PCB sera actualisé toutes les 5 secondes\n\n");

    while (1)
    {
        get_pcb_info(&pcb);

        rewind(file);

        write_pcb_to_file(file, &pcb);

        ftruncate(fileno(file), ftell(file));

        printf("[%ld] PCB mis à jour - PID: %d, État: %c, Threads: %ld\n",
               time(NULL), pcb.pid, pcb.state, pcb.num_threads);

        sleep(5);
    }

    fclose(file);
    return 0;
}
