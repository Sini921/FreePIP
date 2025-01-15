#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "Tweak.h"

#define UIViewParentController(__view) ({ \
    UIResponder *__responder = __view; \
    while ([__responder isKindOfClass:[UIView class]]) \
    __responder = [__responder nextResponder]; \
    (UIViewController *)__responder; \
})

static BOOL locked = NO;

static UIView *getContentView(SBPIPContainerViewController *self) {
    if ([self respondsToSelector:@selector(pictureInPictureViewController)])
        return self.pictureInPictureViewController.view;
    return self.contentViewController.view;
}

%hook SBPIPContainerViewController
-(void)loadView {
    %orig;

    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
    [getContentView(self) addGestureRecognizer:longPressGesture];
    [self setupBorder];
}

-(void)setContentViewPadding:(UIEdgeInsets)arg1 {
    if(!locked) arg1 = UIEdgeInsetsZero;
    %orig(arg1);
}

%new
-(void)handleLongPressGesture: (UILongPressGestureRecognizer *)sender {
    if (sender.state != UIGestureRecognizerStateBegan) return;
    locked = !locked;
    [self setupBorder];
}

%new
-(void)setupBorder {
    UIView *view = getContentView(self);
    view.layer.borderWidth = 2.0;
    view.layer.cornerRadius = 13.0;
    view.layer.masksToBounds = YES;
    view.layer.borderColor = locked ? [UIColor blueColor].CGColor : [UIColor grayColor].CGColor;
}

static UIView *getTargetView(SBPIPInteractionController *self, UIGestureRecognizer *sender) {
    if ([self respondsToSelector:@selector(targetView)])
        return [self targetView];
    return UIViewParentController(sender.view).view;
}
%end

%hook SBPIPInteractionController
-(void)handlePanGesture: (UIPanGestureRecognizer *)sender {
    if(locked) %orig;
    else if(sender.state == UIGestureRecognizerStateChanged) {
        UIView *view = getTargetView(self, sender);
        CGPoint translation = [sender translationInView:view];
        view.transform = CGAffineTransformTranslate(view.transform, translation.x, translation.y);
        [sender setTranslation:CGPointZero inView:view];
    }
}

-(void)handlePinchGesture:(UIPinchGestureRecognizer *)sender {
    if(locked) %orig;
    else if(sender.state == UIGestureRecognizerStateChanged) {
        UIView *view = getTargetView(self, sender);
        view.transform = CGAffineTransformScale(view.transform, sender.scale, sender.scale);
        sender.scale = 1.0;
    }
}

-(void)handleRotationGesture:(UIRotationGestureRecognizer *)sender {
    if(locked) %orig;
}
%end

%ctor {
    %init;
}