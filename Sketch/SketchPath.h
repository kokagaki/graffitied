//
//  SketchPath.h
//  Sketch
//
//  Created by Kenny Okagaki on 11/24/14.
//  Copyright (c) 2014 KRA Productions. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// a point object that can be stored in arrays
@interface SketchPoint : NSObject

@property (nonatomic, readonly) CGFloat x;
@property (nonatomic, readonly) CGFloat y;

- (id)initWithCGPoint:(CGPoint)point;

@end

// a path consisting of a color and multiple way points
@interface SketchPath : NSObject

// the points of this path
@property (nonatomic, strong, readonly) NSMutableArray *points;

// the color of this path
@property (nonatomic, strong, readonly) UIColor *color;

- (id)initWithColor:(UIColor *)color;
- (id)initWithPoints:(NSArray *)points color:(UIColor *)color;

// parse from a JSON representation
+ (SketchPath *)parse:(NSDictionary *)dictionary;

// serialize to a JSON representation
- (NSDictionary *)serialize;

// add a point to this path
- (void)addPoint:(CGPoint)point;

@end
