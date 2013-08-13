#import <UIKit/UIKit.h>

@interface ViewChoiceModel : UIView
{
  // A view to choose model with a bar on top and images on bottom
	CGGradientRef barGradient;
	CGPoint barStartPoint, barEndPoint;
	UIImageView *barImageView;
	CGAffineTransform barImageViewRotation;
	
	BOOL isOpen;
	CGFloat contentHeight;
}

@property (readonly) CGFloat contentHeight;
@property (readonly) BOOL open;

+ (CGFloat) barHeight;
- (void) open_or_collapse;

@end
