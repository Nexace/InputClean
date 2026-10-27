#define main TrackpadCleanMain
#include "main.m"
#undef main
#include <assert.h>

int main(void) {
    EscapeSequence s = {0};
    for (int i=0; i<4; i++) assert(!CountEscape(&s,53,NO,10+i*0.2));
    assert(CountEscape(&s,53,NO,10.8));
    s = (EscapeSequence){0};
    assert(!CountEscape(&s,53,NO,20));
    for (int i=0; i<10; i++) assert(!CountEscape(&s,53,YES,20.1+i*0.1));
    assert(s.count == 1); // A held key never completes the sequence.
    assert(!CountEscape(&s,0,NO,22));
    assert(s.count == 0); // Another key resets the sequence.
    assert(!CountEscape(&s,53,NO,23));
    assert(!CountEscape(&s,53,NO,25));
    assert(s.count == 1); // A pause resets the sequence.
    assert(IsPointerEvent(kCGEventLeftMouseDown));
    assert(IsPointerEvent(kCGEventMouseMoved));
    assert(IsPointerEvent(kCGEventScrollWheel));
    assert(IsPointerEvent((CGEventType)NSEventTypeSwipe));
    assert(IsPointerEvent((CGEventType)NSEventTypeMagnify));
    assert(IsPointerEvent((CGEventType)NSEventTypeRotate));
    assert(!IsPointerEvent(kCGEventKeyDown));
    assert(!IsPointerEvent(kCGEventKeyUp));
    assert(!IsPointerEvent(kCGEventFlagsChanged));
    @autoreleasepool {
        CleanApp *app=[CleanApp new];
        app.mode=CleanTrackpad;
        app.deviceCache=[@{@123:@YES} mutableCopy];
        CGEventRef mouse=CGEventCreateMouseEvent(NULL,kCGEventMouseMoved,CGPointMake(120,200),kCGMouseButtonLeft);
        assert(mouse);
        CGEventSetIntegerValueField(mouse,(CGEventField)87,123);
        CGEventSetIntegerValueField(mouse,kCGMouseEventDeltaX,27);
        CGEventSetIntegerValueField(mouse,kCGMouseEventDeltaY,-8);
        CFDataRef before=CGEventCreateData(NULL,mouse);
        assert(FilterInput(NULL,kCGEventMouseMoved,mouse,(__bridge void *)app)==mouse);
        CFDataRef after=CGEventCreateData(NULL,mouse);
        assert(CFEqual(before,after));
        assert(app.cursorPoint.x==120 && app.cursorPoint.y==200);
        CGEventRef key=CGEventCreateKeyboardEvent(NULL,0,true);assert(key);
        app.mode=CleanKeyboard;
        assert(FilterInput(NULL,kCGEventKeyDown,key,(__bridge void *)app)==NULL);
        app.mode=CleanBoth;
        assert(FilterInput(NULL,kCGEventKeyDown,key,(__bridge void *)app)==NULL);
        app.mode=CleanTrackpad;
        assert(FilterInput(NULL,kCGEventKeyDown,key,(__bridge void *)app)==key);
        assert((ModeMask(CleanKeyboard)&CGEventMaskBit(kCGEventMouseMoved))==0);
        assert((ModeMask(CleanTrackpad)&CGEventMaskBit(14))==0);
        assert(ModeMask(CleanBoth)&CGEventMaskBit(14));
        CFRelease(key);
        CFRelease(before); CFRelease(after); CFRelease(mouse);
    }
    puts("PASS: five-Escape sequence, pointer filtering, and byte-for-byte native mouse preservation");
    return 0;
}
