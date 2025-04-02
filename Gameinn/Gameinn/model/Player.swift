//
//  Player.swift
//  Gameinn
//
//  Created by Sebastian Kroszka on 03/09/2020.
//  Copyright © 2020 Embiq. All rights reserved.
//

import Foundation
import CoreBluetooth

class Player: GameElement {
    let detector = Detector()
    let playerId: Int
    var bands = [Band]()
    var hitTimestamp: UInt64? = nil
    var hitDelays: UInt64 = 0
    var hitCompleted = 0
    var wantedGestures: Int = 0
    
    var bandsPresent: UInt64 {
        get {
            return bands.reduce(0) { k, v in
                k | 1 << v.association
            }
        }
    }
    
    var availableGestures: UInt64 {
        get {
            detector.getGestures(uint(bandsPresent)) & allGesturesMask.rawValue
        }
    }

    init(_ playerId: Int, mediator: Mediator?) {
        self.playerId = playerId
        super.init()
        self.mediator = mediator
        detector.create()
    }
    
    func addBand(band: Band) {
        /* Remove band with same association as new */
        let colisionWithAssociation = bands.filter({ b -> Bool in b != band && b.association == band.association})
        colisionWithAssociation.forEach { b in removeBand(band: b) }
        /* */
        
        if self.bands.contains(band) == false {
            self.bands.append(band)
        }
    }

    func isOwner(of band: Band) -> Bool {
        return self.bands.contains { b -> Bool in
            b.hasOwns(band.peripheral)
        }
    }
    
    func updateData(_ band: Band) {
        guard let lastData = band.lastData else {
            return
        }

        if let gestures = detector.process(Int32(band.association), with: lastData) {
            for gestureData in gestures {
                if let gd = gestureData as? GestureData {
                    mediator?.send(command: .logEvent, sender: self, contextObject: "\(Utility.currentDateToString()) Player::updateData, detected gesture: \(appDelegate?.game.getGestureName(gestureId: gd.type) as! String)" as AnyObject)
                    checkGesture(gestureData: gd, timestamp: gd.timestamp - band.startTimestamp)
                }
            }
        }
    }
    
    func checkGesture(gestureData: GestureData, timestamp: UInt64) {
        if gestureData.type != self.wantedGestures {
            return
        }
        self.wantedGestures = 0
        self.hitTimestamp = timestamp
        
        mediator?.send(command: .gestureDetected, sender: self, contextObject: playerId as AnyObject)
    }
    
    func removeBand(band: Band) {
        if let bandToRemove = bands.first(where: {$0.hasOwns(band.peripheral) }) {
            //TODO: check if this is compatible with Android implementation
            bandToRemove.reset()
            bands.removeAll { b -> Bool in b.hasOwns(band.peripheral) }
        }
    }
    
    func enableGestures(gestures: UInt64) {
        detector.enableGestures(gestures)
    }
    
    func reset(wanted: Int) {
        self.wantedGestures = wanted
        self.hitTimestamp = nil
        for band in self.bands {
            //TODO: check if it works with reseting timestamp
            band.resetTS()
        }
        self.detector.reset()
    }
    
    func stopWaiting() {
        self.wantedGestures = 0
    }
    
    func updateRoundStats(firstTimestamp: UInt64) {
        let hit = hitTimestamp
        if hit == nil {
            return
        }
        
        hitDelays += hit! - firstTimestamp
        hitCompleted += 1
    }
    
    func clean() {
        bands.removeAll()
        detector.destroy()
    }
    
    func vibeAll(vibes: Data) {
        for band in bands {
            band.triggerVibe(vibes: vibes)
        }
    }
}

//FIXME: check and remove if it is not needed anymore

//typealias PlayerGestureCallback = (PlayerBandState, BandData) -> Void

// FIxME: Czy to jest nam potrzebne?
//class PlayerBandState {
//    var band: Band
//    var calibrationData: PlayerGestureCallback?
//    var onSavedNewData: BandDataCallback?
//    var lastTimestamp: UInt64 = 0
//    var startTimestamp: UInt64 = 0
//
//    init(band: Band) {
//        self.band = band
//    }
//
//    func clean() {
//        band.onNewData = onSavedNewData
//    }
//
//    func reset() {
//        startTimestamp = lastTimestamp
//    }
//}
