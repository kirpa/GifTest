#import <Foundation/Foundation.h>

@class CMRssRecord;

@protocol DataParserDelegate <NSObject>

- (void) recordsParsed:(NSArray *) rssRecords;
- (void) finishedParsing;

@end

@interface CMDataParser : NSObject <NSXMLParserDelegate>
{
    NSDateFormatter     *_dateFormatter;
    CMRssRecord         *_currentRecord;
    BOOL                _needElement;
}

@property (assign, nonatomic) id<DataParserDelegate> delegate;

- (void) parseData:(NSData *) data;

@end
