#include <CoreGraphics/CoreGraphics.h>
#include <libproc.h>
#include <sys/resource.h>
#include <time.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
static double now(void) { struct timespec t;clock_gettime(CLOCK_MONOTONIC,&t);return t.tv_sec+t.tv_nsec/1e9; }
static int cleaning(int pid) {
    CGEventTapInformation taps[128];uint32_t n=0;
    if(CGGetEventTapList(128,taps,&n))return -1;
    for(uint32_t i=0;i<n;i++)if(taps[i].tappingProcess==pid && taps[i].enabled) {
        int pointer=(taps[i].eventsOfInterest & CGEventMaskBit(kCGEventMouseMoved))!=0;
        int keyboard=(taps[i].eventsOfInterest & CGEventMaskBit(14))!=0;
        return (pointer?1:0)|(keyboard?2:0);
    }
    return 0;
}
int main(int argc,char **argv) {
    if(argc!=3)return 1;int pid=atoi(argv[1]);FILE *f=fopen(argv[2],"w");if(!f)return 2;
    struct rusage_info_v4 prior={0};
    if(proc_pid_rusage(pid,RUSAGE_INFO_V4,(rusage_info_t *)&prior))return 3;
    double start=now(),last=start;int seen=0,quiet=0,previous=cleaning(pid),rows=0;
    fputs("[\n",f);
    while(now()-start<600) {
        usleep(500000);struct rusage_info_v4 u={0};
        if(proc_pid_rusage(pid,RUSAGE_INFO_V4,(rusage_info_t *)&u))break;
        double t=now(),cpu=((u.ri_user_time+u.ri_system_time)-(prior.ri_user_time+prior.ri_system_time))/1e9/(t-last)*100;
        int active=cleaning(pid);if(active>0){seen|=(1<<active);quiet=0;}else if(seen)quiet++;
        fprintf(f,"%s{\"seconds\":%.3f,\"cleaning\":%d,\"transition\":%s,\"current_bytes\":%llu,\"peak_bytes\":%llu,\"cpu_percent_one_core\":%.6f}",
            rows++?",\n":"",t-start,active,active!=previous?"true":"false",u.ri_phys_footprint,u.ri_lifetime_max_phys_footprint,cpu);
        fflush(f);prior=u;last=t;previous=active;
        if((seen&14)==14 && quiet>=20)break;
    }
    fputs("\n]\n",f);fclose(f);printf("Recorded %d samples; cleaning_observed=%d\n",rows,seen);
    return (seen&14)==14?0:4;
}
