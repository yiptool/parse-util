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
#import "NZParseAvatarButton.h"
#import "NZParseAvatarController.h"

@implementation NZParseAvatarButton
{
	NZParseAvatarController * controller;
	BOOL displayAsCircle;
}

-(id)init
{
	return [self initWithUser:nil placeholderImage:nil isThumbnail:YES];
}

-(id)initWithUser:(PFUser *)user placeholderImage:(UIImage *)image isThumbnail:(BOOL)thumb
{
	self = [super init];
	if (self)
	{
		controller = [[NZParseAvatarController alloc] initWithUser:user placeholderImage:image isThumbnail:thumb];
		controller.onImageChanged = ^(UIImage * image) { self.backgroundImage = image; };
		[self addSubview:controller.blackoutView];

		self.contentMode = UIViewContentModeScaleAspectFill;
		self.imageView.contentMode = UIViewContentModeScaleAspectFill;
	}
	return self;
}

-(void)dealloc
{
	controller.onImageChanged = nil;
	[controller release];
	controller = nil;

	[super dealloc];
}

-(UIImage *)placeholderImage
{
	return controller.placeholderImage;
}

-(PFUser *)user
{
	return controller.user;
}

-(BOOL)isThumbnail
{
	return controller.isThumbnail;
}

-(BOOL)displayAsCircle
{
	return displayAsCircle;
}

-(void)setPlaceholderImage:(UIImage *)image
{
	controller.placeholderImage = image;
}

-(void)setUser:(PFUser *)user
{
	controller.user = user;
}

-(void)setIsThumbnail:(BOOL)isThumbnail
{
	controller.isThumbnail = isThumbnail;
}

-(void)setDisplayAsCircle:(BOOL)flag
{
	displayAsCircle = flag;
	[self setNeedsLayout];
}

-(void)layoutSubviews
{
	if (!displayAsCircle)
		self.layer.cornerRadius = 0.0f;
	else
	{
		self.layer.cornerRadius = self.bounds.size.height * 0.5f;
		self.layer.masksToBounds = YES;
		self.layer.borderWidth = 0;
	}

	[super layoutSubviews];

	[controller layoutSubviews:self.bounds];
}

@end
