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
#import "NZParseImageUploader.h"
#import <yip-imports/ios/uuid.h>
#import <yip-imports/ios/UIImage+Resize.h>

@implementation NZParseImageUploader
{
	UIImage * image;
}

@synthesize imageQuality;
@synthesize thumbnailQuality;
@synthesize thumbnailWidth;
@synthesize thumbnailHeight;
@synthesize progressCallback;
@synthesize completionCallback;

-(id)initWithImage:(UIImage *)img
{
	self = [super init];
	if (self)
	{
		image = [img retain];
		imageQuality = 0.9f;
		thumbnailQuality = 0.6f;
		thumbnailWidth = 384;
		thumbnailHeight = 384;
	}
	return self;
}

-(void)dealloc
{
	[image release];
	image = nil;

	[progressCallback release];
	progressCallback = nil;

	[completionCallback release];
	completionCallback = nil;

	[super dealloc];
}

-(void)start
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		CGFloat thumbWidth = thumbnailWidth / image.scale;
		CGFloat thumbHeight = thumbnailHeight / image.scale;
		CGFloat width = image.size.width;
		CGFloat height = image.size.height;

		if (width > thumbWidth || height > thumbHeight)
		{
			CGFloat scaleX = thumbWidth / width;
			CGFloat scaleY = thumbHeight / height;
			CGFloat scale = MAX(scaleX, scaleY);

			width *= scale;
			height *= scale;
		}

		UIImage * thumb = [image resizedImage:CGSizeMake(width, height) interpolationQuality:kCGInterpolationHigh];
		NSData * imageData = UIImageJPEGRepresentation(image, imageQuality);
		NSData * thumbData = UIImageJPEGRepresentation(thumb, thumbnailQuality);

		NSString * imageId = iosGenerateUUID();
		NSString * thumbId = iosGenerateUUID();

		PFFile * imageFile = [PFFile fileWithName:imageId data:imageData];
		PFFile * thumbFile = [PFFile fileWithName:thumbId data:thumbData];

		[thumbFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError * error) {
			if (!succeeded || error)
			{
				if (completionCallback)
					completionCallback(nil, nil, nil, nil);
				return;
			}

			[imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError * error) {
				if (completionCallback)
				{
					if (!succeeded || error)
						completionCallback(nil, nil, nil, nil);
					else
						completionCallback(image, thumb, imageFile, thumbFile);
				}
			} progressBlock:^(int percentDone) {
				CGFloat progress = (CGFloat)percentDone / 100.0f * 0.7f + 0.3f;
				if (progressCallback)
					progressCallback(progress);
			}];
		} progressBlock:^(int percentDone) {
			CGFloat progress = (CGFloat)percentDone / 100.0f * 0.3f;
			if (progressCallback)
				progressCallback(progress);
		}];
	});
}

@end
