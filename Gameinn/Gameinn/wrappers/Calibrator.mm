//
//  Calibrator.m
//  Gameinn
//
//  Created by Sebastian Kroszka on 02/09/2020.
//  Copyright © 2020 Embiq. All rights reserved.
//

#import "Calibrator.hpp"
#import "band.h"
#import <memory>
#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <MobileVLCKit/MobileVLCKit.h>
#import "Gameinn-Swift.h"

@implementation Calibrator {
    @private
    BandCalibrator *bandCalibrator;
}

- (Calibrator*) init {
    return self;
}

- (void) create {
    try {
        std::unique_ptr<BandCalibrator> p = BandCalibrator::create();
        bandCalibrator = p.release();
    } catch (...) {
        NSLog(@"%@", @"błąd");
    }
}

- (void) destroy {
    delete bandCalibrator;
    bandCalibrator = nullptr;
}

- (bool) isDone {
    return bandCalibrator->is_done();
}

- (bool) process:(BandData *)bandData {
    BandDevice::SensorData sensorData;
    
    if (!bandData) {
        return false;
    }
    
    sensorData.v.ax = (int) bandData.ax;
    sensorData.v.ay = (int) bandData.ay;
    sensorData.v.az = (int) bandData.az;
    sensorData.v.gx = (int) bandData.gx;
    sensorData.v.gy = (int) bandData.gy;
    sensorData.v.gz = (int) bandData.gz;
    sensorData.timestamp = (uint64_t) bandData.timestamp;
    
    return bandCalibrator->process(sensorData);
}

- (BandData *)getZeroOffset {
    BandData* data = [[BandData alloc] init];
    auto sd = bandCalibrator->zero_offset();
    
    data.ax = sd.ax;
    data.ay = sd.ay;
    data.az = sd.az;
    data.gx = sd.gx;
    data.gy = sd.gy;
    data.gz = sd.gz;
    
    return data;
}

- (UInt8)getCalibrationNeededMask {
    return bandCalibrator->calibration_needed_mask();
}

- (NSString *)getStatusString {
    return [NSString stringWithUTF8String:bandCalibrator->status().c_str()];
}

- (bool)isActive {
    return bandCalibrator != nullptr;
}

@end
