//
//  CPPWrapper.h
//  Gameinn
//
//  Created by Sebastian Kroszka on 21/08/2020.
//  Copyright © 2020 Embiq. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BandData;
@class GestureData;


typedef enum : UInt64 {
    pointLeftHandDown = 1,
    pointLeftLegDown = 16,
    squatGesture = 25,
    steeringWheel = 26,
    punch = 29,
    
    pointGestureMask = 0x1fffffe,
    pointAnyMask = 0x1c0f800,
    squatGestureMask = 1 << squatGesture,
    steeringWheelMask = 1 << steeringWheel,
    punchesMask = (UInt64) 0x111 << punch,
    continuousGesturesMask = steeringWheelMask | punchesMask,
    allGesturesMask = pointGestureMask | squatGestureMask,
    
    pointLeftMask = 0x7003e,
    pointRightMask = 0x3807c0,
    pointArmMask = 0xfffe,
    pointLegMask = 0x1ff0000
} Masks;

@interface Detector : NSObject

- (void) create;
- (void) destroy;
- (UInt64) getGestures:(uint)bandMask;
- (void) enableGestures:(UInt64)mask;
- (NSMutableArray<GestureData *>*) process:(int)which with:(BandData*)bandData;
- (void) reset;

@end
