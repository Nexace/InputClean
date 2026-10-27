#define main TrackpadCleanMain
#include "../main.m"
#undef main
#include <libproc.h>
#include <sys/resource.h>
#include <unistd.h>

static NSDictionary *Stats(void) {
    struct rusage_info_v4 u={0};
    proc_pid_rusage(getpid(),RUSAGE_INFO_V4,(rusage_info_t *)&u);
    return @{@"current_bytes":@(u.ri_phys_footprint),@"peak_bytes":@(u.ri_lifetime_max_phys_footprint),
        @"cpu_ns":@(u.ri_user_time+u.ri_system_time)};
}
@interface UIProfile:CleanApp
@property NSMutableArray *samples;
@property NSDictionary *start;
@property CFAbsoluteTime started;
@property NSUInteger cycle;
@property NSUInteger menuCycle;
@end
@implementation UIProfile
- (void)applicationDidFinishLaunching:(NSNotification *)n {
    @autoreleasepool { [super applicationDidFinishLaunching:n]; self.samples=[NSMutableArray array]; }
    [self beginPhase];
    [self performSelector:@selector(idleDone) withObject:nil afterDelay:10];
}
- (void)beginPhase { self.start=Stats();self.started=CFAbsoluteTimeGetCurrent(); }
- (void)record:(NSString *)name {
    NSMutableDictionary *s=[Stats() mutableCopy];double duration=CFAbsoluteTimeGetCurrent()-self.started;
    s[@"phase"]=name;s[@"seconds"]=@(duration);
    s[@"cpu_percent_one_core"]=@(([s[@"cpu_ns"] unsignedLongLongValue]-[self.start[@"cpu_ns"] unsignedLongLongValue])/1e9/duration*100);
    [self.samples addObject:s];printf("%s\n",[[s description] UTF8String]);fflush(stdout);
}
- (void)idleDone { [self record:@"idle"];[self beginPhase];[self cycleCard]; }
- (void)cycleCard { @autoreleasepool {
    if(self.panel) [self hideCard];
    else [self showCardWithStatus:@"Ready to clean" detail:@"Click to pause · Esc ×5 to restore" pinned:YES];
    self.cycle++;
    if(self.cycle<60) [self performSelector:@selector(cycleCard) withObject:nil afterDelay:.1];
    else { [self hideCard];[self record:@"30_hover_cycles"];[self beginPhase];[self cycleMenu]; }
} }
- (void)cycleMenu { @autoreleasepool {
    NSMenu *menu=[self makeMenu];menu.autoenablesItems=NO;
    for(NSMenuItem *item in menu.itemArray)item.enabled=NO;
    NSTimer *close=[NSTimer timerWithTimeInterval:.15 repeats:NO block:^(NSTimer *timer){(void)timer;[menu cancelTracking];}];
    [NSRunLoop.mainRunLoop addTimer:close forMode:NSRunLoopCommonModes];
    [menu popUpMenuPositioningItem:nil atLocation:NSEvent.mouseLocation inView:nil];
    self.menuCycle++;
    if(self.menuCycle<5)[self performSelector:@selector(cycleMenu) withObject:nil afterDelay:.1];
    else { [self record:@"5_menu_cycles"];[self beginPhase];[self performSelector:@selector(finish) withObject:nil afterDelay:10]; }
} }
- (void)finish {
    [self record:@"post_hover_idle"];
    NSData *json=[NSJSONSerialization dataWithJSONObject:self.samples options:NSJSONWritingPrettyPrinted error:NULL];
    NSString *output=NSProcessInfo.processInfo.arguments.lastObject;
    [json writeToFile:output atomically:YES];[NSApp terminate:nil];
}
@end
int main(void) {
    @autoreleasepool {
        [NSApplication.sharedApplication setActivationPolicy:NSApplicationActivationPolicyAccessory];
        __attribute__((objc_precise_lifetime)) UIProfile *p=[UIProfile new];NSApp.delegate=p;[NSApp run];
    }
}
