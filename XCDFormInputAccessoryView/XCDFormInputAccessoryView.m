//
//  XCDFormInputAccessoryView.m
//
//  Created by Cédric Luthi on 2012-11-10
//  Copyright (c) 2012 Cédric Luthi. All rights reserved.
//

#import "XCDFormInputAccessoryView.h"

static NSString * UIKitLocalizedString(NSString *string)
{
	NSBundle *UIKitBundle = [NSBundle bundleForClass:[UIApplication class]];
	return UIKitBundle ? [UIKitBundle localizedStringForKey:string value:string table:nil] : string;
}

static NSArray * EditableTextInputsInView(UIView *view)
{
	NSMutableArray *textInputs = [NSMutableArray new];
    for (UIView *subview in view.subviews) {
		if (([subview isKindOfClass:[UITextField class]] && [(UITextField *)subview isEnabled]) || ([subview isKindOfClass:[UITextView class]] && [(UITextView *)subview isEditable])) {
    		if (textInputs == nil) textInputs = [NSMutableArray new];
            [textInputs addObject:subview];
		} else if (subview.subviews.count > 0) {
            NSArray *subTextInputs = EditableTextInputsInView(subview);
            if (subTextInputs.count > 0) {
                if (textInputs == nil) textInputs = [NSMutableArray new];
                [textInputs addObjectsFromArray:subTextInputs];
            }
        }
	}
	return textInputs;
}

@interface XCDFormInputAccessoryView ()

@property (nonatomic, strong, readwrite) UIToolbar *toolbar;

@end

@implementation XCDFormInputAccessoryView

- (id) initWithFrame:(CGRect)frame
{
	return [self initWithResponders:nil];
}

- (id) initWithResponders:(NSArray *)responders
{
	if (!(self = [super initWithFrame:CGRectZero]))
		return nil;
	
	self.responders = responders;
	
	UIToolbar *toolbar = [[UIToolbar alloc] init];
	toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:@[ UIKitLocalizedString(@"Previous"), UIKitLocalizedString(@"Next") ]];
	[segmentedControl addTarget:self action:@selector(selectAdjacentResponder:) forControlEvents:UIControlEventValueChanged];
	segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
	segmentedControl.momentary = YES;
	UIBarButtonItem *segmentedControlBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:segmentedControl];
	UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	toolbar.items = @[ segmentedControlBarButtonItem, flexibleSpace ];
    self.toolbar = toolbar;
	[self addSubview:toolbar];
    
    self.barStyle = UIBarStyleDefault;
    self.barTranslucent = YES;
    
	self.hasDoneButton = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone;
    
	self.frame = toolbar.frame = (CGRect){CGPointZero, [toolbar sizeThatFits:CGSizeZero]};
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textInputDidBeginEditing:) name:UITextFieldTextDidBeginEditingNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textInputDidBeginEditing:) name:UITextViewTextDidBeginEditingNotification object:nil];
	
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)setBarStyle:(UIBarStyle)barStyle
{
    self.toolbar.barStyle = barStyle;
}

-(UIBarStyle)barStyle
{
    return self.toolbar.barStyle;
}

-(void)setBarTranslucent:(BOOL)barTranslucent
{
    self.toolbar.translucent = barTranslucent;
}

-(BOOL)barTranslucent
{
    return self.toolbar.translucent;
}

- (void) updateSegmentedControl
{
	NSArray *responders = self.responders;
	if ([responders count] == 0)
		return;
	
	UISegmentedControl *segmentedControl = (UISegmentedControl *)[self.toolbar.items.firstObject customView];
	BOOL isFirst = [responders.firstObject isFirstResponder];
	BOOL isLast = [responders.lastObject isFirstResponder];

	[segmentedControl setEnabled:!isFirst forSegmentAtIndex:0];
	[segmentedControl setEnabled:!isLast forSegmentAtIndex:1];
}

- (void) willMoveToWindow:(UIWindow *)window
{
	if (!window)
		return;
	
	[self updateSegmentedControl];
}

- (void) textInputDidBeginEditing:(NSNotification *)notification
{
	[self updateSegmentedControl];
}

- (NSArray *) responders
{
	if (_responders)
		return _responders;
	
	NSArray *textInputs = EditableTextInputsInView([[UIApplication sharedApplication] keyWindow]);
	return [textInputs sortedArrayUsingComparator:^NSComparisonResult(UIView *textInput1, UIView *textInput2) {
		UIView *commonAncestorView = textInput1.superview;
		while (commonAncestorView && ![textInput2 isDescendantOfView:commonAncestorView])
			commonAncestorView = commonAncestorView.superview;
		
		CGRect frame1 = [textInput1 convertRect:textInput1.bounds toView:commonAncestorView];
		CGRect frame2 = [textInput2 convertRect:textInput2.bounds toView:commonAncestorView];
		return [@(CGRectGetMinY(frame1)) compare:@(CGRectGetMinY(frame2))];
	}];
}

- (void) setHasDoneButton:(BOOL)hasDoneButton
{
	[self setHasDoneButton:hasDoneButton animated:NO];
}

- (void) setHasDoneButton:(BOOL)hasDoneButton animated:(BOOL)animated
{
	if (_hasDoneButton == hasDoneButton)
		return;
	
	[self willChangeValueForKey:@"hasDoneButton"];
	_hasDoneButton = hasDoneButton;
	[self didChangeValueForKey:@"hasDoneButton"];
	
    UIToolbar *toolbar = self.toolbar;
    
	NSArray *items = nil;
	if (hasDoneButton) {
		items = [toolbar.items arrayByAddingObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)]];
	} else {
		items = [toolbar.items subarrayWithRange:NSMakeRange(0, 2)];
    }
	
	[toolbar setItems:items animated:animated];
}

#pragma mark - Actions

- (void) selectAdjacentResponder:(UISegmentedControl *)sender
{
    NSArray *responders = self.responders;
	NSArray *firstResponders = [responders filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(UIResponder *responder, NSDictionary *bindings) {
		return [responder isFirstResponder];
	}]];
    UIResponder *firstResponder = [firstResponders lastObject];
    NSInteger offset = sender.selectedSegmentIndex == 0 ? -1 : +1;
    NSInteger firstResponderIndex = [responders indexOfObject:firstResponder];
    NSInteger adjacentResponderIndex = firstResponderIndex != NSNotFound ? firstResponderIndex + offset : NSNotFound;
    UIResponder *adjacentResponder = nil;
	if (adjacentResponderIndex >= 0 && adjacentResponderIndex < (NSInteger)[responders count]) {
		adjacentResponder = [responders objectAtIndex:adjacentResponderIndex];
    }
    if (adjacentResponder) {
        [adjacentResponder becomeFirstResponder];
    }
}

- (void) done
{
	[[UIApplication sharedApplication] sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];
}

@end
