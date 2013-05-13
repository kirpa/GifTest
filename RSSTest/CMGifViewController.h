#import <UIKit/UIKit.h>

@interface CMGifViewController : UIViewController <UIWebViewDelegate>

@property (retain, nonatomic) IBOutlet UIProgressView   *progressView;
@property (retain, nonatomic) IBOutlet UIWebView        *webView;

- (void) showGIFfromData:(NSData *) gifData;

@end
