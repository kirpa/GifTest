#import "CMGifDataRecord.h"

@implementation CMGifDataRecord

#pragma mark Object lifecycle

- (id) init
{
    if (self = [super init])
    {
        self.complete = NO;
        self.size = 0;
        self.data = [NSMutableData data];
    }
    return self;
}

- (void) dealloc
{
    self.data = nil;
    self.urlString = nil;
    [super dealloc];
}

@end
