#import "ViewController.h"
#import "View3D.h"
#import "ViewChoiceModel.h"
#import "AppDelegate.h"

@implementation ViewController

- (void)touch:(id)sender {
  UIButton *bt = (UIButton*)sender;  
  // Send file to View3D
  if (bt.tag == 0)
    [view3D setPliage: @"cocotte"];
  if (bt.tag == 1)
    [view3D setPliage: @"boat"];
  if (bt.tag == 2)
    [view3D setPliage: @"duck"];
  if (bt.tag == 3)
    [view3D setPliage: @"austria"];
  if (bt.tag == 4)
    [view3D setPliage: @"butterfly"];
  
  if (bt.tag == 5)
    [view3D setPliage: @"notexture"];
  if (bt.tag == 6)
    [view3D setPliage: @"texture"];
  
  // Collapse
  [((ViewChoiceModel*)bt.nextResponder) open_or_collapse];
}

// This Controller creates View3D and ControlView
- (void)viewDidLoad {
  // View3D => 3D view full screen
  CGRect bounds = [[UIScreen mainScreen] bounds];
  view3D = [[View3D alloc] initWithFrame:bounds];
  [self.view addSubview:view3D];
  
  // ViewChoiceModel => Bottom view to choose model
	viewChoiceModel = [[ViewChoiceModel alloc] initWithFrame:CGRectMake(0.0f, self.view.frame.size.height-[ViewChoiceModel barHeight], self.view.frame.size.width, 174.0f)]; // 30+72+72
  NSArray *thumbs = [NSArray arrayWithObjects:
                     @"cocotte72x72.png",
                     @"boat72x72.png",
                     @"duck72x72.png",
                     @"austria72x72.png",
                     @"butterfly72x72.png",
                     @"blueyellow72x72.png",
                     @"gally72x72.png",
                     nil];
  int nthumbs = [thumbs count];
  
  // Create buttons and add them to ViewChoiceModel
	for (NSInteger i = 0; i < nthumbs; i++) {
    UIImage *img = [UIImage imageNamed:[thumbs objectAtIndex:i]];
    CGRect rect = CGRectMake(img.size.width * (i%4), [ViewChoiceModel barHeight] + img.size.height*(i/4),
                             img.size.width, img.size.height);
    UIButton *button = [[UIButton alloc] initWithFrame:rect];
    [button  setBackgroundImage:img forState:UIControlStateNormal];
    [button addTarget:self action:@selector(touch:) forControlEvents:UIControlEventTouchUpInside];
    [button setTag:i];
    [viewChoiceModel addSubview:button];
  }
  // Add viewChoiceModel to top view
  [self.view addSubview:viewChoiceModel];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
}

- (void)dealloc {
	[viewChoiceModel dealloc];
	[view3D dealloc];
  [super dealloc];
}

@end
