/*

Copyright 2014 Sebible Limited

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

*/
#import "VideoSnapshot.h"

@implementation VideoSnapshot

- (NSString *)applicationDocumentsDirectory {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

-(UIImage *)drawTimestamp:(CMTime)timestamp withPrefix:(NSString*)prefix ofSize:(int)textSize toImage:(UIImage *)img{
	CGFloat w = img.size.width, h = img.size.height;
	CGFloat size = (CGFloat)(textSize * w) / 1280;
	CGFloat margin = (w < h? w : h) * 0.05;
	NSString* fontName = @"Helvetica";

	long timeMs = (long)(1000 * CMTimeGetSeconds(timestamp));
	int second = (timeMs / 1000) % 60;
	int minute = (timeMs / (1000 * 60)) % 60;
	int hour = (timeMs / (1000 * 60 * 60)) % 24;
	NSString* text = [NSString stringWithFormat:@"%@ %02d:%02d:%02d", prefix, hour, minute, second];
    //CGSize sizeText = [text sizeWithFont:[UIFont fontWithName:@"Helvetica" size:size] minFontSize:size actualFontSize:nil forWidth:783 lineBreakMode:NSLineBreakModeTailTruncation];
	UIFont* font = [UIFont fontWithName:fontName size:size];
	UIColor* color = [UIColor whiteColor];
	NSDictionary* attrs = [NSDictionary dictionaryWithObjectsAndKeys: font, NSFontAttributeName, color, NSForegroundColorAttributeName, nil];
	CGSize sizeText = CGSizeMake(0.0f, 0.0f);
	if ([text respondsToSelector:@selector(sizeWithAttributes)]) {
		sizeText = [text sizeWithAttributes:attrs];
	} else {
		sizeText = [text sizeWithFont:font];
	}

    CGFloat posX = w - margin - sizeText.width;
    CGFloat posY = h - margin - sizeText.height;
	NSLog(@"Drawing at (%f, %f) of size: %f. Image size: (%f, %f)", posX, posY, size, w, h);

    UIGraphicsBeginImageContextWithOptions(img.size, NO, 0.0f);
    [img drawAtPoint:CGPointMake(0.0f, 0.0f)];
	if ([text respondsToSelector:@selector(drawAtPoint:withAttributes:)]) {
    	[text drawAtPoint:CGPointMake(posX, posY) withAttributes:attrs];
	} else {
		CGContextRef context = UIGraphicsGetCurrentContext();
		CGContextSetFillColorWithColor(context, color.CGColor);
		[text drawAtPoint:CGPointMake(posX, posY) withFont:font];
	}
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return result;
} 

- (void)snapshot:(CDVInvokedUrlCommand*)command
{
    NSDictionary* options = [command.arguments objectAtIndex:0];
	NSLog(@"In plugin. Options:%@", options);

    if (options == nil) {
	    [self fail:command withMessage:@"No options provided"];
	    return;
    }

	int count = 1;
	int countPerMinute = 0;
	int textSize = 48;
	bool timestamp = true;
	float quality = 0.9f;
	NSString* prefix = @"";

    NSNumber* nscount = [options objectForKey:@"count"];
    NSNumber* nscountPerMinute = [options objectForKey:@"countPerMinute"];
    NSNumber* nstextSize = [options objectForKey:@"textSize"];
    NSString* source = [options objectForKey:@"source"];
	NSNumber* nstimestamp = [options objectForKey:@"timeStamp"];
	NSNumber* nsquality = [options objectForKey:@"quality"];
	NSString* nsprefix = [options objectForKey:@"prefix"];

    if (source == nil) {
    	[self fail:command withMessage:@"No source provided"];
    	return;
    }
	//source = [self.applicationDocumentsDirectory stringByAppendingPathComponent:@"test.mov"];

	if (nscount != nil) {
		count = [nscount intValue];
	}

	if (nscountPerMinute != nil) {
		countPerMinute = [nscountPerMinute intValue];
	}

	if (nstimestamp != nil) {
		timestamp = [nstimestamp boolValue];
	}

	if (nsquality != nil) {
		quality = (float)[nsquality intValue] / 100;
	}

	if (nsprefix != nil) {
		prefix = nsprefix;
	}

	if (nstextSize != nil) {
		textSize = [nstextSize intValue];
	}

    NSURL* url = [NSURL fileURLWithPath:source];
    if (url == nil) {
    	[self fail:command withMessage:@"Unable to open path"];
    	return;
    }

    NSString* filename = [url.lastPathComponent stringByReplacingOccurrencesOfString:@"." withString:@"_"];
    NSString* tmppath = NSTemporaryDirectory();
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url options:nil];
    AVAssetImageGenerator *generate = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generate.appliesPreferredTrackTransform = true;
    NSError *err = NULL;
	NSMutableArray* paths = [[NSMutableArray alloc] init];
	if (asset.duration.value == 0) {
    	[self fail:command withMessage:@"Unable to load video (duration == 0)"];
    	return;
    }

    Float64 duration = CMTimeGetSeconds(asset.duration);
	if (countPerMinute > 0) {
		count = countPerMinute * duration / 60;
	}
	if (count < 1) {
		count = 1;
	}
    Float64 delta = duration / (count + 1);
	if (delta < 1.f) {
		delta = 1.f;
	}

    NSMutableArray* times = [[NSMutableArray alloc] init];
    for (int i = 1; delta * i < duration && i <= count; i++) {
	    [times addObject:[NSValue valueWithCMTime:CMTimeMakeWithSeconds(delta * i, asset.duration.timescale)]];
	}

    [generate generateCGImagesAsynchronouslyForTimes:times completionHandler:^(CMTime requestedTime, CGImageRef image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error) {
	    NSLog(@"err==%@, imageRef==%@", err, image);
	    if (err != nil) {
	    	return;
	    }    

	   	int sec = (int)CMTimeGetSeconds(actualTime);
	    NSString* path = [tmppath stringByAppendingPathComponent: [NSString stringWithFormat:@"%@-snapshot%d.jpg", filename, sec]];
	    UIImage *uiImage = [UIImage imageWithCGImage:image];
		if (timestamp) {
			uiImage = [self drawTimestamp:actualTime withPrefix:prefix ofSize:textSize toImage:uiImage];
		}

		NSData *jpgData = UIImageJPEGRepresentation(uiImage, quality);
		[jpgData writeToFile:path atomically:NO];

		@synchronized (paths){
			[paths addObject:path];
			if (paths.count == times.count) {
				NSDictionary* ret = [NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithBool:true], @"result", paths, @"snapshots", nil];

				[self success:command withDictionary:ret];
			}
		}
		//CFRelease(image);
    }];
}

- (void)success:(CDVInvokedUrlCommand*)command withDictionary:(NSDictionary*)ret
{
	NSLog(@"Plugin success. Result: %@", ret);
	CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:ret];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];	
}

- (void)fail:(CDVInvokedUrlCommand*)command withMessage:(NSString*)message 
{
	NSLog(@"Plugin failed. Error: %@", message);
	NSDictionary* ret = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithBool:false], @"result", message, @"error", nil];
	CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:ret];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];	
}

@end
