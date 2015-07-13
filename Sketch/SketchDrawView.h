//
//  SketchDrawView.h
//  Sketch
//
//  Created by Kenny Okagaki on 11/24/14.
//  Copyright (c) 2014 KRA Productions. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SketchPath.h"

@class SketchDrawView;

@protocol SketchDrawViewDelegate <NSObject>

// called when a user finished drawing a line/path
- (void)drawView:(SketchDrawView *)view didFinishDrawingPath:(SketchPath *)path;

@end

@interface SketchDrawView : UIView

// the color that is used to draw lines
@property (nonatomic, strong) UIColor *drawColor;

// the delegate that is notified about any drawing by the user
@property (nonatomic, weak) id<SketchDrawViewDelegate> delegate;

// adds a path to display to this view
- (void)addPath:(SketchPath *)path;

@end
