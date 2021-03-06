/*
 * Copyright (c) 2012 Yuichi Hirano
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

#import <AudioToolbox/AudioServices.h>
#import "LadioTailConfig.h"
#import "RadioLib/RadioLib.h"
#import "ICloudStrorage.h"
#import "ApnsStorage.h"
#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // iCloudから通知を受ける
    [[ICloudStrorage sharedInstance] registICloudNotification];

    if (PROVIDER_URL != nil) {
        // お気に入りの変化を監視し、変化時にはプロバイダにお気に入り情報を送信する
        [[ApnsStorage sharedInstance] registApnsService];

        // Remote Notification を受信するためにデバイスを登録する
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge
                                                                               | UIRemoteNotificationTypeSound
                                                                               | UIRemoteNotificationTypeAlert)];
    }

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // アイコンバッジを消す
    application.applicationIconBadgeNumber = 0;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Remote Notification を受信しないようにする
    [[UIApplication sharedApplication] unregisterForRemoteNotifications];
    
    // お気に入りをプロバイダに送信しないようにする
    [[ApnsStorage sharedInstance] unregistApnsService];

    // iCloudからの通知を受けなくする
    [[ICloudStrorage sharedInstance] unregistICloudNotification];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)devToken
{
    
#if DEBUG
    NSLog(@"DeviceToken: %@", devToken);
#endif // #if DEBUG

    // デバイストークンを記憶する
    [[ApnsStorage sharedInstance] setDeviceToken:devToken];

    // お気に入りをプロバイダに送信
    [[ApnsStorage sharedInstance] sendFavoriteToProvider];
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)err
{
    NSLog(@"Error : Fail Regist to APNS. (%@)", err);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    NSDictionary *apsInfo = [userInfo objectForKey:@"aps"];
#if DEBUG
    NSLog(@"Received Push Info: %@", [apsInfo description]);
#endif // #if DEBUG

    NSString *alert = [apsInfo objectForKey:@"alert"];
    UIApplicationState state = [application applicationState];

    switch (state) {
        case UIApplicationStateActive: // アクティブ状態でRemote Notificationを受け取った場合
            // 端末をバイブレーション
            AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
            // アラートを表示
            if (alert != nil) {
                UIAlertView *alertView = [[UIAlertView alloc] init];
                alertView.message = alert;
                NSString *buttonTitle = NSLocalizedString(@"OK", @"OK");
                [alertView addButtonWithTitle:buttonTitle];
                [alertView show];
            }
            // アイコンバッジを消す
            application.applicationIconBadgeNumber = 0;
            break;
        default:
            break;
    }

    switch (state) {
        case UIApplicationStateActive: // アクティブ状態でRemote Notificationを受け取った場合
        case UIApplicationStateInactive: // バックグラウンド状態でRemote Notificationを受け取り、ユーザーがボタンをタップした場合
            // ヘッドラインを更新する
            [[Headline sharedInstance] fetchHeadline];
            break;
        default:
            break;
    }
}

@end
