#import <UIKit/UIKit.h>
#import "View3D.h"
#import "ViewChoiceModel.h"

@interface AppDelegate : NSObject <UIApplicationDelegate>
{
  // Only a Top Window and a ViewController
  UIWindow *window;
  UIViewController *viewController;
}

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) UIViewController *viewController;

@end
