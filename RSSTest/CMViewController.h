#import <UIKit/UIKit.h>
#import "CMDataDownloader.h"
#import "CMDataParser.h"

@interface CMViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, DataDownloaderDelegate, DataParserDelegate>
{
    CMDataDownloader    *_dataDownloader;
    CMDataParser        *_dataParser;
    NSMutableArray      *_rssRecords;
    NSString            *_cacheFilePath;
    NSDateFormatter     *_dateFormatter;
    dispatch_queue_t    _backgroundQueue;
}

@property (assign, nonatomic) IBOutlet UITableView* tableView;

@end
