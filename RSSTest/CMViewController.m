#import "CMViewController.h"
#import "CMRssRecord.h"
#import "CMWebViewController.h"

@interface CMViewController ()

@property (retain, atomic) CMDataDownloader *dataDownloader;
@property (retain, atomic) CMDataParser     *dataParser;
@property (retain, atomic) NSMutableArray   *rssRecords;
@property (readonly, nonatomic) BOOL        showRefresh;

@end

@implementation CMViewController

@synthesize dataDownloader = _dataDownloader, dataParser = _dataParser;

static NSString* cCacheFilename = @"rsscache.plist";
static NSString *cRefreshCellId = @"refreshCell";
static NSString *cRecordCellId = @"recordCell";

#pragma mark -

- (BOOL) showRefresh
{
    return !(self.dataDownloader || self.dataParser);
}

- (void) refreshTable
{
    dispatch_async(dispatch_get_main_queue(), ^(void)
                  {                   
                      [self.tableView reloadData];
                  });
}

- (int) getRssIndexForCell:(int) cellIndex
{
    return self.showRefresh ? cellIndex - 1 : cellIndex;
}

- (void) setRssRecords:(NSMutableArray *)rssRecords
{
    @synchronized(_rssRecords)
    {
        [_rssRecords release];
        _rssRecords = [rssRecords retain];
    }
}

- (NSMutableArray *) rssRecords
{
    @synchronized(_rssRecords)
    {
        return _rssRecords;
    }
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
    if (self.rssRecords)
    {
        NSLog(@"Records read from cache: %d", [self.rssRecords count]);
        [self refreshTable];
    }
    else
    {
        self.rssRecords = [NSMutableArray array];
    }
    [self downloadData];
}

- (void) downloadData
{
    if (!_dataDownloader)
    {
        NSLog(@"Downloading records");
        dispatch_async(_backgroundQueue, ^(void)
        {
            _dataDownloader = [[CMDataDownloader alloc] init];
            _dataDownloader.delegate = self;
            [_dataDownloader downloadData];
        });
    }
    else
    {
        NSLog(@"Download is in progress, ignoring call");
    } 
}

- (void) addRecords:(NSArray *) records
{
    @synchronized (_rssRecords)
    {
        for (CMRssRecord *record in records)
        {
            BOOL shouldAdd = YES;
            for (int i = 0; i < [_rssRecords count]; i++)
            {
                CMRssRecord *storedRecord = [_rssRecords objectAtIndex:i];
                if ([record.date isEqualToDate:storedRecord.date] &&
                    [record.url isEqualToString:storedRecord.url])
                {
                    shouldAdd = NO;
                    break;
                }
                
                if ([record.date compare:storedRecord.date] == NSOrderedDescending)
                {
                    shouldAdd = NO;
                    [_rssRecords insertObject:record atIndex:i];
                    break;
                }
            }
            
            if (shouldAdd)
                [_rssRecords addObject:record];
        }
    }
}

- (void) recordsParsed:(NSArray *) rssRecords
{
    [self addRecords:rssRecords];
    [self refreshTable];
}

- (void) finishedParsing
{
    self.dataParser = nil;
    [self refreshTable];
    [self writeToStorage:self.rssRecords];
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
    self.dataDownloader = nil;
    [self parseData:data];
}

#pragma mark UITableViewDataSource delegate methods

- (UITableViewHeaderFooterView *) getRefreshHeaderCell
{
    UITableViewHeaderFooterView *cell = [_tableView dequeueReusableHeaderFooterViewWithIdentifier:cRefreshCellId];
    if (!cell)
    {
        cell = [[UITableViewHeaderFooterView alloc] initWithReuseIdentifier:cRefreshCellId];
        cell.contentView.backgroundColor = [UIColor greenColor];
        cell.textLabel.textColor = [UIColor grayColor];
        cell.textLabel.textAlignment = UITextAlignmentCenter;
        cell.textLabel.text = @"Обновить";
        [cell autorelease];
    }
    return cell;
}

- (UITableViewCell *) getRefreshCell
{    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cRefreshCellId];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cRefreshCellId];
        cell.contentView.backgroundColor = [UIColor greenColor];
        cell.textLabel.textColor = [UIColor grayColor];
        cell.textLabel.textAlignment = UITextAlignmentCenter;
        cell.textLabel.text = @"Обновить";
        [cell autorelease];
    }
    return cell;
}

- (UITableViewCell *) getRssCellForRecord:(CMRssRecord *) record
{    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cRecordCellId];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cRecordCellId];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:14.0];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        [cell autorelease];
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
        int index = [self getRssIndexForCell:indexPath.row];
        return [self getRssCellForRecord:[self.rssRecords objectAtIndex:index]];
    }
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.showRefresh ? [self.rssRecords count] + 1 : [self.rssRecords count];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellId = [[table cellForRowAtIndexPath:indexPath] reuseIdentifier];
    if ([cellId isEqualToString:cRefreshCellId])
    {
        [self downloadData];
    }
    else
    {        
        int index = [self getRssIndexForCell:indexPath.row];
        CMWebViewController *vc = [[CMWebViewController alloc] init];
        CMRssRecord *rec = [self.rssRecords objectAtIndex:index];
        vc.url = rec.url;
        [self.navigationController pushViewController:vc animated:YES];
        [vc release];
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
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
        _backgroundQueue = dispatch_queue_create("rsstest.background.queue", NULL);
    }
    
    return self;
}

- (void) viewWillAppear:(BOOL) animated
{
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    dispatch_async(_backgroundQueue, ^(void)
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
    dispatch_release(_backgroundQueue);
    [super dealloc];
}

@end
