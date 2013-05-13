#import "CMViewController.h"
#import "CMGifDataRecord.h"
#import "CMGifViewController.h"

@interface CMViewController ()

@property (retain, atomic) CMDataDownloader *dataDownloader;
@property (retain, nonatomic) CMGifViewController *gifVC;

@end

@implementation CMViewController

@synthesize dataDownloader = _dataDownloader;

#pragma mark Downloader delegate methods

- (void) dataDownloaded:(CMGifDataRecord *) gifRecord
{
    dispatch_async(dispatch_get_main_queue(), ^(void)
                   {
                       [self.gifVC showGIFfromData:gifRecord.data];
                   });
}

- (void) progressChanged:(float) progress
{
    if (self.gifVC)
    {
        NSLog(@"Setting progress to: %.1f", progress);
        dispatch_async(dispatch_get_main_queue(), ^(void)
                       {
                           [self.gifVC.progressView setProgress:progress animated:YES];
                       });
    }
    else
        NSLog(@"Downloading while not showing GIF view controller, this should not happen");
}

#pragma mark Data routines

- (void) downloadDataForGif:(CMGifDataRecord *) gifRecord
{
    if (!_dataDownloader)
    {
        dispatch_async(_backgroundQueue, ^(void)
        {
            _dataDownloader = [[CMDataDownloader alloc] init];
            _dataDownloader.delegate = self;
            [_dataDownloader downloadDataForGif:gifRecord];
        });
    }
    else
    {
        NSLog(@"Download is in progress, ignoring call");
    } 
}

#pragma mark UITableViewDataSource delegate methods

- (UITableViewCell *) tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cRecordCellId = @"recordCell";
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cRecordCellId];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cRecordCellId];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:14.0];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        [cell autorelease];
    }
    cell.textLabel.text = [NSString stringWithFormat:@"Gif %d", indexPath.row + 1];
    return cell;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_gifURLs count];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.gifVC = [[[CMGifViewController alloc] init] autorelease];
    int index = indexPath.row;
    CMGifDataRecord *gifRec = [_downloadedGif objectAtIndex:index];
    if ([gifRec isEqual:[NSNull null]])
    {
        NSLog(@"No data downloaded, creating gif record");
        gifRec = [[CMGifDataRecord alloc] init];
        gifRec.urlString = [_gifURLs objectAtIndex:index];
        [_downloadedGif replaceObjectAtIndex:index withObject:gifRec];
        [gifRec release];
    }
    if (!gifRec.complete)
    {
        NSLog(@"Download is not complete, resuming");
        self.gifVC.progressView.hidden = NO;
        [self downloadDataForGif:gifRec];
    }
    else
    {
        NSLog(@"Data downloaded, just opening");
        [self.gifVC showGIFfromData:gifRec.data];
    }
    [self.navigationController pushViewController:self.gifVC animated:YES];

    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark Object lifecycle

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])
    {
        _gifURLs = [[NSArray arrayWithObjects:
                     @"http://s01.developerslife.ru/public/images/gifs/d898ff0d-e06d-482c-95dd-552de9307aa6.gif",
                     @"http://s0.developerslife.ru/public/images/gifs/407ab7c4-64d8-4e72-b9cb-e0c06d8d3130.gif",
                     @"http://s0.developerslife.ru/public/images/gifs/baaaf66f-8857-488b-9d28-95ab450900ec.gif",
                     @"http://s01.developerslife.ru/public/images/gifs/89721c82-00d7-4737-b569-d5aeb3f81cd2.gif",
                     @"http://s1.developerslife.ru/public/images/gifs/6f3b2508-2deb-41a2-912c-95dc9f0ecfc0.gif",
                     @"http://s1.developerslife.ru/public/images/gifs/8ebcb08a-bffe-49db-9b47-0b85cec7d2b1.gif",
                     @"http://s0.developerslife.ru/public/images/gifs/86ae10d7-5b64-485a-824d-d3bb127b0793.gif",
                     @"http://s3.developerslife.ru/public/images/gifs/fa02544c-ddf5-4a17-971d-5a3b6221cf67.gif",
                     @"http://s3.developerslife.ru/public/images/gifs/0945408f-6258-4545-95a2-486cc5096181.gif",
                     @"http://s01.developerslife.ru/public/images/gifs/10e11bec-4db0-4396-b17e-117fb2e1ddc0.gif",
                     @"http://s0.developerslife.ru/public/images/gifs/2260791b-7d7d-4995-898e-f43182adc720.gif",
                     @"http://s1.developerslife.ru/public/images/gifs/4774545a-f5b9-442f-89dd-5c7ec11bdcc7.gif",
                     @"http://s0.developerslife.ru/public/images/gifs/c11b27ed-a800-48b0-b8db-a8f1206133f5.gif", nil] retain];
        
        _downloadedGif = [[NSMutableArray alloc] initWithCapacity:_gifURLs.count];
        for (int i = 0; i < _gifURLs.count; i++)
            [_downloadedGif addObject:[NSNull null]];
        _backgroundQueue = dispatch_queue_create("rsstest.background.queue", NULL);
    }
    
    return self;
}

- (void) viewWillAppear:(BOOL) animated
{
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
    if (_dataDownloader)
    {
                           [_dataDownloader stopDownload];
                           [_dataDownloader release];
                           _dataDownloader = nil;

    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    for (int i = 0; i < _gifURLs.count; i++)
        [_downloadedGif replaceObjectAtIndex:i withObject:[NSNull null]];
}

- (void) dealloc
{
    self.dataDownloader = nil;
    self.gifVC = nil;
    [_downloadedGif release];
    [_gifURLs release];
    dispatch_release(_backgroundQueue);
    [super dealloc];
}

@end
