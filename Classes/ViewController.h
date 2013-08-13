#import <UIKit/UIKit.h>
#import "View3D.h"

@class ViewChoiceModel;
@class View3D;

@interface ViewController : UIViewController
{
  // Only a View to choose model and a 3D view
	ViewChoiceModel *viewChoiceModel;
  View3D *view3D;
}

@end
