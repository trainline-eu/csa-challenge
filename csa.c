#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include <sys/param.h>

typedef union {
    struct {
        int from;
        int to;
        int start;
        int end;
    };
    int args[4];
}connection;

struct {
    int capacity;
    int count;
    connection * c;
} timetable;

void print_connection(connection c) {
    printf("%i %i %i %i\n",c.from, c.to, c.start, c.end);
}

typedef union {
    struct {
        int from;
        int to;
        int start;
    };
    int args[3];
}request;

const int MAX_STATIONS = 100000;
const int INF = INT_MAX;

int in_connection[MAX_STATIONS];
int earliest_arrival[MAX_STATIONS];

void compute_route(request r)
{
    // setup
    for (int i=0; i<MAX_STATIONS; ++i) {
        earliest_arrival[i] = in_connection[i] = INF;
    }
    earliest_arrival[r.from] = r.start;
    
    // main loop
    int earliest = INF;
    for (int i = 0; i < timetable.count; ++i) {
        connection current_c = timetable.c[i];
        if (current_c.start >= earliest_arrival[current_c.from] && current_c.end < earliest_arrival[current_c.to]) {
            earliest_arrival[current_c.to] = current_c.end;
            in_connection[current_c.to] = i;
            
            if(current_c.to == r.to) {
                earliest = MIN(earliest, current_c.end);
            }
        } else if(current_c.end > earliest) {
            break;
        }
    }
    
    //
    if(in_connection[r.to] == INF) {
        printf("NO_SOLUTION\n");
    } else {
        connection route[300];
        // We have to rebuild the route from the arrival station
        int last_connection_index = in_connection[r.to];
        int i = 0;
        while (last_connection_index != INF) {
            connection c = timetable.c[last_connection_index];
            route[i++] = c;
            last_connection_index = in_connection[c.from];
        }
        
        // And now print it out in the right direction
        for (i--; i>=0; i--) {
            print_connection(route[i]);
        }
    }
    printf("\n");
    fflush(stdout);
}

int main()
{
    const int BLOCK = 1024;
    timetable.capacity = BLOCK;
    timetable.c = malloc(timetable.capacity*sizeof(connection));
    timetable.count = 0;
    enum { LOAD, COMPUTE } mode = LOAD;
    char * buf = NULL;
    size_t linecap = 0;
    ssize_t linelen;
    while ((linelen = getline(&buf,&linecap,stdin))>0) {
        if(strcmp(buf,"\n")==0) {
            mode = COMPUTE;
        } else {
            switch (mode) {
                case LOAD: {
                    char *line=buf; char *token; int i=0;
                    connection *c = &timetable.c[timetable.count++];
                    while ((token = strsep(&line, " ")) && i<4) {
                        c->args[i++] = atoi(token);
                    }
                    if (timetable.count==timetable.capacity) {
                        timetable.capacity+=BLOCK;
                        timetable.c = realloc(timetable.c, timetable.capacity*sizeof(connection));
//                        fprintf(stderr,"realloced to %d\n",timetable.capacity);
                    }
                    break;
                }
                case COMPUTE:{
                    char *line=buf; char *token; int i=0;
                    request r;
                    while ((token = strsep(&line, " ")) && i<4) {
                        r.args[i++] = atoi(token);
                    }
                    compute_route(r);
                    break;
                }
            }
        }
    }
    free(buf);
    return 0;
}
