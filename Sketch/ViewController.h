//
//  ViewController.h
//  Sketch
//
//  Created by Charles Ramsey Fahs on 12/1/14.
//  Copyright (c) 2014 KRA Productions. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SketchViewController.h"

@interface ViewController : UIViewController

- (IBAction)wallClicked:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *wallName;
- (IBAction)TapDown:(id)sender;

 
@end
