Cordova Video Snapshot
======================

A cordova plugin for generating video snapshots

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


* **success**		success callback function. Will receive {"result": true, "snapshots": [absolute_path...]}
* **fail**		fail callback function with param error object or string
* **options**		options object. Possible keys:
    *							source: string, a file url of the source file
    *							count: int, count of snapshots that will be taken, default 1
    *							countPerMinute: int, if specified, count will be calculated according to the duration, default 0 (disabled)
    *							timeStamp: bool, add a timestamp at the lower-right corner, default true
    *							textSize: int, timestamp size, default 48
    *							prefix: string, optional text to print before timestamp
    *							quality: int 0<x<100, jpeg quality, default 90



License 
-------

Apache 2.0