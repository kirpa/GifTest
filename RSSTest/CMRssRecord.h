#import <Foundation/Foundation.h>

@interface CMRssRecord : NSObject <NSCoding>

@property (retain, nonatomic) NSString *title;
@property (retain, nonatomic) NSString *url;
@property (retain, nonatomic) NSDate *date;

@end
