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
#import "NZParseAvatarController.h"
#import "NZParseAvatar.h"

@implementation NZParseAvatarController
{
	PFUser * user;
	UIImage * placeholderImage;
	int uploading;
	int downloading;
	BOOL usingPlaceholder;
	BOOL isThumbnail;
	long long imageRequestID;
}

@synthesize blackoutView;
@synthesize progressView;
@synthesize activityIndicator;
@synthesize image;
@synthesize onImageChanged;

-(id)initWithUser:(PFUser *)aUser placeholderImage:(UIImage *)aImage isThumbnail:(BOOL)thumb
{
	self = [super init];
	if (self)
	{
		usingPlaceholder = YES;
		placeholderImage = [aImage retain];
		image = [aImage retain];
		isThumbnail = thumb;
		imageRequestID = -1;

		blackoutView = [[UIView alloc] init];
		blackoutView.hidden = YES;
		blackoutView.backgroundColor = [UIColor blackColor];
		blackoutView.alpha = 0.5f;
		blackoutView.userInteractionEnabled = YES;

		activityIndicator = [[UIActivityIndicatorView alloc]
			initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
		activityIndicator.hidden = YES;
		[blackoutView addSubview:activityIndicator];

		progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
		progressView.hidden = YES;
		progressView.progressTintColor = [UIColor whiteColor];
		progressView.trackTintColor = [UIColor blackColor];
		[blackoutView addSubview:progressView];

		[NZParseAvatar addListener:self];
		[self setUser:aUser];
	}
	return self;
}

-(void)dealloc
{
	[NZParseAvatar removeListener:self];

	[blackoutView release];
	blackoutView = nil;

	[user release];
	user = nil;

	[placeholderImage release];
	placeholderImage = nil;

	[image release];
	image = nil;

	[onImageChanged release];
	onImageChanged = nil;

	[progressView release];
	progressView = nil;

	[activityIndicator release];
	activityIndicator = nil;

	[super dealloc];
}

-(PFUser *)user
{
	return user;
}

-(UIImage *)placeholderImage
{
	return placeholderImage;
}

-(BOOL)isThumbnail
{
	return isThumbnail;
}

-(void)setPlaceholderImage:(UIImage *)aImage
{
	if (placeholderImage == aImage)
		return;

	[placeholderImage release];
	placeholderImage = [aImage retain];

	if (usingPlaceholder)
	{
		[image release];
		image = [aImage retain];
		if (onImageChanged)
			onImageChanged(image);
	}
}

-(void)setIsThumbnail:(BOOL)thumb
{
	if ((isThumbnail && thumb) || (!isThumbnail && !thumb))
		return;

	isThumbnail = thumb;

	if (user)
		[self downloadImage];
}

-(void)setUser:(PFUser *)aUser
{
	if (aUser == user)
		return;

	[user release];
	user = nil;

	[image release];
	image = [placeholderImage retain];
	usingPlaceholder = YES;
	if (onImageChanged)
		onImageChanged(image);

	if (!aUser)
	{
		downloading = 0;
		uploading = 0;
		[self updateBlackout];
		return;
	}

	user = [aUser retain];

	downloading = [NZParseAvatar isDownloadingForUser:user];
	uploading = [NZParseAvatar isUploadingForUser:user];
	[self updateBlackout];

	[self downloadImage];
}

-(void)downloadImage
{
	if (user)
		[NZParseAvatar downloadForUser:user thumbnail:isThumbnail];
}

-(void)onBeginDownloadingAvatarForUser:(PFUser *)aUser requestID:(long long)requestID
{
	if (user && aUser && [[user objectId] isEqualToString:[aUser objectId]])
	{
		++downloading;
		[self updateBlackout];
	}
}

-(void)onEndDownloadingAvatarForUser:(PFUser *)aUser image:(UIImage *)aImage isThumbnail:(BOOL)isThumb
	requestID:(long long)requestID
{
	if (user && aUser && [[user objectId] isEqualToString:[aUser objectId]])
	{
		--downloading;
		[self updateBlackout];

		if (aImage && requestID > imageRequestID && (isThumbnail || !isThumb || usingPlaceholder))
		{
			[image release];
			image = [aImage retain];
			usingPlaceholder = NO;
			imageRequestID = requestID;
			if (onImageChanged)
				onImageChanged(image);
		}
	}
}

-(void)onBeginUploadingAvatarForUser:(PFUser *)aUser requestID:(long long)requestID
{
	if (user && aUser && [[user objectId] isEqualToString:[aUser objectId]])
	{
		if (!uploading)
			[progressView setProgress:0.0f animated:NO];
		++uploading;
		[self updateBlackout];
	}
}

-(void)onContinueUploadingAvatarForUser:(PFUser *)aUser progress:(float)progress requestID:(long long)requestID
{
	if (user && aUser && [[user objectId] isEqualToString:[aUser objectId]])
	{
		if (progress > progressView.progress)
			[progressView setProgress:progress animated:YES];
	}
}

-(void)onEndUploadingAvatarForUser:(PFUser *)aUser image:(UIImage *)aImage thumbnail:(UIImage *)thumb
	requestID:(long long)requestID
{
	if (user && aUser && [[user objectId] isEqualToString:[aUser objectId]])
	{
		--uploading;
		[self updateBlackout];

		if (aImage && requestID > imageRequestID)
		{
			[image release];
			image = [aImage retain];
			usingPlaceholder = NO;
			imageRequestID = requestID;
			if (onImageChanged)
				onImageChanged(image);
		}
	}
}

-(void)updateBlackout
{
	blackoutView.hidden = (!downloading && !uploading);
	BOOL hideActivity = (!downloading || uploading);
	progressView.hidden = !uploading;

	if (activityIndicator.hidden != hideActivity)
	{
		activityIndicator.hidden = hideActivity;
		if (hideActivity)
			[activityIndicator stopAnimating];
		else
			[activityIndicator startAnimating];
	}
}

-(void)layoutSubviews:(CGRect)frame
{
	blackoutView.frame = frame;
	activityIndicator.frame = frame;
	progressView.frame = frame;
}

@end
