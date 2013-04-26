#import <Foundation/Foundation.h>

@class CMRssRecord;

@protocol DataParserDelegate <NSObject>

- (void) recordParsed:(CMRssRecord *) rssRecord;
- (void) finishedParsing;

@end

@interface CMDataParser : NSObject <NSXMLParserDelegate>
{
    NSXMLParser         *_parser;
    NSDateFormatter     *_dateFormatter;
    CMRssRecord         *_currentRecord;
    BOOL                _needElement;
}

@property (assign, nonatomic) id<DataParserDelegate> delegate;

- (void) parseData:(NSData *) data;

@end
