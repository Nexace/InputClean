#define main InputCleanMain
#include "../main.m"
#undef main

@interface PhotoBackdrop:NSView
@end
@implementation PhotoBackdrop
- (void)drawRect:(NSRect)dirty {
    (void)dirty;
    NSGradient *gradient=[[NSGradient alloc]initWithStartingColor:[NSColor colorWithSRGBRed:.04 green:.12 blue:.24 alpha:1]
        endingColor:[NSColor colorWithSRGBRed:.17 green:.66 blue:.66 alpha:1]];
    [gradient drawInRect:self.bounds angle:20];
}
@end

@interface PhotoApp:CleanApp
@property NSWindow *backdrop;
@property NSString *destination;
@end
@implementation PhotoApp
// Photos exercise the real views without installing an input filter.
- (void)startCleaning:(CleanMode)mode { (void)mode; }
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    (void)notification;NSApp.appearance=[NSAppearance appearanceNamed:NSAppearanceNameDarkAqua];
    NSRect screen=NSScreen.mainScreen.visibleFrame;
    NSRect frame=NSMakeRect(NSMidX(screen)-350,NSMidY(screen)-130,700,260);
    self.backdrop=[[NSWindow alloc]initWithContentRect:frame styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:NO];
    self.backdrop.level=NSFloatingWindowLevel;self.backdrop.opaque=YES;self.backdrop.ignoresMouseEvents=YES;
    self.backdrop.contentView=[[PhotoBackdrop alloc]initWithFrame:NSMakeRect(0,0,700,260)];
    [NSApp activate];[self.backdrop orderFrontRegardless];[self.backdrop display];[self showHover];[self centerCard];
    [self performSelector:@selector(readyPhoto) withObject:nil afterDelay:.6];
}
- (void)centerCard {
    NSRect frame=self.backdrop.frame;
    [self.panel setFrameOrigin:NSMakePoint(NSMidX(frame)-150,NSMidY(frame)-56)];
}
- (void)capture:(NSString *)name {
    NSArray *windows=CFBridgingRelease(CGWindowListCopyWindowInfo(kCGWindowListOptionIncludingWindow,(CGWindowID)self.backdrop.windowNumber));
    NSDictionary *window=nil;
    for(NSDictionary *candidate in windows)if([candidate[(__bridge id)kCGWindowNumber] integerValue]==self.backdrop.windowNumber)window=candidate;
    if(![window[(__bridge id)kCGWindowIsOnscreen] boolValue]){fprintf(stderr,"Photo backdrop is not visible\n");return;}
    CGRect rect=CGRectZero;CGRectMakeWithDictionaryRepresentation((__bridge CFDictionaryRef)window[(__bridge id)kCGWindowBounds],&rect);
    NSString *request=[self.destination stringByAppendingPathComponent:@".capture-request.json"];
    NSString *ack=[self.destination stringByAppendingPathComponent:@".capture-done"];
    [NSFileManager.defaultManager removeItemAtPath:ack error:NULL];
    NSDictionary *capture=@{@"name":name,@"rect":@[@(rect.origin.x),@(rect.origin.y),@(rect.size.width),@(rect.size.height)]};
    [[NSJSONSerialization dataWithJSONObject:capture options:0 error:NULL] writeToFile:request atomically:YES];
    CFAbsoluteTime deadline=CFAbsoluteTimeGetCurrent()+8;
    while(CFAbsoluteTimeGetCurrent()<deadline && ![NSFileManager.defaultManager fileExistsAtPath:ack])
        CFRunLoopRunInMode(kCFRunLoopDefaultMode,.05,false);
    [NSFileManager.defaultManager removeItemAtPath:request error:NULL];
    [NSFileManager.defaultManager removeItemAtPath:ack error:NULL];
}
- (void)readyPhoto {
    [self capture:@"ready.png"];self.cleaning=YES;self.mode=CleanBoth;
    [self showCardWithStatus:ModeStatus(CleanBoth) detail:@"Click icon or press Esc ×5 to restore" pinned:YES];[self centerCard];
    [self performSelector:@selector(pausedPhoto) withObject:nil afterDelay:.6];
}
- (void)pausedPhoto {
    [self capture:@"paused.png"];[self hideCard];self.cleaning=NO;
    NSMenu *menu=[self makeMenu];
    NSTimer *capture=[NSTimer timerWithTimeInterval:.6 repeats:NO block:^(NSTimer *timer){
        (void)timer;[self capture:@"mode-menu.png"];[menu cancelTracking];
    }];
    [NSRunLoop.mainRunLoop addTimer:capture forMode:NSRunLoopCommonModes];
    [menu popUpMenuPositioningItem:nil atLocation:NSMakePoint((700-menu.size.width)/2,(260+menu.size.height)/2-6) inView:self.backdrop.contentView];
    [capture invalidate];[self.backdrop close];[NSApp terminate:nil];
}
@end
int main(int argc,const char *argv[]) { @autoreleasepool {
    if(argc!=2){fprintf(stderr,"Usage: screenshots OUTPUT_DIR\n");return 2;}
    [NSApplication.sharedApplication setActivationPolicy:NSApplicationActivationPolicyAccessory];
    __attribute__((objc_precise_lifetime)) PhotoApp *app=[PhotoApp new];app.destination=@(argv[1]);
    [NSFileManager.defaultManager createDirectoryAtPath:app.destination withIntermediateDirectories:YES attributes:nil error:NULL];
    NSApp.delegate=app;[NSApp run];
} }
