'use strict';

import { NativeModules, DeviceEventEmitter } from 'react-native';
const NativeMusicControl = NativeModules.PlayerLockScreen;

/**
 * High-level docs for the MusicControl iOS API can be written here.
 */
var handlers = { };
var subscription = null;

var MusicControl = {
    setNowPlaying: function(info){
        NativeMusicControl.setNowPlayingTemp(info)
    }
};

module.exports = MusicControl;