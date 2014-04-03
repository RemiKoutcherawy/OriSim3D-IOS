#import "ViewChoiceModel.h"

const float gBarHeight = 30.0f;

@implementation ViewChoiceModel

@synthesize contentHeight = contentHeight;
@synthesize open = isOpen;

- (id)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
		isOpen = FALSE;
		contentHeight = frame.size.height - gBarHeight;
		
		// Gradient setup for bar
		const CGFloat barColors[8] = {
			0.30f, 0.30f, 0.30f, 0.75f,
			0.00f, 0.00f, 0.00f, 0.75f
		};
		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
		if (colorSpace != NULL) {
			barGradient = CGGradientCreateWithColorComponents(colorSpace, barColors, NULL, 2);
			CGColorSpaceRelease(colorSpace);
		}
		barStartPoint = CGPointMake(0.0f, 0.0f);
		barEndPoint = CGPointMake(0.0f, gBarHeight);
		
		// Image setup for bar
		UIImage *image=[UIImage imageWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"Triangle" ofType:@"png"]];
		
		barImageView = [[[UIImageView alloc] initWithImage:image] autorelease];
		CGRect imageViewFrame = barImageView.frame;
		imageViewFrame.origin.x = floorf((frame.size.width/2.0f) - (imageViewFrame.size.width/2.0f));
		imageViewFrame.origin.y = floorf((gBarHeight/2.0f) - (imageViewFrame.size.height/2.0f));
		[barImageView setFrame:imageViewFrame];
		
		[self addSubview:barImageView];
		
		barImageViewRotation = CGAffineTransformMake(cos(-M_PI), sin(-M_PI), -sin(-M_PI), cos(-M_PI), 0.0f, 0.0f);
    
		self.opaque = FALSE;
  }
  return self;
}

+ (CGFloat)barHeight {
	return gBarHeight;
}

- (void)drawRect:(CGRect)rect {
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSaveGState(context);
	
	CGContextDrawLinearGradient(context, barGradient, barStartPoint, barEndPoint, kCGGradientDrawsAfterEndLocation);
	
	CGContextSetRGBFillColor(context, 0.25f, 0.25f, 0.25f, 1.0f);
	UIRectFill(CGRectMake(0.0f, 0.0f, self.frame.size.width, 1.0f));
	
	CGContextRestoreGState(context);
}

- (void)dealloc {
	CGGradientRelease(barGradient);
  [super dealloc];
}

- (void)open_or_collapse {
  [UIView beginAnimations:nil context:NULL];
  [UIView setAnimationDuration:0.25f];
  
  CGRect frame = [self frame];
  
  if (isOpen == FALSE) {
    frame.origin.y -= contentHeight;
    [barImageView setTransform:barImageViewRotation];
    isOpen = YES;
  }
  else {
    frame.origin.y += contentHeight;
    [barImageView setTransform:CGAffineTransformIdentity];
    isOpen = NO;
  }
  [self setFrame:frame];
  [UIView commitAnimations];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  UITouch *touch;
	CGPoint point;
  // From the top of ControlView
  if ([touches count] > 0) {
    touch = [[touches allObjects] objectAtIndex:0];
		point = [touch locationInView:self];
		if (point.y <= gBarHeight) {
			[self open_or_collapse];
		}
	}
}

@end
