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
#import "LadioTailViewController.h"

@implementation LadioTailViewController

#pragma mark UIView methods

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // リモコン対応
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated
{
    // リモコン対応
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [self resignFirstResponder];

    [super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -
#pragma mark UIResponder methods

- (BOOL)canBecomeFirstResponder
{
    // リモコン対応
    return YES;
}

- (void)remoteControlReceivedWithEvent:(UIEvent*)event
{
	switch (event.subtype) {
		case UIEventSubtypeRemoteControlTogglePlayPause:
            // リモコンからのボタンクリック
            [[Player sharedInstance] switchPlayStop];
            break;
		default:
            break;
	}
}

@end
