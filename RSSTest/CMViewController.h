#import <UIKit/UIKit.h>
#import "CMDataDownloader.h"

@interface CMViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, DataDownloaderDelegate>
{
    CMDataDownloader    *_dataDownloader;
    NSArray             *_gifURLs;
    NSMutableArray      *_downloadedGif;
    dispatch_queue_t    _backgroundQueue;
}

@property (assign, nonatomic) IBOutlet UITableView* tableView;

@end
