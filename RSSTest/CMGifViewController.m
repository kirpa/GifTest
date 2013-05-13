#import "CMGifViewController.h"

@interface CMGifViewController ()

@end

@implementation CMGifViewController

static NSString *cGifType = @"image/gif";

#pragma mark Other methods

- (void) showGIFfromData:(NSData *) gifData
{
    if (!self.view)
        // nothing. Just touching the view to create it
        ;
    self.progressView.hidden = YES;
    [self.webView loadData:gifData MIMEType:cGifType textEncodingName:nil baseURL:nil];
}

#pragma mark UIViewController methods

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) viewWillAppear:(BOOL) animated
{
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
