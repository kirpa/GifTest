#import <Foundation/Foundation.h>

@class CMGifDataRecord;

@protocol DataDownloaderDelegate <NSObject>

- (void) dataDownloaded:(CMGifDataRecord *) gifRecord;
- (void) progressChanged:(float) progress;

@end

@interface CMDataDownloader : NSObject
{
    BOOL    _done;
}


@property (assign, nonatomic) id<DataDownloaderDelegate> delegate;

- (void) downloadDataForGif:(CMGifDataRecord *) gifRecord;
- (void) stopDownload;

@end
