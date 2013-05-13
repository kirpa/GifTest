#import "CMDataDownloader.h"
#import "CMGifDataRecord.h"

@interface CMDataDownloader()

@property (retain, nonatomic) NSURLConnection *connection;
@property (retain, nonatomic) CMGifDataRecord *gifRecord;

@end

@implementation CMDataDownloader

static const float cDownloadDelay           = 0.0;
static NSString *cRangeHeader               = @"Range";
static NSString *cGifType                   = @"image/gif";

- (void) stopDownload
{
    [self.connection cancel];
}

- (void) downloadDataForGif:(CMGifDataRecord *) gifRecord
{
    _done = NO;
    self.gifRecord = gifRecord;
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:gifRecord.urlString]];
    if ([gifRecord.data length] > 0)
    {
        [[NSURLCache sharedURLCache] removeCachedResponseForRequest:request];
        NSString *rangeString = [NSString stringWithFormat:@"bytes=%d-", [gifRecord.data length]];
        [request setValue:rangeString forHTTPHeaderField:cRangeHeader];
    }
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
    NSLog(@"Error downloading GIF data: %@", error);
    [self.delegate dataDownloaded:nil];
}

- (void) connection:(NSURLConnection *) connection didReceiveResponse:(NSURLResponse *)response
{
    if ([response isKindOfClass:[NSHTTPURLResponse class]])
    {
        NSDictionary *headers = [(NSHTTPURLResponse *)response allHeaderFields];
        NSLog(@"Response headers are: %@", headers);
        if ([response.MIMEType isEqualToString:cGifType] && self.gifRecord.size == 0)
        {
            self.gifRecord.size = response.expectedContentLength;
        }
    }
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{    
    [self.gifRecord.data appendData:data];
    if (self.gifRecord.data.length > 0)
    {
        NSLog(@"length // total size: %d -> %lld", self.gifRecord.data.length, self.gifRecord.size);
        [self.delegate progressChanged: (double)self.gifRecord.data.length / self.gifRecord.size];
    }
    if (cDownloadDelay > 0.)
        [NSThread sleepForTimeInterval:cDownloadDelay];
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"Connection finished successfully!");
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self.delegate dataDownloaded:self.gifRecord];
    self.gifRecord.complete = YES;
    _done = YES;
}

#pragma mark Object lifecycle

- (void) dealloc
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    self.gifRecord = nil;
    self.connection = nil;
    [super dealloc];
}

@end
