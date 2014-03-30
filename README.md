Cordova Video Snapshot
======================

A cordova plugin for generating video snapshots.

Platforms
---------

* Android
* IOS

Installation
------------

Install with `cordova plugin` or `plugman`. The javascript module will be injected automatically.

Usage
-----

`window.sebible.videosnapshot.snapshot(success, fail, options)`

Take snapshots of a video. 

Time points will be calculated automatically according to the count of shots specified by user 
and the duration of the video. 

All processing is done on worker threads so no blocking on the javascript thread and it's pretty fast!


* **success**    	success callback function. Will receive {"result": true, "snapshots": [absolute_path...]}
* **fail**		fail callback function with param error object or string
* **options**		options object. Possible keys:
    *							source: string, a file url of the source file
    *							count: int, count of snapshots that will be taken, default 1
    *							countPerMinute: int, if specified, count will be calculated according to the duration, default 0 (disabled)
    *							timeStamp: bool, add a timestamp at the lower-right corner, default true
    *							textSize: int, relative timestamp size, default (48 * video_width / 1280)
    *							prefix: string, optional text to print before timestamp
    *							quality: int 0<x<100, jpeg quality, default 90

Example
-------

    function success(result) {
        if (result && result.result) {
            for (var i in result.snapshots) {
                var absfilepath = result.snapshots[i];
                // Do whatever you want with absfilepath
                // Maybe assign to a img
                // $("<img>").attr("src", absfilepath).appendTo("body");
            }
        }
    }
    
    function fail(err) {
        console.log(err);
    }
    
    // This generates 3 snapshots of the source video no matter what its duration is (with timestamps printed at the lower right)
    var options = {
        source: "file:///mnt/sdcard/DCIM/Camera/0.mp4",
        count: 3,
        timeStamp: true
    }

    sebible.videosnapshot.snapshot(success, fail, options);

    // This generates 3 snapshots for every minute of the source video (with timestamps as well).
    var options2 = {
        source: "file:///mnt/sdcard/DCIM/Camera/0.mp4",
        countPerMinute: 3,
        timeStamp: true
    }
    
    sebible.videosnapshot.snapshot(success, fail, options2);

License 
-------

Apache 2.0