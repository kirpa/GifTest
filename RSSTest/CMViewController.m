#import "CMViewController.h"
#import "CMRssRecord.h"

@interface CMViewController ()

@property (retain, atomic) CMDataDownloader *dataDownloader;
@property (retain, atomic) CMDataParser     *dataParser;
@property (retain, atomic) NSMutableArray   *rssRecords;
@property (readonly, nonatomic) BOOL        showRefresh;

@end

@implementation CMViewController

@synthesize dataDownloader = _dataDownloader, rssRecords = _rssRecords, dataParser = _dataParser;

static NSString* cCacheFilename = @"rsscache.plist";

#pragma mark -

- (BOOL) showRefresh
{
    return !(self.dataDownloader || self.dataParser);
}

- (void) refreshTable
{
    dispatch_sync(dispatch_get_main_queue(), ^(void)
                  {
                      [self.tableView reloadData];
                  });
}

#pragma mark Data routines

- (void) writeToStorage:(NSArray *) array
{
    BOOL success = [NSKeyedArchiver archiveRootObject:array toFile:_cacheFilePath];
    if (!success)
        NSLog(@"Error writing RSS to storage");
}

- (NSMutableArray *) readFromStorage
{
    NSMutableArray *array = [[NSKeyedUnarchiver unarchiveObjectWithFile:_cacheFilePath] mutableCopy];
    if (!array)
    {
            NSLog(@"Error reading RSS from storage");
    }
    return [array autorelease];
}

- (void) readRecords
{
    // should not be called from the main thread
    self.rssRecords = [self readFromStorage];
    if (_rssRecords)
    {
        NSLog(@"Records read from cache: %d", [_rssRecords count]);
        [self refreshTable];
    }
    else
    {
        self.rssRecords = [NSMutableArray array];
    }
    NSLog(@"Downloading records");
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) , ^(void)
    {
        [self downloadData];
    });
}

- (void) downloadData
{
    // should not be called from the main thread
    if (!_dataDownloader)
    {
        _dataDownloader = [[CMDataDownloader alloc] init];
        _dataDownloader.delegate = self;
        [_dataDownloader downloadData];
    }
    else
    {
        NSLog(@"Download is in progress, ignoring call");
    } 
}

- (void) sortAndFilter
{
    static NSComparator dateSorting = ^(CMRssRecord *rec1, CMRssRecord *rec2)
    {
        return [rec2.date compare:rec1.date];
    };
    [_rssRecords sortUsingComparator:dateSorting];
    NSMutableIndexSet *duplicates = nil;
    for (int i = 0; i < [_rssRecords count] - 1; i++)
    {
        CMRssRecord *current = [_rssRecords objectAtIndex:i];
        CMRssRecord *next = [_rssRecords objectAtIndex:i + 1];
        if ([current.date isEqualToDate:next.date] &&
            [current.url isEqualToString:next.url])
        {
            if (!duplicates)
                duplicates = [NSMutableIndexSet indexSet];
            [duplicates addIndex:i];
        }
    }
    if (duplicates)
        [_rssRecords removeObjectsAtIndexes:duplicates];
}

- (void) recordParsed:(CMRssRecord *)rssRecord
{
    [_rssRecords addObject:rssRecord];
    [self sortAndFilter];
    [self refreshTable];
}

- (void) finishedParsing
{
    self.dataParser = nil;
    // TODO: should make tableView to show Refresh button now. Actually, it doesn't
    [self refreshTable];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) , ^(void)
                   {
                       [self writeToStorage:_rssRecords];
                   });
}

- (void) parseData:(NSData *) data
{
    // should not be called from the main thread
    _dataParser = [[CMDataParser alloc] init];
    _dataParser.delegate = self;
    [_dataParser parseData:data];
}

- (void) dataDownloaded:(NSData *)data
{
    NSLog(@"Download finished");
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) , ^(void)
                   {
                       [self parseData:data];
                       self.dataDownloader = nil;
                   });
}

#pragma mark UITableViewDataSource delegate methods

- (UITableViewCell *) getRefreshCell
{
    static NSString *cRefreshCellId = @"refreshCell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cRefreshCellId];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cRefreshCellId];
        cell.contentView.backgroundColor = [UIColor greenColor];
        cell.textLabel.textColor = [UIColor grayColor];
        cell.textLabel.textAlignment = UITextAlignmentCenter;
        cell.textLabel.text = @"Обновить";
    }
    return cell;
}

- (UITableViewCell *) getRSSCellForRecord:(CMRssRecord *) record
{
    static NSString *cRecordCellId = @"recordCell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cRecordCellId];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cRecordCellId];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:14.0];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    cell.textLabel.text = record.title;
    cell.detailTextLabel.text = [_dateFormatter stringFromDate:record.date];
    return cell;
}

- (UITableViewCell *) tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0 && self.showRefresh)
        return [self getRefreshCell];
    else
    {
        int index = self.showRefresh ? indexPath.row - 1: indexPath.row;
        return [self getRSSCellForRecord:[_rssRecords objectAtIndex:index]];
    }
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.showRefresh ? [_rssRecords count] + 1 : [_rssRecords count];
}


#pragma mark Object lifecycle

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])
    {
        NSArray *libraryPath = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
        _cacheFilePath = [[NSString stringWithFormat:@"%@/%@", [libraryPath objectAtIndex:0], cCacheFilename] retain];
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateStyle = NSDateFormatterLongStyle;
        _dateFormatter.timeStyle = NSDateFormatterShortStyle;
        _dateFormatter.locale = [[[NSLocale alloc] initWithLocaleIdentifier:@"RU"] autorelease];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) , ^(void)
                   {
                       [self readRecords];
                   });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) dealloc
{
    self.dataDownloader = nil;
    self.dataParser = nil;
    self.rssRecords = nil;
    [_cacheFilePath release];
    [_dateFormatter release];
    [super dealloc];
}

@end
