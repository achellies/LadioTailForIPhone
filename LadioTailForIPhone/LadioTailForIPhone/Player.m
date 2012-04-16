/*
 * Copyright (c) 2012 Y.Hirano
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import "Player.h"

static Player *instance = nil;


@implementation Player
{
@private
    AVPlayer *player;
    PlayerState state;
    NSURL *playUrl;
}

+ (Player *)sharedInstance
{
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        instance = [[Player alloc] init];
    });
    return instance;
}

- (id)init
{
    if (self = [super init]) {
        @synchronized (self) {
            state = PlayerStateIdle;
        }

        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [[AVAudioSession sharedInstance] setDelegate:self];
        NSError *setCategoryError = nil;
        [audioSession setCategory:AVAudioSessionCategoryPlayback error:&setCategoryError];
        if (setCategoryError) {
            NSLog(@"Audio session setCategory error.");
        }
        NSError *setActiveError = nil;
        [audioSession setActive:YES error:&setActiveError];
        if (setActiveError) {
            NSLog(@"Audio session setActive error.");
        }

        // 再生が終端ないしエラーで終了した際に通知を受け取り、状態を変更する
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(stopped:)
         name:AVPlayerItemDidPlayToEndTimeNotification
         object:nil];
        [[NSNotificationCenter defaultCenter]
         addObserver:self selector:@selector(stopped:)
         name:AVPlayerItemFailedToPlayToEndTimeNotification
         object:nil];
    }
    return self;
}

- (void)dealloc
{
    [self stop];

    [[NSNotificationCenter defaultCenter]
     removeObserver:self
     name:AVPlayerItemDidPlayToEndTimeNotification
     object:nil];
    [[NSNotificationCenter defaultCenter]
     removeObserver:self
     name:AVPlayerItemFailedToPlayToEndTimeNotification
     object:nil];

    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *setActiveError = nil;
    [audioSession setActive:NO error:&setActiveError];
    if (setActiveError) {
        NSLog(@"Audio session setActive error.");
    }
}

- (void)play:(NSURL *)url
{
    @synchronized (self) {
        // 既に再生中のURLとおなじ場合は何もしない
        if ([self isPlaying:url]) {
            return;
        }

        switch (state) {
            case PlayerStatePlay:
                // 再生中中は停止
                [player pause];
                [player removeObserver:self forKeyPath:@"status"];
                // スルー
            case PlayerStateIdle:
                state = PlayerStatePrepare;
                playUrl = url;
                NSLog(@"Play start %@", [playUrl absoluteString]);
                [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_NAME_PLAY_STATE_CHANGED object:self];
                player = [AVPlayer playerWithURL:url];
                [player addObserver:self forKeyPath:@"status" options:0 context:nil];
                [player play];
                break;
            case PlayerStatePrepare:
            default:
                break;
        }
    }
}

- (void)stop
{
    @synchronized (self) {
        [player pause];
        [player removeObserver:self forKeyPath:@"status"];
        state = PlayerStateIdle;
        NSLog(@"Play stopped by user operation.");
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_NAME_PLAY_STATE_CHANGED object:self];
    }
}

- (BOOL)isPlaying:(NSURL *)url
{
    @synchronized (self) {
        NSURL *playingUrl = [self getPlayUrl];
        if (playingUrl == nil) {
            return NO;
        } else {
            return ([[playingUrl absoluteString] isEqualToString:[url absoluteString]]);
        }
    }
}

- (NSURL *)getPlayUrl
{
    @synchronized (self) {
        switch (state) {
            case PlayerStatePlay:
                return playUrl;
            case PlayerStateIdle:
            case PlayerStatePrepare:
            default:
                return nil;
        }
    }
}

- (PlayerState)getState
{
    @synchronized (self) {
        return state;
    }
}

- (void)stopped:(NSNotification *)notification
{
    @synchronized (self) {
        playUrl = nil;
        state = PlayerStateIdle;
        NSLog(@"Play stopped.");
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_NAME_PLAY_STATE_CHANGED object:self];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context
{
    if (object == player && [keyPath isEqualToString:@"status"]) {
        if (player.status == AVPlayerStatusReadyToPlay) {
            @synchronized (self) {
                state = PlayerStatePlay;
                NSLog(@"Play started.");
                [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_NAME_PLAY_STATE_CHANGED object:self];
            }
        } else if (player.status == AVPlayerStatusFailed) {
            @synchronized (self) {
                state = PlayerStateIdle;
                NSLog(@"Play failed.");
                [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_NAME_PLAY_STATE_CHANGED object:self];
            }
        }
    }
}

- (void)beginInterruption
{
#if DEBUG
	NSLog(@"audio settion beginInterruption");
#endif /* #if DEBUG */
}

- (void)endInterruption
{
#if DEBUG
	NSLog(@"audio settion endInterruption");
#endif /* #if DEBUG */
}

- (void)endInterruptionWithFlags:(NSUInteger)flags
{
#if DEBUG
	NSLog(@"audio settion endInterruptionWithFlags %d", flags);
#endif /* #if DEBUG */
}

- (void)inputIsAvailableChanged:(BOOL)isInputAvailable
{
#if DEBUG
	NSLog(@"audio settion inputIsAvailableChanged %d", isInputAvailable);
#endif /* #if DEBUG */
}

@end
