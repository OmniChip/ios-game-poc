//
//  CPPWrapper.m
//  Gameinn
//
//  Created by Sebastian Kroszka on 21/08/2020.
//  Copyright © 2020 Embiq. All rights reserved.
//

#import "Detector.hpp"
#import "band.h"
#import <memory>
#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <MobileVLCKit/VLCMediaListPlayer.h>
#import "Gameinn-Swift.h"

@implementation Detector {
    @private
    BandDetector *bandDetector;
}

- (Detector*) init {
    return self;
}

- (void)create {
    std::unique_ptr<BandDetector> p = BandDetector::create();
    bandDetector = p.release();
}

- (void)destroy {
    delete bandDetector;
    bandDetector = nullptr;
}

- (UInt64)getGestures:(uint)bandMask {
    BandDetector::gesture_bitmap_t bm = bandDetector->get_gestures(bandMask);
    
    return bm.to_ullong();
}

- (void)enableGestures:(UInt64)mask {
    /* Creating bitset (std::bitset<__NUM_GESTURES>) from (long) mask */
    BandDetector::gesture_bitmap_t bitMap(mask);
    
    /* Passing expected type to badn detector */
    bandDetector->enable_gestures(bitMap);
}

- (NSMutableArray<GestureData *> *)process:(int)which with:(BandData *)bandData {
    if (!bandData) {
        return nullptr;
    }
    
    if (which < 0 || which > BandDetector::__NUM_LOCATIONS) {
        return nullptr;
    }
    
    BandDevice::SensorData sensorData;
    sensorData.v.ax = (int) bandData.ax;
    sensorData.v.ay = (int) bandData.ay;
    sensorData.v.az = (int) bandData.az;
    sensorData.v.gx = (int) bandData.gx;
    sensorData.v.gy = (int) bandData.gy;
    sensorData.v.gz = (int) bandData.gz;
    sensorData.timestamp = (uint64_t) bandData.timestamp;
    
    auto vs = bandDetector->process((BandDetector::BandLocation)which, sensorData);
    
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:vs.size()];
    for (const auto& g : vs) {
        GestureData* gd = [[GestureData alloc] init];
        gd.timestamp = g.timestamp;
        gd.type = g.type;
        gd.x = g.value.x;
        gd.y = g.value.y;
        gd.z = g.value.z;
        [array addObject:gd];
    }
    
    return array;
}

- (void)reset {
    bandDetector->reset();
}

@end
