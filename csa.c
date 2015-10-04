#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include <sys/param.h>

#if DEBUG
  #define eprintf(format, args...) do{ fprintf(stderr, format , ## args); fflush(stderr); }while(0);
#else
  #define eprintf(format, args...)
#endif

// Generic Arrays in C \o/

#define array_of(type) type##_array
#define define_array_of(type) typedef struct { size_t capacity; size_t count; type * values; } array_of(type);
#define array_at(array,i) array->values[i]
#define array_new_entry(array) ({\
  if ((array)->count==(array)->capacity) {\
    const size_t BLOCK = 4*1024*1024;\
    (array)->capacity+=BLOCK;\
    (array)->values = realloc((array)->values, (array)->capacity*sizeof((array)->values[0]));\
    eprintf("realloced to %zu\n",(array)->capacity);\
  }\
  (array)->count++;\
  &((array)->values[(array)->count-1]);\
})

// Generic raw structure access

void _raw_parse(char* line, unsigned int * raw, size_t capacity) {
    char *token; size_t i=0;
    while ((token = strsep(&line, " ")) && i<capacity) {
        raw[i++] = atoi(token);
    }
}
void _raw_printf(unsigned int * raw, size_t size) {
    for (size_t i=0; i<size; i++) { printf("%i ", raw[i]); } printf("\n");
}

#define raw_parse(line,struct_pointer) _raw_parse(line,(unsigned int *)struct_pointer,sizeof(*struct_pointer)/sizeof(unsigned int))
#define raw_printf(struct_pointer) _raw_printf((unsigned int *)struct_pointer,sizeof(*struct_pointer)/sizeof(unsigned int))


// Data structure

typedef unsigned int station;
typedef unsigned int timestamp;

typedef struct {
    station from;
    station to;
    timestamp start;
    timestamp end;
} connection;
define_array_of(connection);
typedef size_t connection_index;

typedef struct {
    station from;
    station to;
    timestamp start;
} request;

// CSA

void compute_route(array_of(connection) *timetable, request *rq)
{
    const size_t MAX_STATIONS = 100000;
    const timestamp INFINITE = INT_MAX;
    const connection_index INVALID_CONNECTION = INT_MAX;
    
    static connection_index in_connection[MAX_STATIONS];
    static timestamp earliest_arrival[MAX_STATIONS];

    // setup
    for (station s=0; s<MAX_STATIONS; ++s) {
        in_connection[s] = INVALID_CONNECTION;
        earliest_arrival[s] = INFINITE;
    }
    earliest_arrival[rq->from] = rq->start;
    
    // main loop
    timestamp earliest = INFINITE;
    for (connection_index i = 0; i < timetable->count; ++i) {
        connection * c = &array_at(timetable,i);
        if (c->start >= earliest_arrival[c->from] && c->end < earliest_arrival[c->to]) {
            earliest_arrival[c->to] = c->end;
            in_connection[c->to] = i;
            
            if(c->to == rq->to) {
                earliest = MIN(earliest, c->end);
            }
        } else if(c->end > earliest) {
            break;
        }
    }

    // print result
    if(in_connection[rq->to] == INFINITE) {
        printf("NO_SOLUTION\n");
    } else {
        connection_index route[300];
        connection_index last_connection = in_connection[rq->to];
        int i = 0;
        while (last_connection != INFINITE) {
            route[i++] = last_connection;
            last_connection = in_connection[array_at(timetable,last_connection).from];
        }
        
        for (i--; i>=0; i--) {
            raw_printf(&array_at(timetable, route[i]));
        }
    }
    printf("\n");
    fflush(stdout);
}

// Main I/O

int main()
{
    array_of(connection) timetable = {0,0,NULL};

    enum { LOAD, COMPUTE } mode = LOAD;
    char * line = NULL; size_t line_cap = 0; ssize_t linelen;
    while ((linelen = getline(&line,&line_cap,stdin))>0) {
        if(strcmp(line,"\n")==0) {
            eprintf( "%zu connections",t.count);
            mode = COMPUTE;
        } else {
            switch (mode) {
                case LOAD: {
                    raw_parse(line, array_new_entry(&timetable));
                    break;
                }
                case COMPUTE: {
                    request rq;
                    raw_parse(line, &rq);
                    compute_route(&timetable,&rq);
                    break;
                }
            }
        }
    }
    free(line);
    return 0;
}
