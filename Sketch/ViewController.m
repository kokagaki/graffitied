//
//  ViewController.m
//  Sketch
//
//  Created by Charles Ramsey Fahs on 12/1/14.
//  Copyright (c) 2014 KRA Productions. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //self.view.backgroundColor = [UIColor colorWithRed:0.808 green:0.561 blue:0.996 alpha:1];
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"purplegraff2.jpg"]];
    

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (IBAction)wallClicked:(id)sender {
    
    // Establish a character set of only alphanumeric characters and the underscore
    NSCharacterSet *s = [NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890_"];
    s = [s invertedSet];
    NSString *upperWall = _wallName.text;
    // Make the input all lowercase so that it's not case sensitive
    NSString *wall = [upperWall lowercaseString];
    NSLog(@"%@", wall);
    NSRange r = [wall rangeOfCharacterFromSet:s];
    // Scrubs the inputs
    if (r.location != NSNotFound || [wall length] == 0) {
        UIAlertView *alertView =
        [[UIAlertView alloc]initWithTitle: @"Error!" message:@"You must input alphanumeric text!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alertView show];
    }
    
    else
    {
    // Sets a global variable for the user input so that the sketch view controller can access it.
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults synchronize];
    [defaults setObject:wall forKey:@"wallURL"];
    
    // Presents the sketch view controller
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *viewController = [mainStoryboard   instantiateViewControllerWithIdentifier:@"Sketch"];
    [self presentViewController:viewController animated:YES completion:nil];
        
    }
    

}
- (IBAction)TapDown:(id)sender {
    // Makes it so that if you tap off of the screen when you've seleted the text field the keyboard is dismissed.
    [self.view endEditing:YES];
}
@end
