//
//  ModalNavControl.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/13/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "ModalNavControl.h"
#import "ModalNavRoot.h"

@interface ModalNavControl ()
@property (nonatomic,strong) ModalNavRoot* navRoot;
@end

@implementation ModalNavControl
@synthesize delegate;
@synthesize navController;
@synthesize navRoot;
@synthesize completionBlock;

- (id)init
{
    self = [super initWithNibName:@"ModalNavControl" bundle:nil];
    if(self) 
    {
        self.completionBlock = nil;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navRoot = [[ModalNavRoot alloc] initWithNibName:@"ModalNavRoot" bundle:nil];
    self.navController = [[UINavigationController alloc] initWithRootViewController:[self navRoot]];
    self.navController.delegate = self;
    [self.navController setNavigationBarHidden:YES];
    [self.view addSubview:self.navController.view];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.navRoot = nil;
    self.navController = nil;
    self.completionBlock = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if(viewController == self.navRoot)
    {
        // dismiss myself if stack has been fully popped
        [self.delegate dismissModal];
        
        // call completion block
        if(self.completionBlock)
        {
            self.completionBlock(YES);
            self.completionBlock = nil;
        }
    }
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    // do nothing
}

@end
