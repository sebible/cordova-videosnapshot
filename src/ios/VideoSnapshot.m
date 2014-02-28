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
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@implementation VideoSnapshot

- (void)snapshot:(CDVInvokedUrlCommand*)command
{
    NSDictionary* options = [command.arguments objectAtIndex:0];

    if (options == nil) {
	    [self fail:command withMessage:@"No options provided"];
	    return;
    }

    NSNumber* nscount = [options objectForKey:@"count"];
	int count = 1;
    NSString* source = [options objectForKey:@"source"];

    if (source == nil) {
    	[self fail:command withMessage:@"No source provided"];
    	return;
    }

	if (nscount != nil) {
		count = [nscount intValue];
	}

    NSURL* url = [NSURL URLWithString:source relativeToURL:nil];
    if (url == nil) {
    	[self fail:command withMessage:@"Unable to open url"];
    	return;
    }

    NSString* filename = [url.lastPathComponent stringByReplacingOccurrencesOfString:@"." withString:@"_"];
    NSString* tmppath = NSTemporaryDirectory();
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url options:nil];
    AVAssetImageGenerator *generate = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    NSError *err = NULL;
	NSMutableArray* paths = [[NSMutableArray alloc] init];
	if (asset.duration.value == 0) {
    	[self fail:command withMessage:@"Unable to load video (duration == 0)"];
    	return;
    }

    Float64 duration = CMTimeGetSeconds(asset.duration);
    Float64 delta = duration / (count + 1);

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
		NSData *jpgData = UIImageJPEGRepresentation(uiImage, 0.9f);
		[jpgData writeToFile:path atomically:NO];

		[paths addObject:path];
		CFRelease(image);
    }];
	
	NSDictionary* ret = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithBool:true], @"result", paths, @"paths", nil];

	[self success:command withDictionary:ret];
}

- (void)success:(CDVInvokedUrlCommand*)command withDictionary:(NSDictionary*)ret
{
	CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:ret];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];	
}

- (void)fail:(CDVInvokedUrlCommand*)command withMessage:(NSString*)message 
{
	NSDictionary* ret = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithBool:false], @"result", message, @"error", nil];
	CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:ret];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];	
}

@end
