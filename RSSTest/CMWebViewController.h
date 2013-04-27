#import <UIKit/UIKit.h>

@interface CMWebViewController : UIViewController

@property (assign, nonatomic) IBOutlet UIWebView *webView;
@property (retain, nonatomic) NSString *url;

@end
