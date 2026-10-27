#import <AppKit/AppKit.h>
#import <ApplicationServices/ApplicationServices.h>
#import <QuartzCore/QuartzCore.h>
#import <IOKit/IOKitLib.h>
#import <mach/mach.h>
#import <IOSurface/IOSurface.h>
#import <ServiceManagement/SMAppService.h>
#include <dlfcn.h>
#include <string.h>
#include <IOKit/hidsystem/ev_keymap.h>
#include <IOKit/hidsystem/IOLLEvent.h>

typedef NS_OPTIONS(NSUInteger,CleanMode) { CleanTrackpad=1, CleanKeyboard=2, CleanBoth=3 };

typedef struct { NSUInteger count; CFAbsoluteTime last; } EscapeSequence;
static EscapeSequence Escapes;
static BOOL TraceInput;

static BOOL CountEscape(EscapeSequence *sequence, int64_t key, BOOL repeat, CFAbsoluteTime now) {
    if (key != 53) { *sequence = (EscapeSequence){0}; return NO; }
    if (repeat) return NO;
    sequence->count = now-sequence->last <= 1.5 ? sequence->count+1 : 1;
    sequence->last = now;
    return sequence->count >= 5;
}

// AppKit exposes gesture event numbers through NSEvent, not CGEventType.
static BOOL IsPointerEvent(CGEventType type) {
    switch ((uint32_t)type) {
        case 1: case 2: case 3: case 4: case 5: case 6: case 7:
        case 18: case 19: case 20: case 22: case 23: case 24:
        case 25: case 26: case 27: case 29: case 30: case 31:
        case 32: case 33: case 34: return YES;
        default: return NO;
    }
}

static CGEventMask ModeMask(CleanMode mode) {
    CGEventMask mask=CGEventMaskBit(kCGEventKeyDown)|CGEventMaskBit(kCGEventKeyUp)|CGEventMaskBit(kCGEventFlagsChanged);
    if(mode&CleanTrackpad) for(uint32_t i=1;i<64;i++) if(IsPointerEvent((CGEventType)i)) mask|=CGEventMaskBit(i);
    if(mode&CleanKeyboard) mask|=CGEventMaskBit(14);
    return mask;
}

static NSString *ModeStatus(CleanMode mode) {
    return mode==CleanBoth?@"Keyboard & trackpad paused":mode==CleanKeyboard?@"Keyboard input paused":@"Trackpad input paused";
}

static BOOL ModeMenuClick(NSEventType type,NSEventModifierFlags flags) {
    return type==NSEventTypeRightMouseUp || type==NSEventTypeRightMouseDown || (flags&NSEventModifierFlagControl)!=0;
}

static BOOL IsMouseSender(uint64_t sender) {
    if (!sender) return NO;
    io_registry_entry_t entry = IOServiceGetMatchingService(kIOMainPortDefault, IORegistryEntryIDMatching(sender));
    BOOL mouse = NO, builtIn = NO, trackpad = NO;
    for (NSUInteger depth=0; entry && depth<12; depth++) {
        CFMutableDictionaryRef raw = NULL;
        if (IORegistryEntryCreateCFProperties(entry, &raw, NULL, 0) == KERN_SUCCESS) {
            NSDictionary *properties = CFBridgingRelease(raw);
            NSString *product = properties[@"Product"];
            if ([product isKindOfClass:NSString.class] && [product.lowercaseString containsString:@"trackpad"]) trackpad = YES;
            builtIn |= [properties[@"Built-In"] boolValue];
            mouse |= [properties[@"PrimaryUsagePage"] unsignedIntValue] == 1 && [properties[@"PrimaryUsage"] unsignedIntValue] == 2;
            // Stop at the HID device; USB controller parents may themselves be built in.
            if (mouse && [product isKindOfClass:NSString.class] && product.length) {
                IOObjectRelease(entry);
                return !builtIn && !trackpad;
            }
        }
        io_registry_entry_t parent = IO_OBJECT_NULL;
        IORegistryEntryGetParentEntry(entry, kIOServicePlane, &parent);
        IOObjectRelease(entry);
        entry = parent;
    }
    if (entry) IOObjectRelease(entry);
    return mouse && !builtIn && !trackpad;
}

static BOOL IsMouseEvent(CGEventRef event, NSMutableDictionary<NSNumber *,NSNumber *> *cache) {
    // Undocumented sender field used by native per-device mouse utilities.
    // Unknown sources stay blocked; Escape always remains available.
    uint64_t sender = (uint64_t)CGEventGetIntegerValueField(event, (CGEventField)87);
    NSNumber *key = @(sender), *known = cache[key];
    if (known) return known.boolValue;
    BOOL mouse = IsMouseSender(sender);
    if (TraceInput) NSLog(@"InputClean source=%llu externalMouse=%d",sender,mouse);
    if (cache.count >= 16) [cache removeAllObjects];
    cache[key] = @(mouse);
    return mouse;
}

static NSImage *StatusIcon(BOOL cleaning) {
    const size_t side = 40;
    CGContextRef c = CGBitmapContextCreate(NULL, side, side, 8, 0, NULL, (CGBitmapInfo)kCGImageAlphaOnly);
    CGContextScaleCTM(c, 2, 2);
    CGContextSetLineWidth(c, 1.3);
    CGContextSetLineCap(c, kCGLineCapRound);
    CGPathRef shape = CGPathCreateWithRoundedRect(CGRectMake(1.5, 3, 15, 13), 2.6, 2.6, NULL);
    CGContextAddPath(c, shape);
    CGContextStrokePath(c);
    CGPathRelease(shape);
    CGContextMoveToPoint(c, 2.2, 8.5);
    CGContextAddLineToPoint(c, 15.8, 8.5);
    CGContextStrokePath(c);
    for(int row=0;row<2;row++)for(int column=0;column<4;column++)
        CGContextFillRect(c,CGRectMake(3.5+column*3,10+row*2.7,1.2,1.1));
    shape=CGPathCreateWithRoundedRect(CGRectMake(5.4,4.4,6.6,2.5),.6,.6,NULL);
    CGContextAddPath(c,shape);CGContextStrokePath(c);CGPathRelease(shape);
    // A small cleaning sparkle above the keyboard and trackpad.
    CGContextSetBlendMode(c, kCGBlendModeClear);
    CGContextFillRect(c, CGRectMake(12, 11.5, 8, 8));
    CGContextSetBlendMode(c, kCGBlendModeNormal);
    CGContextMoveToPoint(c, 16, 12);
    CGContextAddLineToPoint(c, 16, 18);
    CGContextMoveToPoint(c, 13, 15);
    CGContextAddLineToPoint(c, 19, 15);
    CGContextStrokePath(c);
    if (cleaning) {
        CGContextSetLineWidth(c, 1.8);
        CGContextMoveToPoint(c, 7, 5.3);
        CGContextAddLineToPoint(c, 7, 6);
        CGContextMoveToPoint(c, 10, 5.3);
        CGContextAddLineToPoint(c, 10, 6);
        CGContextStrokePath(c);
    }
    CGImageRef bitmap = CGBitmapContextCreateImage(c);
    NSImage *image = [[NSImage alloc] initWithCGImage:bitmap size:NSMakeSize(20, 20)];
    image.template = YES;
    CGImageRelease(bitmap);
    CGContextRelease(c);
    return image;
}

@interface CardView : NSView
@property NSArray<NSString *> *lines;
@property BOOL paused;
@property id surface;
@end

@implementation CardView
- (BOOL)wantsUpdateLayer { return YES; }
- (NSString *)accessibilityRole { return NSAccessibilityStaticTextRole; }
- (id)accessibilityValue { return [self.lines componentsJoinedByString:@"\n"]; }
- (void)updateLayer { @autoreleasepool {
    CGFloat scale=self.window.backingScaleFactor?:2;
    size_t width=(size_t)ceil(self.bounds.size.width*scale),height=(size_t)ceil(self.bounds.size.height*scale);
    IOSurfaceRef surface=IOSurfaceCreate((__bridge CFDictionaryRef)@{
        (__bridge id)kIOSurfaceWidth:@(width),(__bridge id)kIOSurfaceHeight:@(height),
        (__bridge id)kIOSurfaceBytesPerElement:@4,(__bridge id)kIOSurfaceBytesPerRow:@(width*4),
        (__bridge id)kIOSurfacePixelFormat:@(0x42475241)});
    if(!surface)return;
    IOSurfaceLock(surface,0,NULL);
    CGColorSpaceRef color=CGColorSpaceCreateDeviceRGB();
    CGContextRef context=CGBitmapContextCreate(IOSurfaceGetBaseAddress(surface),width,height,8,IOSurfaceGetBytesPerRow(surface),color,
        (CGBitmapInfo)(kCGImageAlphaPremultipliedFirst|kCGBitmapByteOrder32Little));
    CGColorSpaceRelease(color);
    if(context) {
        CGContextClearRect(context,CGRectMake(0,0,width,height));CGContextScaleCTM(context,scale,scale);
        [NSGraphicsContext saveGraphicsState];
        NSGraphicsContext.currentContext=[NSGraphicsContext graphicsContextWithCGContext:context flipped:NO];
        [self drawRect:self.bounds];[NSGraphicsContext restoreGraphicsState];CGContextRelease(context);
    }
    IOSurfaceUnlock(surface,0,NULL);
    [CATransaction begin];[CATransaction setDisableActions:YES];
    self.layer.contentsScale=scale;self.layer.contentsFormat=kCAContentsFormatRGBA8Uint;
    self.layer.contents=nil;self.surface=CFBridgingRelease(surface);self.layer.contents=self.surface;
    [CATransaction commit];
} }
- (void)drawRect:(NSRect)dirty { @autoreleasepool {
    (void)dirty;
    BOOL dark=[[self.effectiveAppearance bestMatchFromAppearancesWithNames:@[NSAppearanceNameAqua,NSAppearanceNameDarkAqua]] isEqual:NSAppearanceNameDarkAqua];
    NSRect r=NSInsetRect(self.bounds,.5,.5);
    NSBezierPath *outline=[NSBezierPath bezierPathWithRoundedRect:r xRadius:15.5 yRadius:15.5];
    [[NSColor colorWithWhite:1 alpha:dark?.01:.025] setFill];[outline fill];
    [[NSColor colorWithWhite:1 alpha:dark?.18:.65] setStroke];outline.lineWidth=.7;[outline stroke];
    CGFloat ys[]={78,52,17};CGFloat sizes[]={14,13,12};
    for(NSUInteger i=0;i<self.lines.count;i++) {
        CGFloat x=i==1?30:16;
        [self.lines[i] drawAtPoint:NSMakePoint(x,ys[i]) withAttributes:@{
            NSFontAttributeName:[NSFont systemFontOfSize:sizes[i] weight:i==0?NSFontWeightSemibold:NSFontWeightRegular],
            NSForegroundColorAttributeName:i==2?NSColor.secondaryLabelColor:NSColor.labelColor}];
    }
    [[NSColor colorWithSRGBRed:self.paused?.95:.13 green:self.paused?.62:.64 blue:self.paused?.20:.52 alpha:1] setFill];
    [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(16,57,6,6)] fill];
    [[NSColor colorWithWhite:dark?1:0 alpha:.08] setStroke];
    NSBezierPath *line=[NSBezierPath bezierPath];line.lineWidth=.5;
    [line moveToPoint:NSMakePoint(16,39)];[line lineToPoint:NSMakePoint(NSWidth(self.bounds)-16,39)];[line stroke];
} }
@end

@interface CleanApp : NSObject <NSApplicationDelegate>
@property NSStatusItem *item;
@property NSImage *readyIcon;
@property NSImage *cleaningIcon;
@property NSTimer *hoverTimer;
@property NSTimer *unlockTimer;
@property BOOL menuOpen;
@property BOOL askedForAccess;
@property BOOL cleaning;
@property CleanMode mode;
@property CleanMode selectedMode;
@property CleanMode pendingMode;
@property NSMutableDictionary<NSNumber *,NSNumber *> *deviceCache;
@property CFMachPortRef tap;
@property CFRunLoopSourceRef tapSource;
@property NSPanel *panel;
@property CardView *cardView;
@property NSPoint anchor;
@property NSUInteger blockedEvents;
@property NSUInteger mouseEvents;
@property CGPoint cursorPoint;
@property NSMenu *activeMenu;
- (void)stopCleaning;
- (void)startCleaning:(CleanMode)mode;
@end

static CGEventRef FilterInput(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *context) {
    (void)proxy;
    CleanApp *app = (__bridge CleanApp *)context;
    if (type == kCGEventTapDisabledByTimeout || type == kCGEventTapDisabledByUserInput) {
        BOOL resumed=NO;
        if (app.tap && CFMachPortIsValid(app.tap)) {
            CGEventTapEnable(app.tap,true);
            resumed=CGEventTapIsEnabled(app.tap);
        }
        if (TraceInput) NSLog(@"InputClean filter disabled type=%u resumed=%d",type,resumed);
        if (!resumed) dispatch_async(dispatch_get_main_queue(), ^{ [app stopCleaning]; });
        return event;
    }
    if (type == kCGEventKeyDown) {
        if (CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode) == 53) {
            if (CountEscape(&Escapes, 53, CGEventGetIntegerValueField(event, kCGKeyboardEventAutorepeat), CFAbsoluteTimeGetCurrent()))
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (TraceInput) NSLog(@"InputClean keyboard unlock completed");
                    [app stopCleaning];
                });
            return NULL;
        }
        Escapes = (EscapeSequence){0};
    }
    if (type == kCGEventKeyUp && CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode) == 53) return NULL;
    if (type == kCGEventFlagsChanged) Escapes = (EscapeSequence){0};
    if(app.mode&CleanKeyboard) {
        if(type==kCGEventKeyDown || type==kCGEventKeyUp || type==kCGEventFlagsChanged) { app.blockedEvents++;return NULL; }
        if((uint32_t)type==14) { @autoreleasepool {
            NSEvent *key=[NSEvent eventWithCGEvent:event];
            if(key.subtype==NX_SUBTYPE_AUX_CONTROL_BUTTONS && ((key.data1>>16)&0xFFFF)!=NX_POWER_KEY)return NULL;
        } }
    }
    if(!(app.mode&CleanTrackpad))return event;
    if (!IsPointerEvent(type)) return event;
    @autoreleasepool {
        if (IsMouseEvent(event, app.deviceCache)) {
            app.mouseEvents++;
            // Preserve every native mouse field, including acceleration and sensitivity.
            app.cursorPoint=CGEventGetLocation(event);
            return event;
        }
        app.blockedEvents++;
        if (type == kCGEventMouseMoved || type == kCGEventLeftMouseDragged ||
            type == kCGEventRightMouseDragged || type == kCGEventOtherMouseDragged) {
            CGEventSetLocation(event,app.cursorPoint);
            CGWarpMouseCursorPosition(app.cursorPoint);
        }
        return NULL;
    }
}

@implementation CleanApp
- (instancetype)init { if((self=[super init]))_selectedMode=CleanTrackpad;return self; }
- (void)applicationDidFinishLaunching:(NSNotification *)notification { @autoreleasepool {
    (void)notification;
    self.readyIcon = StatusIcon(NO);
    self.cleaningIcon = StatusIcon(YES);
    self.item = [NSStatusBar.systemStatusBar statusItemWithLength:NSSquareStatusItemLength];
    self.item.button.image = self.readyIcon;
    self.item.button.accessibilityLabel = @"InputClean";
    self.item.button.accessibilityHelp = @"Click to toggle the selected cleaning mode. Control-click or right-click to choose trackpad, keyboard, or both. Press Escape five times to restore input.";
    self.item.button.target = self;
    self.item.button.action = @selector(clicked:);
    [self.item.button sendActionOn:NSEventMaskLeftMouseUp | NSEventMaskRightMouseUp];
    [self.item.button addTrackingArea:[[NSTrackingArea alloc] initWithRect:NSZeroRect
        options:NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways | NSTrackingInVisibleRect
        owner:self userInfo:nil]];
    [NSDistributedNotificationCenter.defaultCenter addObserver:self selector:@selector(stopCleaning)
        name:@"com.apple.screenIsLocked" object:nil];
} }
- (void)hideCard { @autoreleasepool {
    BOOL hadPanel=self.panel!=nil;
    [self.hoverTimer invalidate]; self.hoverTimer = nil;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(closeCard) object:nil];
    [self.panel orderOut:nil];
    self.cardView.layer.contents=nil;self.cardView.surface=nil;
    self.panel.contentView=nil;[self.panel close];self.panel=nil;self.cardView=nil;
    [CATransaction flush];
    // Let AppKit drain deferred window resources even when the pointer stops moving.
    if(hadPanel)[NSApp postEvent:[NSEvent otherEventWithType:NSEventTypeApplicationDefined
        location:NSZeroPoint modifierFlags:0 timestamp:0 windowNumber:0 context:nil subtype:0 data1:0 data2:0] atStart:NO];
} }
- (void)showCardWithStatus:(NSString *)status detail:(NSString *)detail pinned:(BOOL)pinned { @autoreleasepool {
    [self hideCard];
    [self presentCardWithStatus:status detail:detail pinned:pinned];
} }
- (void)mouseEntered:(NSEvent *)event {
    (void)event;
    if (self.cleaning) return;
    [self.hoverTimer invalidate];
    self.hoverTimer = [NSTimer scheduledTimerWithTimeInterval:0.45 target:self selector:@selector(showHover)
        userInfo:nil repeats:NO];
}
- (void)mouseExited:(NSEvent *)event { (void)event; if (!self.cleaning) [self hideCard]; }
- (void)showHover {
    if (self.menuOpen || self.cleaning) return;
    NSString *ready=self.selectedMode==CleanKeyboard?@"Keyboard ready":self.selectedMode==CleanBoth?@"Keyboard & trackpad ready":@"Trackpad ready";
    [self showCardWithStatus:ready detail:@"Click to pause · Ctrl-click for options" pinned:NO];
}
- (void)clicked:(id)sender {
    (void)sender;
    NSEvent *event=NSApp.currentEvent;
    BOOL menu=ModeMenuClick(event.type,event.modifierFlags|NSEvent.modifierFlags);
    [self hideCard];
    if (menu) {
        [self presentMenu];
        return;
    }
    [self toggleCleaning];
}
- (void)toggleCleaning {
    if (self.cleaning) {
        if (TraceInput) NSLog(@"InputClean icon/menu unlock");
        [self stopCleaning]; return;
    }
    [self startCleaning:self.selectedMode];
}
- (void)startCleaning:(CleanMode)mode {
    if(!mode || (mode&~CleanBoth))return;
    if (!AXIsProcessTrusted()) {
        if (!self.askedForAccess) {
            self.askedForAccess = YES;
            AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)@{(__bridge NSString *)kAXTrustedCheckOptionPrompt:@YES});
        }
        [self showCardWithStatus:@"Allow Accessibility access" detail:@"Enable InputClean, then click again" pinned:NO];
        return;
    }
    // The HID entry point is root-restricted; Accessibility permits a session filter.
    self.tap = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap, kCGEventTapOptionDefault,
        ModeMask(mode), FilterInput, (__bridge void *)self);
    if (TraceInput) NSLog(@"InputClean session filter created=%d",self.tap != NULL);
    if (!self.tap) {
        [self showCardWithStatus:@"Input could not be paused" detail:@"Check Accessibility access, then try again" pinned:NO];
        return;
    }
    self.tapSource = CFMachPortCreateRunLoopSource(NULL, self.tap, 0);
    if (!self.tapSource) { [self stopCleaning]; return; }
    self.deviceCache = [NSMutableDictionary dictionary];
    self.mode=mode;
    CFRunLoopAddSource(CFRunLoopGetMain(), self.tapSource, kCFRunLoopCommonModes);
    CGEventTapEnable(self.tap, true);
    if (!CGEventTapIsEnabled(self.tap)) { [self stopCleaning]; return; }
    CGEventRef position=CGEventCreate(NULL);
    if (!position) { [self stopCleaning]; return; }
    self.cursorPoint=CGEventGetLocation(position);
    CFRelease(position);
    self.cleaning = YES;
    self.blockedEvents = 0; self.mouseEvents = 0;
    self.item.button.image = self.cleaningIcon;
    self.item.button.accessibilityValue = ModeStatus(mode);
    self.unlockTimer = [NSTimer scheduledTimerWithTimeInterval:300 target:self selector:@selector(stopCleaning)
        userInfo:nil repeats:NO];
    if(TraceInput)NSLog(@"InputClean started mode=%lu",(unsigned long)mode);
    [self showCardWithStatus:ModeStatus(mode) detail:@"Click icon or press Esc ×5 to restore" pinned:YES];
}
- (void)stopCleaning {
    @autoreleasepool {
        if (TraceInput && self.cleaning) NSLog(@"InputClean stopped blocked=%lu mousePassed=%lu",self.blockedEvents,self.mouseEvents);
        [self.unlockTimer invalidate]; self.unlockTimer = nil;
        if (self.tap) { CGEventTapEnable(self.tap, false); CFMachPortInvalidate(self.tap); }
        if (self.tapSource) { CFRunLoopRemoveSource(CFRunLoopGetMain(), self.tapSource, kCFRunLoopCommonModes); CFRelease(self.tapSource); self.tapSource = NULL; }
        if (self.tap) { CFRelease(self.tap); self.tap = NULL; }
        self.cleaning = NO;
        self.mode=0;
        self.pendingMode=0;
        [self.activeMenu cancelTracking];
        self.deviceCache = nil;
        Escapes = (EscapeSequence){0};
        self.item.button.image = self.readyIcon;
        self.item.button.accessibilityValue = @"Ready";
        [self hideCard];
    }
}
- (void)selectMode:(NSMenuItem *)item {
    if(item.tag<(NSInteger)CleanTrackpad || item.tag>(NSInteger)CleanBoth)return;
    self.selectedMode=(CleanMode)item.tag;
    if(TraceInput)NSLog(@"InputClean selected mode=%lu",(unsigned long)self.selectedMode);
    BOOL stop=self.cleaning && self.mode==(CleanMode)item.tag;
    [self stopCleaning];
    if(!stop) {
        if(self.menuOpen)self.pendingMode=(CleanMode)item.tag;
        else [self startCleaning:(CleanMode)item.tag];
    }
}
- (NSMenu *)makeMenu {
    NSMenu *menu = [NSMenu new];
    NSArray *titles=@[@"Clean trackpad",@"Clean keyboard",@"Clean both"];
    for(NSUInteger i=0;i<titles.count;i++) {
        NSMenuItem *item=[[NSMenuItem alloc]initWithTitle:titles[i] action:@selector(selectMode:) keyEquivalent:@""];
        item.target=self;item.tag=(NSInteger)i+1;
        item.state=(self.cleaning?self.mode:self.selectedMode)==(CleanMode)item.tag?NSControlStateValueOn:NSControlStateValueOff;
        [menu addItem:item];
    }
    if(self.cleaning) {
        [menu addItem:NSMenuItem.separatorItem];
        NSMenuItem *restore=[[NSMenuItem alloc]initWithTitle:@"Restore input" action:@selector(stopCleaning) keyEquivalent:@""];
        restore.target=self;[menu addItem:restore];
    }
    [menu addItem:NSMenuItem.separatorItem];
    NSMenuItem *quit = [[NSMenuItem alloc] initWithTitle:@"Quit InputClean" action:@selector(terminate:) keyEquivalent:@""];
    quit.target = NSApp; [menu addItem:quit];
    return menu;
}
- (void)presentMenu { @autoreleasepool {
    NSMenu *menu=[self makeMenu];self.activeMenu=menu;
    self.menuOpen = YES;
    [menu popUpMenuPositioningItem:nil atLocation:NSEvent.mouseLocation inView:nil];
    self.menuOpen = NO;
    self.activeMenu=nil;
    CleanMode requested=self.pendingMode;self.pendingMode=0;
    // Create keyboard taps after AppKit has left the menu's tracking loop.
    if(requested)dispatch_async(dispatch_get_main_queue(), ^{ [self startCleaning:requested]; });
} }
- (void)presentCardWithStatus:(NSString *)status detail:(NSString *)detail pinned:(BOOL)pinned { @autoreleasepool {
    self.anchor = NSEvent.mouseLocation;
    NSRect bounds = NSMakeRect(0, 0, 300, 112);
    NSPanel *panel = [[NSPanel alloc] initWithContentRect:bounds
        styleMask:NSWindowStyleMaskBorderless | NSWindowStyleMaskNonactivatingPanel
        backing:NSBackingStoreBuffered defer:NO];
    panel.level = NSPopUpMenuWindowLevel;
    panel.hidesOnDeactivate = NO; panel.ignoresMouseEvents = YES;
    panel.releasedWhenClosed=NO;panel.colorSpace=NSColorSpace.sRGBColorSpace;
    panel.hasShadow = YES; panel.opaque = NO; panel.backgroundColor = NSColor.clearColor;
    panel.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorFullScreenAuxiliary;
    CardView *card=[[CardView alloc]initWithFrame:bounds];card.lines=@[@"InputClean",status,detail];
    card.paused=self.cleaning;card.wantsLayer=YES;self.cardView=card;
    if(@available(macOS 26.0,*)) {
        NSGlassEffectView *glass=[[NSGlassEffectView alloc]initWithFrame:bounds];
        glass.style=NSGlassEffectViewStyleClear;glass.cornerRadius=16;glass.contentView=card;
        panel.contentView=glass;
    } else {
        NSVisualEffectView *glass=[[NSVisualEffectView alloc]initWithFrame:bounds];
        glass.material=NSVisualEffectMaterialPopover;glass.blendingMode=NSVisualEffectBlendingModeBehindWindow;
        glass.state=NSVisualEffectStateActive;glass.wantsLayer=YES;glass.layer.cornerRadius=16;glass.layer.masksToBounds=YES;
        [glass addSubview:card];panel.contentView=glass;
    }
    NSScreen *screen = NSScreen.mainScreen;
    for (NSScreen *candidate in NSScreen.screens) if (NSPointInRect(self.anchor, candidate.frame)) { screen = candidate; break; }
    NSRect frame = screen.visibleFrame;
    CGFloat x = MAX(NSMinX(frame)+6, MIN(self.anchor.x-bounds.size.width/2, NSMaxX(frame)-bounds.size.width-6));
    [panel setFrameOrigin:NSMakePoint(x, MIN(self.anchor.y-16, NSMaxY(frame)-6)-bounds.size.height)];
    self.panel = panel;
    [panel orderFrontRegardless];
    [self performSelector:@selector(closeCard) withObject:nil afterDelay:pinned?301:8];
} }
- (void)closeCard { [self hideCard]; }
- (void)applicationWillTerminate:(NSNotification *)notification {
    (void)notification;
    [self stopCleaning];
}
@end

int main(int argc, const char *argv[]) {
    if(argc==2 && (strcmp(argv[1],"--enable-login")==0 || strcmp(argv[1],"--disable-login")==0 || strcmp(argv[1],"--login-status")==0)) { @autoreleasepool {
        if(@available(macOS 13.0,*)) {
            void *library=dlopen("/System/Library/Frameworks/ServiceManagement.framework/ServiceManagement",RTLD_LAZY|RTLD_LOCAL);
            Class serviceClass=library?NSClassFromString(@"SMAppService"):Nil;
            SMAppService *service=serviceClass?[serviceClass mainAppService]:nil;
            NSError *error=nil;
            BOOL query=strcmp(argv[1],"--login-status")==0,enable=strcmp(argv[1],"--enable-login")==0;
            SMAppServiceStatus desired=enable?SMAppServiceStatusEnabled:SMAppServiceStatusNotRegistered;
            BOOL ok=service && (query || service.status==desired ||
                (enable?[service registerAndReturnError:&error]:[service unregisterAndReturnError:&error]));
            printf("login_status=%ld\n",service?(long)service.status:-1L);
            if(error)fprintf(stderr,"%s\n",error.localizedDescription.UTF8String);
            return ok && (query || service.status==desired)?0:2;
        }
        return 2;
    } }
    TraceInput = getenv("INPUTCLEAN_DIAGNOSTICS") != NULL;
    NSApplication *application;
    __attribute__((objc_precise_lifetime)) CleanApp *delegate;
    @autoreleasepool {
        application = NSApplication.sharedApplication;
        [application setActivationPolicy:NSApplicationActivationPolicyAccessory];
        delegate = [CleanApp new];
        application.delegate = delegate;
    }
    @autoreleasepool {
        [application run];
    }
    return 0;
}
