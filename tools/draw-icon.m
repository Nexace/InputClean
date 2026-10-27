#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <ImageIO/ImageIO.h>

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        if (argc != 2) return 1;
        CGColorSpaceRef space = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
        CGContextRef c = CGBitmapContextCreate(NULL, 1024, 1024, 8, 0, space, (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
        CGPathRef tile = CGPathCreateWithRoundedRect(CGRectMake(80,80,864,864), 194,194,NULL);
        CGContextAddPath(c,tile); CGContextClip(c);
        CGFloat colors[] = {0.04,0.19,0.25,1, 0.13,0.63,0.66,1};
        CGGradientRef gradient = CGGradientCreateWithColorComponents(space,colors,NULL,2);
        CGContextDrawLinearGradient(c,gradient,CGPointMake(200,160),CGPointMake(820,960),kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
        CGGradientRelease(gradient);
        CGContextSetRGBStrokeColor(c,1,1,1,0.15);
        CGContextSetLineWidth(c,3); CGContextAddPath(c,tile); CGContextStrokePath(c);
        CGPathRelease(tile);
        CGColorRef shadow = CGColorCreateGenericRGB(0.01,0.08,0.12,0.4);
        CGContextSetShadowWithColor(c,CGSizeMake(0,-18),28,shadow);
        CGPathRef pad = CGPathCreateWithRoundedRect(CGRectMake(229,282,566,405),67,67,NULL);
        CGContextSetRGBFillColor(c,0.94,0.99,1,1);
        CGContextAddPath(c,pad); CGContextFillPath(c);
        CGContextSetShadowWithColor(c,CGSizeZero,0,NULL);
        CGContextSetRGBStrokeColor(c,0.20,0.50,0.54,0.45);
        CGContextSetLineWidth(c,6);
        CGContextMoveToPoint(c,234,389); CGContextAddLineToPoint(c,790,389); CGContextStrokePath(c);
        CGPathRelease(pad); CGColorRelease(shadow);
        // White diamond sparkle, lifted above the upper right edge.
        CGContextSetRGBFillColor(c,1,1,1,1);
        CGContextMoveToPoint(c,755,819);
        CGContextAddCurveToPoint(c,769,748,780,737,844,723);
        CGContextAddCurveToPoint(c,780,709,769,698,755,627);
        CGContextAddCurveToPoint(c,741,698,730,709,666,723);
        CGContextAddCurveToPoint(c,730,737,741,748,755,819);
        CGContextFillPath(c);
        CGImageRef image = CGBitmapContextCreateImage(c);
        NSURL *url = [NSURL fileURLWithPath:@(argv[1])];
        CGImageDestinationRef dest = CGImageDestinationCreateWithURL((__bridge CFURLRef)url, CFSTR("public.png"),1,NULL);
        CGImageDestinationAddImage(dest,image,NULL);
        BOOL success = CGImageDestinationFinalize(dest);
        CFRelease(dest); CGImageRelease(image); CGContextRelease(c); CGColorSpaceRelease(space);
        return success ? 0 : 1;
    }
}
