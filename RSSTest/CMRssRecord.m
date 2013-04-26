#import "CMRssRecord.h"

@interface CMRssRecord()

@property (readonly, nonatomic) NSDateFormatter *dateFormatter;

@end

@implementation CMRssRecord

#pragma mark NSCoding protocol

static NSString *cTitleKey  = @"rssTitle";
static NSString *cUrlKey    = @"rssUrl";
static NSString *cDateKey   = @"rssDate";

- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.title forKey:cTitleKey];
    [aCoder encodeObject:self.url forKey:cUrlKey];
    [aCoder encodeObject:self.date forKey:cDateKey];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    if (self = [self init])
    {
        self.title = [aDecoder decodeObjectForKey:cTitleKey];
        self.url = [aDecoder decodeObjectForKey:cUrlKey];
        self.date = [aDecoder decodeObjectForKey:cDateKey];
    }
    
    return self;
}

#pragma mark Object lifecycle

- (void) dealloc
{
    self.title = nil;
    self.url = nil;
    self.date = nil;
    [super dealloc];
}

@end
