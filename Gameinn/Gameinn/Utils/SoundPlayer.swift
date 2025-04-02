//
// Created by Sebastian Kroszka on 18/09/2020.
// Copyright (c) 2020 Embiq. All rights reserved.
//

import Foundation
import MobileVLCKit

class SoundPlayer: GameElement {
    var player = VLCMediaListPlayer()
    var queue = [String]()
    let pitchDown = 7
    var currentCommandId: Int = 0

    override init() {
        super.init()
        player.delegate = self
    }

    func playSound() {
        player.mediaList = VLCMediaList()
        queue.forEach { command in
            var url = Bundle.main.url(forResource: command, withExtension: "wav")
            var media = VLCMedia(url: url!)
            player.mediaList.add(media)
        }
        player.play()
        queue.removeAll()
    }

    func prepareExerciseQueue(commandId: Int) {
        var mask = UInt64(1) << commandId

        queue.append("simon-says")
        if commandId == squatGesture.rawValue {
            queue.append("squat")
        } else if mask & pointGestureMask.rawValue != UInt64(0) {
            if mask & pointLeftMask.rawValue != UInt64(0) {
                queue.append("left")
            } else if mask & pointRightMask.rawValue != UInt64(0) {
                queue.append("right")
            }

            if mask & pointArmMask.rawValue != UInt64(0) {
                queue.append("hand")
            } else if mask & pointLegMask.rawValue != UInt64(0) {
                queue.append("leg")
            }

            var pitch = 0
            if mask & pointArmMask.rawValue != UInt64(0) {
                pitch = (commandId - Int(pointLeftHandDown.rawValue)) % 5
            } else {
                pitch = (commandId - Int(pointLeftLegDown.rawValue)) % 3
            }

            switch pitch + pitchDown {
            case 7:
                queue.append("down")
            case 8:
                queue.append("low")
            case 9:
                queue.append("level")
            case 10:
                queue.append("high")
            case 11:
                queue.append("up")
            default:
                print("unsupported pitch value")
            }
        }

        playSound()
    }

    func playPlayerWins(playerNumber: Int) {
        queue.removeAll()
        switch playerNumber {
        case 1:
            queue.append("player-one")
        case 2:
            queue.append("player-two")
        case 3:
            queue.append("player-three")
        case 4:
            queue.append("player-four")
        default:
            print("wrong player number")
        }
        queue.append("wins")
        playSound()
    }

 

    override func receive(command: MediatorCommands, sender: AnyObject, contextObject: AnyObject?) {
        if command == .playExerciseSound {
            currentCommandId = contextObject as! Int
            prepareExerciseQueue(commandId: currentCommandId)
        } else if command == .playPlayerWins {
            playPlayerWins(playerNumber: contextObject as! Int)
        }
    }
}
extension SoundPlayer:  VLCMediaListPlayerDelegate  {
    func mediaListPlayerFinishedPlayback(_ player: VLCMediaListPlayer!) {
         print("\(Utility.currentDateToString()) sending soundCompleted command")
         player.stop()
         mediator?.send(command: .soundCompleted, sender: self, contextObject: currentCommandId as AnyObject)
     }
}
