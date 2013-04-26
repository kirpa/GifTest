#import "CMDataDownloader.h"

@interface CMDataDownloader()

@property (retain, nonatomic) NSMutableData *data;
@property (retain, nonatomic) NSURLConnection *connection;

@end

@implementation CMDataDownloader

static NSString *cRSSUrl = @"http://habrahabr.ru/rss/hubs/";

- (void) downloadData
{
    _done = NO;
    self.data = [NSMutableData data];
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:cRSSUrl]];
    self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    if (self.connection)
    {
        do
        {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        } while (!_done);
    }
}

#pragma mark NSURLConnection delegate methods

- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    _done = YES;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    NSLog(@"Error downloading RSS data: %@", error);
    [self.delegate dataDownloaded:nil];
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.data appendData:data];    
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection
{
    _done = YES;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self.delegate dataDownloaded:self.data];
}

#pragma mark Object lifecycle

- (void) dealloc
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    self.data = nil;
    self.connection = nil;
    [super dealloc];
}

@end
