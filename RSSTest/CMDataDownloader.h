#import <Foundation/Foundation.h>

@protocol DataDownloaderDelegate <NSObject>

- (void) dataDownloaded:(NSData *) data;

@end

@interface CMDataDownloader : NSObject
{
    BOOL    _done;
}


@property (assign, nonatomic) id<DataDownloaderDelegate> delegate;

- (void) downloadData;

@end
