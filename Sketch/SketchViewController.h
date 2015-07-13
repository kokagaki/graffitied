//
//  SketchViewController.h
//  Sketch
//
//  Created by Kenny Okagaki on 11/24/14.
//  Copyright (c) 2014 KRA Productions. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SketchDrawView.h"
#import "SketchColorPickController.h"


@interface SketchViewController : UIViewController<SketchDrawViewDelegate, SketchColorPickerDelegate>

@property (strong, nonatomic) UIWindow *window;


@end
