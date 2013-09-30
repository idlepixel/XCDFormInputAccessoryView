//
//  XCDFormInputAccessoryView.h
//
//  Created by Cédric Luthi on 2012-11-10
//  Copyright (c) 2012 Cédric Luthi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XCDFormInputAccessoryView : UIView

@property (assign) UIBarStyle barStyle NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR;
@property (assign) BOOL barTranslucent NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR;

- (id) initWithResponders:(NSArray *)responders; // Objects must be UIResponder instances

@property (nonatomic, strong) NSArray *responders;
@property (nonatomic, strong, readonly) UIToolbar *toolbar;

@property (nonatomic, assign) BOOL hasDoneButton; // Defaults to YES on iPhone, NO on iPad

- (void) setHasDoneButton:(BOOL)hasDoneButton animated:(BOOL)animated;

@end
