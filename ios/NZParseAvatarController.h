/* vim: set ai noet ts=4 sw=4 tw=115: */
//
// Copyright (c) 2014 Nikolay Zapolnov (zapolnov@gmail.com).
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "NZParseAvatar.h"

@interface NZParseAvatarController : NSObject<NZParseAvatarListener>
@property (nonatomic, retain, readonly) UIView * blackoutView;
@property (nonatomic, retain, readonly) UIProgressView * progressView;
@property (nonatomic, retain, readonly) UIActivityIndicatorView * activityIndicator;
@property (nonatomic, retain, readonly) UIImage * image;
@property (nonatomic, retain) UIImage * placeholderImage;
@property (nonatomic, retain) PFUser * user;
@property (nonatomic, assign) BOOL isThumbnail;
@property (nonatomic, copy) void (^ onImageChanged)(UIImage * image);
-(id)initWithUser:(PFUser *)user placeholderImage:(UIImage *)image isThumbnail:(BOOL)thumb;
-(void)layoutSubviews:(CGRect)frame;
@end
