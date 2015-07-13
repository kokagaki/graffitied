//
//  SketchViewController.m
//  Sketch
//
//  Created by Kenny Okagaki on 11/24/14.
//  Copyright (c) 2014 KRA Productions. All rights reserved.
//


#import "SketchViewController.h"
#import <UIKit/UIKit.h>
#import "SketchDrawView.h"
#import "SketchColorPickController.h"
#import <Firebase/Firebase.h>

// Declares firebase URL
static NSString * const kFirebaseURL = @"https://groupsketch.firebaseio.com/";

@interface SketchViewController()

// The firebase this program uses
@property (nonatomic, strong) Firebase *firebase;

// The current state of the paths drawn
@property (nonatomic, strong) NSMutableArray *paths;

// A view the user can draw on
@property (nonatomic, strong) SketchDrawView *drawView;

// A button to choose to erase whiteboard
@property (nonatomic, strong) UIButton *eraseButton;

// A button to choose to erase whiteboard
@property (nonatomic, strong) UIButton *backButton;

// A button to choose a undo stroke
@property (nonatomic, strong) UIButton *reloadButton;

// A button to choose a new color
@property (nonatomic, strong) UIButton *colorButton;

// A set of paths by this user that have not been acknowlegded by the server yet
@property (nonatomic, strong) NSMutableSet *outstandingPaths;

// The handle that was returned for observing child events
@property (nonatomic) FirebaseHandle childAddedHandle;

@end

@implementation SketchViewController


- (id)initWithCoder:(NSCoder *)aDecoder
{
    
    self = [super init];
    // Retrieve the user's input from NSUserDefaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults synchronize];
    NSString *wall = [defaults objectForKey:@"wallURL"];
    if (self != nil) {
        
        // initialize the firebase that is used for this sample, appending the user's input to the URL to create/edit their board.
        self.firebase = [[[[Firebase alloc] initWithUrl:kFirebaseURL] childByAppendingPath:@"boards"] childByAppendingPath: wall];
        
        // setup the state variables
        self.paths = [NSMutableArray array];
        self.outstandingPaths = [NSMutableSet set];
        
        // get a weak reference so we don't cause any retain cycles in tha callback block
        __weak SketchViewController *weakSelf = self;
        
        // New drawings will appear as child added events
        self.childAddedHandle = [self.firebase observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
            if ([weakSelf.outstandingPaths containsObject:snapshot.key]) {
                // this was drawn by this device and already taken care of by our draw view, ignore
            } else {
                // parse the path into our internal format
                SketchPath *path = [SketchPath parse:snapshot.value];
                if (path != nil) {
                    // the parse was successful, add it to our view
                    if (weakSelf.drawView != nil) {
                        [weakSelf.drawView addPath:path];
                    }
                    // keep track of the paths so far
                    [weakSelf.paths addObject:path];
                } else {
                    // there was an error parsing the snapshot, log an error
                    NSLog(@"Not a valid path: %@ -> %@", snapshot.key, snapshot.value);
                }
            }
        }];
    }
    return self;
}

- (void)dealloc
{
    // make sure there are no outstanding observers
    [self.firebase removeObserverWithHandle:self.childAddedHandle];
}

- (void)colorButtonPressed
{
    // the user decided to choose a new color, present the color picker view controller modally
    SketchColorPickController *cpc = [[SketchColorPickController alloc] initWithColor:self.drawView.drawColor];
    
    // set the color picker delegate to self
    cpc.delegate = self;
    
    // wrap the color picker view controller into a navigation view controller for over 9000 beauty
    UINavigationController *vc = [[UINavigationController alloc] initWithRootViewController:cpc];
    vc.modalPresentationStyle = UIModalPresentationFormSheet;
    
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)colorPicker:(SketchColorPickController *)colorPicker didPickColor:(UIColor *)color
{
    // the user chose a new color, update the drawing view
    self.drawView.drawColor = color;
}

- (void)drawView:(SketchDrawView *)view didFinishDrawingPath:(SketchPath *)path
{
    // the user finished drawing a path
    Firebase *pathRef = [self.firebase childByAutoId];
    
    // get the name of this path which serves as a global id
    NSString *name = pathRef.key;
    
    // remember that this path was drawn by this user so it's not drawn twice
    [self.outstandingPaths addObject:name];
    
    // save the path to Firebase
    [pathRef setValue:[path serialize] withCompletionBlock:^(NSError *error, Firebase *ref) {
        // The path was successfully saved and can now be removed from the outstanding paths
        [self.outstandingPaths removeObject:name];
    }];
}

- (void)loadView
{
    // load and setup views
    
    // this is the main view and used to show drawing from other users and let the user draw
    self.drawView = [[SketchDrawView alloc] initWithFrame:CGRectMake(0, 0, 320, 400)];
    
    // make sure it's resizable to fit any device size
    self.drawView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    // add any paths that were already received from Firebase
    for (SketchPath *path in self.paths) {
        [self.drawView addPath:path];
    }
    
    // make sure the user can draw on this view
    self.drawView.userInteractionEnabled = YES;
    
    // set the delegate of this view to self
    self.drawView.delegate = self;
    
    // create the back button
    self.backButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    
    // make button over 9000 beauty
    self.backButton.layer.cornerRadius = 10;
    self.backButton.layer.backgroundColor = [UIColor colorWithWhite:1 alpha:0.9].CGColor;
    self.backButton.layer.borderColor = self.backButton.tintColor.CGColor;
    self.backButton.layer.borderWidth = 2;
    [self.backButton.titleLabel setFont:[UIFont fontWithName:@"Futura-Medium" size:13.0]];
    [self.backButton setTitle:@"BACK" forState:UIControlStateNormal];
    
    // make sure clicks on the button call our method
    [self.backButton addTarget:self
                         action:@selector(backButtonPressed)
               forControlEvents:UIControlEventTouchUpInside];
    
    // ensure the button has the right size and position
    CGSize viewSize = self.drawView.frame.size;
    CGSize backButtonSize = CGSizeMake(60, 25);
    self.backButton.frame = CGRectMake(0.0,
                                        -150,
                                        backButtonSize.width,
                                        backButtonSize.height);
    self.backButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    
    // add the back button to the draw view
    [self.drawView addSubview:self.backButton];
    
    // create the color button
    self.colorButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    
    // make button over 9000 beauty
    self.colorButton.layer.cornerRadius = 10;
    self.colorButton.layer.backgroundColor = [UIColor colorWithWhite:1 alpha:0.9].CGColor;
    self.colorButton.layer.borderColor = self.colorButton.tintColor.CGColor;
    self.colorButton.layer.borderWidth = 1;
    [self.colorButton.titleLabel setFont:[UIFont fontWithName:@"Futura-Medium" size:15.0]];
    [self.colorButton setTitle:@"COLOR" forState:UIControlStateNormal];
    
    // make sure clicks on the button call our method
    [self.colorButton addTarget:self
                         action:@selector(colorButtonPressed)
               forControlEvents:UIControlEventTouchUpInside];
    
    // ensure the button has the right size and position
    CGSize buttonSize = CGSizeMake(100, 40);
    self.colorButton.frame = CGRectMake(viewSize.width - buttonSize.width - 5,
                                        viewSize.height - buttonSize.height - 20,
                                        buttonSize.width,
                                        buttonSize.height);
    self.colorButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    
    // add the color button to the draw view
    [self.drawView addSubview:self.colorButton];
    
    // create the erase button
    self.eraseButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    
    // make erase button over 9000 beauty
    self.eraseButton.layer.cornerRadius = 10;
    self.eraseButton.layer.backgroundColor = [UIColor colorWithWhite:1 alpha:0.9].CGColor;
    self.eraseButton.layer.borderColor = self.eraseButton.tintColor.CGColor;
    self.eraseButton.layer.borderWidth = 1;
    [self.eraseButton.titleLabel setFont:[UIFont fontWithName:@"Futura-Medium" size:15.0]];
    [self.eraseButton setTitle:@"ERASE ALL" forState:UIControlStateNormal];
    
    
    // make sure clicks on the button call our methods
    [self.eraseButton addTarget:self action:@selector(touchDownRepeat:) forControlEvents:UIControlEventTouchDownRepeat];
    
    
    // ensure the erase button has the right size and position
    self.eraseButton.frame = CGRectMake(viewSize.width - buttonSize.width - 110,
                                        viewSize.height - buttonSize.height - 20,
                                        buttonSize.width,
                                        buttonSize.height);
    self.eraseButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    
    // add the erase button to the draw view
    [self.drawView addSubview:self.eraseButton];
    
    // create the undo button
    self.reloadButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    
    // make erase button over 9000 beauty
    self.reloadButton.layer.cornerRadius = 10;
    self.reloadButton.layer.backgroundColor = [UIColor colorWithWhite:1 alpha:0.9].CGColor;
    self.reloadButton.layer.borderColor = self.eraseButton.tintColor.CGColor;
    self.reloadButton.layer.borderWidth = 1;
    [self.reloadButton.titleLabel setFont:[UIFont fontWithName:@"Futura-Medium" size:15.0]];
    [self.reloadButton setTitle:@"RELOAD" forState:UIControlStateNormal];
    
    // make sure clicks on the button call our method
    [self.reloadButton addTarget:self
                        action:@selector(reloadButtonPressed:)
              forControlEvents:UIControlEventTouchUpInside];
    
    // ensure the undo button has the right size and position
    self.reloadButton.frame = CGRectMake(viewSize.width - buttonSize.width - 215,
                                       viewSize.height - buttonSize.height - 20,
                                       buttonSize.width,
                                       buttonSize.height);
    self.reloadButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    
    // add the reload button to the draw view
    [self.drawView addSubview:self.reloadButton];
    
    // finally set the view of this view controller to the draw view
    self.view = self.drawView;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    if ([self isViewLoaded] && [self.view window] == nil) {
        self.view = nil;
        self.drawView = nil;
        self.colorButton = nil;
    }
}

//Function that deletes last stroke made
-(void) reloadButtonPressed:(id)sender
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    SketchViewController *drawViewController = [[SketchViewController alloc] initWithCoder:nil];
    self.window.rootViewController = drawViewController;
    [self.window makeKeyAndVisible];
    
}
-(void) backButtonPressed
{
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *viewController = [mainStoryboard   instantiateViewControllerWithIdentifier:@"MainGraf"];
    [self presentViewController:viewController animated:YES completion:nil];
    
}
- (void) touchDownRepeat:(id)sender
{
    
    Firebase *ref = [[Firebase alloc] initWithUrl: kFirebaseURL];
    [ref removeValue];
    
    [self eraseAll];
}

- (void) eraseAll
{
    // load and setup views
    
    // this is the main view and used to show drawing from other users and let the user draw
    self.drawView = [[SketchDrawView alloc] initWithFrame:CGRectMake(0, 0, 320, 400)];
    
    // make sure it's resizable to fit any device size
    self.drawView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    // make sure the user can draw on this view
    self.drawView.userInteractionEnabled = YES;
    
    // set the delegate of this view to self
    self.drawView.delegate = self;
    
    // create the back button
    self.backButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    
    // make button over 9000 beauty
    self.backButton.layer.cornerRadius = 10;
    self.backButton.layer.backgroundColor = [UIColor colorWithWhite:1 alpha:0.9].CGColor;
    self.backButton.layer.borderColor = self.backButton.tintColor.CGColor;
    self.backButton.layer.borderWidth = 2;
    [self.backButton.titleLabel setFont:[UIFont fontWithName:@"Futura-Medium" size:13.0]];
    [self.backButton setTitle:@"BACK" forState:UIControlStateNormal];
    
    // make sure clicks on the button call our method
    [self.backButton addTarget:self
                        action:@selector(backButtonPressed)
              forControlEvents:UIControlEventTouchUpInside];
    
    // ensure the button has the right size and position
    CGSize viewSize = self.drawView.frame.size;
    CGSize backButtonSize = CGSizeMake(60, 25);
    self.backButton.frame = CGRectMake(0.0,
                                       -150,
                                       backButtonSize.width,
                                       backButtonSize.height);
    self.backButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    
    // add the back button to the draw view
    [self.drawView addSubview:self.backButton];
    
    // create the color button
    self.colorButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    
    // make button over 9000 beauty
    self.colorButton.layer.cornerRadius = 10;
    self.colorButton.layer.backgroundColor = [UIColor colorWithWhite:1 alpha:0.9].CGColor;
    self.colorButton.layer.borderColor = self.colorButton.tintColor.CGColor;
    self.colorButton.layer.borderWidth = 1;
    [self.colorButton.titleLabel setFont:[UIFont fontWithName:@"Futura-Medium" size:15.0]];
    [self.colorButton setTitle:@"COLOR" forState:UIControlStateNormal];
    
    // make sure clicks on the button call our method
    [self.colorButton addTarget:self
                         action:@selector(colorButtonPressed)
               forControlEvents:UIControlEventTouchUpInside];
    
    // ensure the button has the right size and position
    CGSize buttonSize = CGSizeMake(100, 40);
    self.colorButton.frame = CGRectMake(viewSize.width - buttonSize.width - 5,
                                        viewSize.height - buttonSize.height - 20,
                                        buttonSize.width,
                                        buttonSize.height);
    self.colorButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    
    // add the color button to the draw view
    [self.drawView addSubview:self.colorButton];
    
    // create the erase button
    self.eraseButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    
    // make erase button over 9000 beauty
    self.eraseButton.layer.cornerRadius = 10;
    self.eraseButton.layer.backgroundColor = [UIColor colorWithWhite:1 alpha:0.9].CGColor;
    self.eraseButton.layer.borderColor = self.eraseButton.tintColor.CGColor;
    self.eraseButton.layer.borderWidth = 1;
    [self.eraseButton.titleLabel setFont:[UIFont fontWithName:@"Futura-Medium" size:15.0]];
    [self.eraseButton setTitle:@"ERASE ALL" forState:UIControlStateNormal];
    
    
    // make sure clicks on the button call our methods
    [self.eraseButton addTarget:self action:@selector(touchDownRepeat:) forControlEvents:UIControlEventTouchDownRepeat];
    
    
    // ensure the erase button has the right size and position
    self.eraseButton.frame = CGRectMake(viewSize.width - buttonSize.width - 110,
                                        viewSize.height - buttonSize.height - 20,
                                        buttonSize.width,
                                        buttonSize.height);
    self.eraseButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    
    
    // add the erase button to the draw view
    [self.drawView addSubview:self.eraseButton];
    
    // create the undo button
    self.reloadButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    
    // make erase button over 9000 beauty
    self.reloadButton.layer.cornerRadius = 10;
    self.reloadButton.layer.backgroundColor = [UIColor colorWithWhite:1 alpha:0.9].CGColor;
    self.reloadButton.layer.borderColor = self.eraseButton.tintColor.CGColor;
    self.reloadButton.layer.borderWidth = 1;
    [self.reloadButton.titleLabel setFont:[UIFont fontWithName:@"Futura-Medium" size:15.0]];
    [self.reloadButton setTitle:@"RELOAD" forState:UIControlStateNormal];
    
    // make sure clicks on the button call our method
    [self.reloadButton addTarget:self
                        action:@selector(reloadButtonPressed:)
              forControlEvents:UIControlEventTouchUpInside];
    
    // ensure the undo button has the right size and position
    self.reloadButton.frame = CGRectMake(viewSize.width - buttonSize.width - 215,
                                       viewSize.height - buttonSize.height - 20,
                                       buttonSize.width,
                                       buttonSize.height);
    self.reloadButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    
    // add the undo button to the draw view
    [self.drawView addSubview:self.reloadButton];
    
    // finally set the view of this view controller to the draw view
    self.view = self.drawView;
}

@end

