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
#import "NZParseAvatar.h"
#import <yip-imports/ios/image.h>
#import <yip-imports/ios/uuid.h>
#import <yip-imports/ios/UIImage+Resize.h>

static NSMutableSet * g_AvatarListeners;
static NSMutableDictionary * g_UploadingUsers;
static NSMutableDictionary * g_DownloadingUsers;
static CGFloat g_ThumbnailWidth = 384;
static CGFloat g_ThumbnailHeight = 384;
static long long g_SerialID = 0;

@implementation NZParseAvatar

+(void)setThumbnailWidth:(int)width height:(int)height
{
	g_ThumbnailWidth = (CGFloat)width;
	g_ThumbnailHeight = (CGFloat)height;
}

+(void)addListener:(id<NZParseAvatarListener>)listener
{
	if (!g_AvatarListeners)
		g_AvatarListeners = [[NSMutableSet alloc] init];
	[g_AvatarListeners addObject:listener];
}

+(void)removeListener:(id<NZParseAvatarListener>)listener
{
	if (g_AvatarListeners)
	{
		[g_AvatarListeners removeObject:listener];
		if (g_AvatarListeners.count == 0)
		{
			[g_AvatarListeners release];
			g_AvatarListeners = nil;
		}
	}
}

+(int)isUploadingForUser:(PFUser *)user
{
	return [g_UploadingUsers[user.objectId] intValue];
}

+(int)isDownloadingForUser:(PFUser *)user
{
	return [g_DownloadingUsers[user.objectId] intValue];
}

+(void)downloadForUser:(PFUser *)user thumbnail:(BOOL)thumb
{
	long long requestID = g_SerialID++;

	if (!g_DownloadingUsers)
		g_DownloadingUsers = [[NSMutableDictionary alloc] init];
	int numDownloading = [g_DownloadingUsers[user.objectId] intValue];
	g_DownloadingUsers[user.objectId] = @(numDownloading + 1);

	for (id<NZParseAvatarListener> listener in g_AvatarListeners)
		[listener onBeginDownloadingAvatarForUser:user requestID:requestID];

	void (^ callback)(UIImage * image) = ^(UIImage * image) {
		int numDownloading = [g_DownloadingUsers[user.objectId] intValue];
		if (--numDownloading > 0)
			g_DownloadingUsers[user.objectId] = @(numDownloading);
		else
			[g_DownloadingUsers removeObjectForKey:user.objectId];
		if (g_DownloadingUsers.count == 0)
		{
			[g_DownloadingUsers release];
			g_DownloadingUsers = nil;
		}
		for (id<NZParseAvatarListener> listener in g_AvatarListeners)
			[listener onEndDownloadingAvatarForUser:user image:image isThumbnail:thumb requestID:requestID];
	};

	@try
	{
		PFFile * file = (thumb ? user[@"avatarThumbImage"] : user[@"avatarImage"]);
		if (file)
		{
			[file getDataInBackgroundWithBlock:^(NSData * data, NSError * error) {
				if (error || !data)
					callback(nil);
				else
					iosAsyncDecodeImage(data, callback);
			}];
			return;
		}
	}
	@catch (id e)
	{
		NSLog(@"Unable to fetch avatar data from PFUser: %@", e);
	}

	@try
	{
		if ([user[@"facebookAvatarURL"] length])
		{
			iosAsyncDownloadImage(user[@"facebookAvatarURL"], callback);
			return;
		}
	}
	@catch (id e)
	{
		NSLog(@"Unable to fetch Facebook avatar data from PFUser: %@", e);
	}

	@try
	{
		if ([user[@"twitterAvatarURL"] length])
		{
			iosAsyncDownloadImage(user[@"twitterAvatarURL"], callback);
			return;
		}
	}
	@catch (id e)
	{
		NSLog(@"Unable to fetch Twitter avatar data from PFUser: %@", e);
	}

	@try
	{
		if ([user[@"vkAvatarURL"] length])
		{
			iosAsyncDownloadImage(user[@"vkAvatarURL"], callback);
			return;
		}
	}
	@catch (id e)
	{
		NSLog(@"Unable to fetch VK avatar data from PFUser: %@", e);
	}

	callback(nil);
}

+(void)upload:(UIImage *)image forUser:(PFUser *)user
{
	long long requestID = g_SerialID++;

	if (!g_UploadingUsers)
		g_UploadingUsers = [[NSMutableDictionary alloc] init];
	int numUploading = [g_UploadingUsers[user.objectId] intValue];
	g_UploadingUsers[user.objectId] = @(numUploading + 1);

	for (id<NZParseAvatarListener> listener in g_AvatarListeners)
		[listener onBeginUploadingAvatarForUser:user requestID:requestID];

	void (^ callback)(UIImage * image, UIImage * thumb) = ^(UIImage * image, UIImage * thumb) {
		int numUploading = [g_UploadingUsers[user.objectId] intValue];
		if (--numUploading > 0)
			g_UploadingUsers[user.objectId] = @(numUploading);
		else
			[g_UploadingUsers removeObjectForKey:user.objectId];
		if (g_UploadingUsers.count == 0)
		{
			[g_UploadingUsers release];
			g_UploadingUsers = nil;
		}
		for (id<NZParseAvatarListener> listener in g_AvatarListeners)
			[listener onEndUploadingAvatarForUser:user image:image thumbnail:thumb requestID:requestID];
	};

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		CGFloat thumbnailWidth = g_ThumbnailWidth / image.scale;
		CGFloat thumbnailHeight = g_ThumbnailHeight / image.scale;
		CGFloat width = image.size.width;
		CGFloat height = image.size.height;

		if (width > thumbnailWidth || height > thumbnailHeight)
		{
			CGFloat scaleX = thumbnailWidth / width;
			CGFloat scaleY = thumbnailHeight / height;
			CGFloat scale = MAX(scaleX, scaleY);

			width *= scale;
			height *= scale;
		}

		UIImage * thumb = [image resizedImage:CGSizeMake(width, height) interpolationQuality:kCGInterpolationHigh];
		NSData * imageData = UIImageJPEGRepresentation(image, 0.9f);
		NSData * thumbData = UIImageJPEGRepresentation(thumb, 0.6f);

		NSString * imageId = iosGenerateUUID();
		NSString * thumbId = iosGenerateUUID();

		PFFile * imageFile = [PFFile fileWithName:imageId data:imageData];
		PFFile * thumbFile = [PFFile fileWithName:thumbId data:thumbData];

		[thumbFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError * error) {
			if (!succeeded || error)
			{
				callback(nil, nil);
				return;
			}

			[imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError * error) {
				if (!succeeded || error)
				{
					callback(nil, nil);
					return;
				}

				@try
				{
					user[@"avatarThumbImage"] = thumbFile;
					user[@"avatarImage"] = imageFile;
				}
				@catch (id e)
				{
					NSLog(@"Unable to store avatar data in PFUser: %@", e);
					callback(nil, nil);
					return;
				}

				[user saveInBackgroundWithBlock:^(BOOL succeeded, NSError * error) {
					if (!succeeded || error)
					{
						callback(nil, nil);
						return;
					}

					callback(image, thumb);
				}];
			} progressBlock:^(int percentDone) {
				float progress = (float)percentDone / 100.0f * 0.7f + 0.3f;
				for (id<NZParseAvatarListener> listener in g_AvatarListeners)
					[listener onContinueUploadingAvatarForUser:user progress:progress requestID:requestID];
			}];
		} progressBlock:^(int percentDone) {
			float progress = (float)percentDone / 100.0f * 0.7f + 0.3f;
			for (id<NZParseAvatarListener> listener in g_AvatarListeners)
				[listener onContinueUploadingAvatarForUser:user progress:progress requestID:requestID];
		}];
	});
}

@end
