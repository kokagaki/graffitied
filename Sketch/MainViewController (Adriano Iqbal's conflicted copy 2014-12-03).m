//
//  MainViewController.m
//  Sketch
//
//  Created by Charles Ramsey Fahs on 12/2/14.
//  Copyright (c) 2014 KRA Productions. All rights reserved.
//
short
#import "MainViewController.h"
#import <Firebase/Firebase.h>

@interface MainViewController ()

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void) adduser {
    
    //TODO get username, password, email, phone number
    
    //check if username exists
    
    Firebase *usernamechk = [[Firebase alloc] initWithUrl:@"https://groupsketch.firebaseio.com/users"];
    [[[usernamechk queryOrderedByKey] queryEqualToValue:@"rfahs"]
     observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
         NSLog(@"%@", snapshot.key);
     }];
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
/*
- (IBAction)LogInClicked:(id)sender {
    //I'm gonna need if statements
    [self performSegueWithIdentifier:@"logInToMain"sender:self];
}
 */
/*
- (IBAction)RegisterClicked:(id)sender {
    [self performSegueWithIdentifier:@"logInToRegister"sender:self];
}
 */

- (IBAction)BackgroundTap:(id)sender {
    [self.view endEditing:YES];

}

-(BOOL) textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end
