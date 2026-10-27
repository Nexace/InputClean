#define main TrackpadCleanMain
#include "../main.m"
#undef main
#include <assert.h>

int main(int argc,const char *argv[]) {
    @autoreleasepool {
        [NSApplication.sharedApplication setActivationPolicy:NSApplicationActivationPolicyAccessory];
        CleanApp *app=[CleanApp new];
        NSMenu *menu=[app makeMenu];
        assert(menu.itemArray.count==5);
        assert([menu.itemArray[1].title isEqualToString:@"Clean keyboard"]);
        assert([menu.itemArray[2].title isEqualToString:@"Clean both"]);
        for(NSArray *lines in @[@[@"Ready to clean",@"Click to pause · Esc ×5 to restore"],
                               @[@"Trackpad input paused",@"Mouse: click icon · Keyboard: Esc ×5"],
                               @[@"Keyboard input paused",@"Click icon or press Esc ×5 to restore"],
                               @[@"Keyboard & trackpad paused",@"Click icon or press Esc ×5 to restore"],
                               @[@"Allow Accessibility access",@"Enable TrackpadClean, then click again"]]) {
            [app showCardWithStatus:lines[0] detail:lines[1] pinned:YES];
            CGFloat sizes[]={14,13,12};
            for(NSUInteger i=0;i<3;i++) {
                NSString *line=app.cardView.lines[i];
                CGFloat width=[line sizeWithAttributes:@{NSFontAttributeName:[NSFont systemFontOfSize:sizes[i]
                    weight:i==0?NSFontWeightSemibold:NSFontWeightRegular]}].width;
                assert(width+(i==1?30:16)<=NSWidth(app.cardView.bounds)-16);
            }
            assert([[app.cardView accessibilityValue] containsString:lines[1]]);
            [app hideCard];assert(!app.panel && !app.cardView);
        }
        if(argc==2) {
            [app showCardWithStatus:@"Ready to clean" detail:@"Click to pause · Esc ×5 to restore" pinned:YES];
            NSImage *image=[[NSImage alloc]initWithSize:app.cardView.bounds.size];
            [image lockFocus];[NSColor.windowBackgroundColor setFill];NSRectFill(app.cardView.bounds);
            [app.cardView drawRect:app.cardView.bounds];[image unlockFocus];
            NSBitmapImageRep *bitmap=[[NSBitmapImageRep alloc]initWithData:image.TIFFRepresentation];
            [[bitmap representationUsingType:NSBitmapImageFileTypePNG properties:@{}] writeToFile:@(argv[1]) atomically:YES];
            [app hideCard];
        }
        puts("PASS: card text fits, accessibility text is present, and card resources are released");
    }
}
