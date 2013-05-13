#import <Foundation/Foundation.h>

@interface CMGifDataRecord : NSObject

@property (assign, nonatomic) BOOL  complete;
@property (assign, nonatomic) long long  size;
@property (retain, nonatomic) NSMutableData *data;
@property (retain, nonatomic) NSString *urlString;

@end
