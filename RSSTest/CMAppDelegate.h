//
//  CMAppDelegate.h
//  RSSTest
//
//  Created by Vadim on 4/24/13.
//  Copyright (c) 2013 Vadim. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CMViewController;

@interface CMAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) CMViewController *viewController;

@end
