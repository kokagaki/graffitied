//
//  SketchDrawView.m
//  Sketch
//
//  Created by Kenny Okagaki on 11/24/14.
//  Copyright (c) 2014 KRA Productions. All rights reserved.
//

#import "SketchDrawView.h"
#import "SketchViewController.h"

@interface SketchDrawView ()

// the paths currently displayed by this view
@property (nonatomic, strong) NSMutableArray *paths;

// the current path the user is drawing
@property (nonatomic, strong) SketchPath *currentPath;

// the touch that is used to currently draw this path
@property (nonatomic, strong) UITouch *currentTouch;

@end

@implementation SketchDrawView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil) {
        self.paths = [NSMutableArray array];
        self.backgroundColor = [UIColor whiteColor];
        self.drawColor = [UIColor redColor];
    }
    return self;
}

- (void)addPath:(SketchPath *)path
{
    [self.paths addObject:path];
    // make sure the view is redrawn
    [self setNeedsDisplay];
}

- (void)deletePath:(SketchPath *)path
{
    [self.paths removeObject:path];
    // make sure the view is redrawn
    [self setNeedsDisplay];
}

- (void)drawPath:(SketchPath *)path withContext:(CGContextRef)context
{
    if (path.points.count > 1) {
        // make sure this is a new line
        CGContextBeginPath(context);
        
        // set the color
        CGContextSetStrokeColorWithColor(context, path.color.CGColor);
        
        SketchPoint *point = path.points[0];
        CGContextMoveToPoint(context, point.x, point.y);
        
        // draw all points on the path
        for (NSUInteger i = 0; i < path.points.count; i++) {
            SketchPoint *point = path.points[i];
            CGContextAddLineToPoint(context, point.x, point.y);
        }
        
        // actually draw the path
        CGContextDrawPath(context, kCGPathStroke);
    }
}


- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    
    // draw all lines from Firebase
    for (SketchPath *path in self.paths) {
        CGContextSetLineWidth(context, path.markerSize);
        [self drawPath:path withContext:context];
    }
    
    // make sure to draw the line the user is currently drawing
    if (self.currentPath != nil) {
        [self drawPath:self.currentPath withContext:context];
    }
}

- (void)touchesBegan:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    if (self.currentPath == nil) {
        // the user is currently not drawing a line so start a new one
        
        // remember the touch to not mix up multitouch
        self.currentTouch = [touches anyObject];
        self.currentPath = [[SketchPath alloc] initWithColor:self.drawColor];
        
        // add the current point on the path
        CGPoint touchPoint = [self.currentTouch locationInView:self];
        [self.currentPath addPoint:touchPoint];
        
        [self setNeedsDisplay];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.currentPath != nil) {
        // look if any of the touches that moved is the one currently used to draw a line
        for (UITouch *touch in touches) {
            if (self.currentTouch == touch) {
                // we found the touch so update the line
                CGPoint touchPoint = [self.currentTouch locationInView:self];
                [self.currentPath addPoint:touchPoint];
                [self setNeedsDisplay];
            }
        }
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.currentPath != nil) {
        for (UITouch *touch in touches) {
            if (self.currentTouch == touch) {
                // the touch was cancelled reset drawing state
                self.currentPath = nil;
                self.currentTouch = nil;
                [self setNeedsDisplay];
            }
        }
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.currentPath != nil) {
        for (UITouch *touch in touches) {
            if (self.currentTouch == touch) {
                self.currentPath.markerSize = self.markerSize;
                // the touch finished draw add the line to the current state
                [self.paths addObject:self.currentPath];
                
                // notify the delegate
                [self.delegate drawView:self didFinishDrawingPath:self.currentPath];
                
                // reset drawing state
                self.currentPath = nil;
                self.currentTouch = nil;
            }
        }
    }
}

@end
