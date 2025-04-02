//
//  Calibrator.h
//  Gameinn
//
//  Created by Sebastian Kroszka on 02/09/2020.
//  Copyright © 2020 Embiq. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BandData;

@interface Calibrator : NSObject
- (void) create;
- (void) destroy;
- (bool) process:(BandData*)bandData;
- (BandData*) getZeroOffset;
- (bool) isDone;
- (UInt8) getCalibrationNeededMask;
- (NSString*) getStatusString;
- (bool) isActive;
@end
