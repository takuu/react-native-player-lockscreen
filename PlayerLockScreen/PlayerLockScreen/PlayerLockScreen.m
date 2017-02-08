#import "PlayerLockScreen.h"
#import "RCTConvert.h"
#import "RCTBridge.h"
#import "RCTEventDispatcher.h"
#import <AVFoundation/AVAudioSession.h>

@import MediaPlayer;

@interface PlayerLockScreen ()

@property (nonatomic, copy) NSString *artworkUrl;

@end

@implementation PlayerLockScreen

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE()

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

RCT_EXPORT_METHOD(setNowPlaying:(NSDictionary *) jsonObject)
{
    MPNowPlayingInfoCenter *center = [MPNowPlayingInfoCenter defaultCenter];
    
    
    // If the json object could not be parsed we exit early
    if (jsonObject == nil) {
        NSLog(@"Could not parse now playing json object");
        return;
    }
    
    // Create media dictionary from existing keys or create a new one, this way we can update single attributes if we want to
    NSMutableDictionary *mediaDict = (center.nowPlayingInfo != nil) ? [[NSMutableDictionary alloc] initWithDictionary: center.nowPlayingInfo] : [NSMutableDictionary dictionary];
    
    if ([jsonObject objectForKey: @"albumTitle"] != nil) {
        [mediaDict setValue:[jsonObject objectForKey: @"albumTitle"] forKey:MPMediaItemPropertyAlbumTitle];
    }
    
    if ([jsonObject objectForKey: @"trackCount"] != nil) {
        [mediaDict setValue:[jsonObject objectForKey: @"trackCount"] forKey:MPMediaItemPropertyAlbumTrackCount];
    }
    
    if ([jsonObject objectForKey: @"trackNumber"] != nil) {
        [mediaDict setValue:[jsonObject objectForKey: @"trackNumber"] forKey:MPMediaItemPropertyAlbumTrackNumber];
    }
    
    if ([jsonObject objectForKey: @"artist"] != nil) {
        [mediaDict setValue:[jsonObject objectForKey: @"artist"] forKey:MPMediaItemPropertyArtist];
    }
    
    if ([jsonObject objectForKey: @"composer"] != nil) {
        [mediaDict setValue:[jsonObject objectForKey: @"composer"] forKey:MPMediaItemPropertyComposer];
    }
    
    if ([jsonObject objectForKey: @"discCount"] != nil) {
        [mediaDict setValue:[jsonObject objectForKey: @"discCount"] forKey:MPMediaItemPropertyDiscCount];
    }
    
    if ([jsonObject objectForKey: @"discNumber"] != nil) {
        [mediaDict setValue:[jsonObject objectForKey: @"discNumber"] forKey:MPMediaItemPropertyDiscNumber];
    }
    
    if ([jsonObject objectForKey: @"genre"] != nil) {
        [mediaDict setValue:[jsonObject objectForKey: @"genre"] forKey:MPMediaItemPropertyGenre];
    }
    
    if ([jsonObject objectForKey: @"persistentID"] != nil) {
        [mediaDict setValue:[jsonObject objectForKey: @"persistentID"] forKey:MPMediaItemPropertyPersistentID];
    }
    
    if ([jsonObject objectForKey: @"playbackDuration"] != nil) {
        [mediaDict setValue:[jsonObject objectForKey: @"playbackDuration"] forKey:MPMediaItemPropertyPlaybackDuration];
    }
    
    if ([jsonObject objectForKey: @"title"] != nil) {
        [mediaDict setValue:[jsonObject objectForKey: @"title"] forKey:MPMediaItemPropertyTitle];
    }
    
    if ([jsonObject objectForKey: @"elapsedPlaybackTime"] != nil) {
        [mediaDict setValue:[jsonObject objectForKey: @"elapsedPlaybackTime"] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
    }
    
    if ([jsonObject objectForKey: @"playbackRate"] != nil) {
        [mediaDict setValue:[jsonObject objectForKey: @"playbackRate"] forKey:MPNowPlayingInfoPropertyPlaybackRate];
    } else {
        // In iOS Simulator, always include the MPNowPlayingInfoPropertyPlaybackRate key in your nowPlayingInfo dictionary
        [mediaDict setValue:[NSNumber numberWithDouble:1] forKey:MPNowPlayingInfoPropertyPlaybackRate];
    }
    
    if ([jsonObject objectForKey: @"playbackQueueIndex"] != nil) {
        [mediaDict setValue:[jsonObject objectForKey: @"playbackQueueIndex"] forKey:MPNowPlayingInfoPropertyPlaybackQueueIndex];
    }
    
    if ([jsonObject objectForKey: @"playbackQueueCount"] != nil) {
        [mediaDict setValue:[jsonObject objectForKey: @"playbackQueueCount"] forKey:MPNowPlayingInfoPropertyPlaybackQueueCount];
    }
    
    if ([jsonObject objectForKey: @"chapterNumber"] != nil) {
        [mediaDict setValue:[jsonObject objectForKey: @"chapterNumber"] forKey:MPNowPlayingInfoPropertyChapterNumber];
    }
    
    if ([jsonObject objectForKey: @"chapterCount"] != nil) {
        [mediaDict setValue:[jsonObject objectForKey: @"chapterCount"] forKey:MPNowPlayingInfoPropertyChapterCount];
    }
    
    center.nowPlayingInfo = mediaDict;
    
    // Custom handling of artwork in another thread, will be loaded async
    if ([jsonObject objectForKey: @"artwork"] != nil) {
        [self setNowPlayingArtwork: [jsonObject objectForKey: @"artwork"]];
    }
    
}

RCT_EXPORT_METHOD(setNowPlayingArtwork:(NSString *) url)
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        UIImage *image = nil;
        // check whether artwork path is present
        if (![url isEqual: @""]) {
            // artwork is url download from the interwebs
            if ([url hasPrefix: @"http://"] || [url hasPrefix: @"https://"]) {
                NSURL *imageURL = [NSURL URLWithString:url];
                NSData *imageData = [NSData dataWithContentsOfURL:imageURL];
                image = [UIImage imageWithData:imageData];
            } else {
                // artwork is local. so create it from a UIImage
                NSString *basePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
                NSString *fullPath = [NSString stringWithFormat:@"%@%@", basePath, url];
                BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:fullPath];
                if (fileExists) {
                    image = [UIImage imageNamed:fullPath];
                }
            }
        }
        
        // Check if image was available otherwise don't do anything
        if (image == nil) {
            return;
        }
        
        // check whether image is loaded
        CGImageRef cgref = [image CGImage];
        CIImage *cim = [image CIImage];
        if (cim != nil || cgref != NULL) {
            // Callback to main queue to set nowPlayingInfo
            dispatch_async(dispatch_get_main_queue(), ^{
                MPNowPlayingInfoCenter *center = [MPNowPlayingInfoCenter defaultCenter];
                MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithImage: image];
                NSMutableDictionary *mediaDict = (center.nowPlayingInfo != nil) ? [[NSMutableDictionary alloc] initWithDictionary: center.nowPlayingInfo] : [NSMutableDictionary dictionary];
                [mediaDict setValue:artwork forKey:MPMediaItemPropertyArtwork];
                center.nowPlayingInfo = mediaDict;
            });
        }
    });
}

@end
