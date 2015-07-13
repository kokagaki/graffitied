//
//  SketchColorPickController.h
//  Sketch
//
//  Created by Kenny Okagaki on 11/24/14.
//  Copyright (c) 2014 KRA Productions. All rights reserved.
//

#import <UIKit/UIkit.h>

@class SketchColorPickController;

@protocol SketchColorPickerDelegate <NSObject>

- (void)colorPicker:(SketchColorPickController *)colorPicker didPickColor:(UIColor *)color;

@end

@interface SketchColorPickController : UIViewController

@property (nonatomic, weak) id<SketchColorPickerDelegate> delegate;

- (id)initWithColor:(UIColor *)color;

@end

