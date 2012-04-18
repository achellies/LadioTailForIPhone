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
#import "AdBannerManager.h"
#import "WebPageViewController.h"

@implementation WebPageViewController
{
@private
    /// ページを読み込み中か
    BOOL isPageLoading;
}

@synthesize url;
@synthesize topNavigationItem;
@synthesize pageWebView;
@synthesize backButton;
@synthesize forwardButton;
@synthesize reloadButton;
@synthesize bottomView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        ;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [pageWebView loadRequest:[NSURLRequest requestWithURL:url]];

    // 下部Viewの背景色をグラデーションに
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = bottomView.bounds;
    gradient.colors = [NSArray arrayWithObjects:
                       (id) [UIColor colorWithRed:0.22 green:0.22 blue:0.22 alpha:1].CGColor,
                       (id) [UIColor colorWithRed:0 green:0 blue:0 alpha:1].CGColor,
                       nil];
    [bottomView.layer insertSublayer:gradient atIndex:0];

    // ボタン類の表示を更新する
    [self updateViews];
}

- (void)viewDidUnload
{
    [self setPageWebView:nil];
    [self setBackButton:nil];
    [self setForwardButton:nil];
    [self setReloadButton:nil];
    [self setTopNavigationItem:nil];
    [self setBottomView:nil];
    [super viewDidUnload];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // WebViewのデリゲートを設定する
    pageWebView.delegate = self;

    // ページ読み込み中フラグを下げる
    isPageLoading = NO;

    // リモコン対応
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];

    // 広告を表示する
    AdBannerManager *adBannerManager = [AdBannerManager sharedInstance];
    [adBannerManager setShowPosition:CGPointMake(0, 316) hiddenPosition:CGPointMake(320, 316)];
    adBannerManager.bannerSibling = self.view;
}

- (void)viewWillDisappear:(BOOL)animated
{
    // WebViewのデリゲートを削除する
    pageWebView.delegate = nil;
    
    // WebViewの読み込みを中止する
    [pageWebView stopLoading];
    
    if (isPageLoading) {
        // ネットワークインジケーターを消す
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }

    // リモコン対応
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [self resignFirstResponder];
    
    [super viewWillDisappear:animated];
}

- (BOOL)canBecomeFirstResponder
{
    // リモコン対応
    return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)remoteControlReceivedWithEvent:(UIEvent*)event
{
    // リモコンからのボタンクリック
    [[Player sharedInstance] playFromRemoteControl:event];
}

#pragma mark UIWebViewDelegate methods

- (void)webViewDidStartLoad:(UIWebView*)webView
{
    // ネットワークインジケーターを表示
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    // ページ読み込み中フラグを上げる
    isPageLoading = YES;

    // ボタン類の表示を更新する
    [self updateViews];
}

- (void)webViewDidFinishLoad:(UIWebView*)webView
{
    // ネットワークインジケーターを消す
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    // ページ読み込み中フラグを下げる
    isPageLoading = NO;

    // ボタン類の表示を更新する
    [self updateViews];
}

- (void)webView:(UIWebView*)webView didFailLoadWithError:(NSError*)error
{
    // ネットワークインジケーターを消す
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    // ページ読み込み中フラグを下げる
    isPageLoading = NO;

    // ボタン類の表示を更新する
    [self updateViews];
}

- (IBAction)back:(id)sender
{
    if (pageWebView.canGoBack) {
        [pageWebView goBack];
    }
}

- (IBAction)forward:(id)sender
{
    if (pageWebView.canGoForward) {
        [pageWebView goForward];
    }
}

- (IBAction)goToBottom:(id)sender
{
    int pageHeight = pageWebView.scrollView.contentSize.height;
    if (pageHeight == 0) {
        return;
    }

    CGPoint movePoint = CGPointMake(
                                    pageWebView.scrollView.contentOffset.x,
                                    pageHeight - pageWebView.frame.size.height);
#ifdef DEBUG
    NSLog(@"Page scroll form %@ to %@.", NSStringFromCGPoint(pageWebView.scrollView.contentOffset), NSStringFromCGPoint(movePoint));
#endif /* #ifdef DEBUG */
    [pageWebView.scrollView setContentOffset:movePoint animated:YES];
}

- (IBAction)reload:(id)sender
{
    if (isPageLoading) {
        [pageWebView stopLoading];
    } else {
        [pageWebView reload];
    }
}

- (void)updateViews
{
    NSString* title = [pageWebView stringByEvaluatingJavaScriptFromString:@"document.title"];
    if (!([title length] == 0)) {
        topNavigationItem.title = title;
    }

    backButton.enabled = pageWebView.canGoBack;
    forwardButton.enabled = pageWebView.canGoForward;
    if (isPageLoading) {
        [reloadButton setImage:[UIImage imageNamed:@"delete.png"] forState:UIControlStateNormal];
    } else {
        [reloadButton setImage:[UIImage imageNamed:@"playback_reload.png"] forState:UIControlStateNormal];
    }
}

@end