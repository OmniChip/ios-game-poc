//
//  Game.swift
//  Gameinn
//
//  Created by Sebastian Kroszka on 09/09/2020.
//  Copyright © 2020 Embiq. All rights reserved.
//

import Foundation
import CoreBluetooth

class Game: GameElement {
    var timer: Timer?
    var players = [Player]()
    var allowedExercises = Array<Int>()
    var allowedExercisesMask: UInt64 = 0
    var onGameOver: (() -> Void)? = nil
    var numberOfPlayers: Int {
        get {
            return self.players.count
        }
    }
    var isGameStarted = false

    var successfullyStarted = false
    var previousGesture = 0
    var numberOfHits = 0
    var numberOfRoundsLeft = 0
    let roundTimeInSeconds = 15

    var bands: [Band] = []
    var timingMaster: Band?
    var timesyncGroup: Data?

    var started: Bool {
        get {
            numberOfRoundsLeft > 0
        }
    }

    override init() {
        super.init()
        timesyncGroup = generateRandomBytes()
    }

    func generateRandomBytes() -> Data? {
        var bytes = [UInt8](repeating: 0, count: 5)
        let result = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)

        guard result == errSecSuccess else {
            print("Problem generating random bytes")
            return nil
        }

        return Data(bytes)
    }

    func addNewPlayer(with identifier: Int) {
        if identifier == 0 {
            return
        }
        let player = Player(identifier, mediator: self.mediator)
        self.players.append(player)
    }

    func onFoundBand(_ band: Band) {
        if self.bands.filter({ b -> Bool in return b.peripheral == band.peripheral }).isEmpty == false {
            return
        }

        bands.append(band)
        self.mediator?.send(command: .onBandsUpdated, sender: self, contextObject: nil)

        band.restartTimesync()
    }

    func onUpdateBandData(_ data: (device: CBPeripheral, data: Data)) {
        guard let bandToUpdate = getAssociatedBand(data.device) else {
            return
        }
        let newData = BandData(data: data.data)
        bandToUpdate.updateData(newData)

        if let player = getAssociatedPlayer(for: bandToUpdate) {
            player.updateData(bandToUpdate)
        }

        self.mediator?.send(command: .onBandsUpdated, sender: self, contextObject: nil)
    }

    func getAssociatedBand(_ peripheral: CBPeripheral) -> Band? {
        return self.bands.first { band -> Bool in
            return band.hasOwns(peripheral)
        }
    }

    func getAssociatedPlayer(for band: Band) -> Player? {
        return players.first { player -> Bool in
            player.isOwner(of: band)
        }
    }

    func getPlayerWithId(_ identifier: Int) -> Player? {
        return self.players.first { player -> Bool in
            return player.playerId == identifier
        }
    }

    func bindBandWithPlayer(_ band: Band, userId: Int) -> Bool {
        guard let player = getPlayerWithId(userId) else {
            return false
        }
        player.addBand(band: band)
        return true
    }

    func unbindBandFromUser(_ band: Band) {
        if let player = getAssociatedPlayer(for: band) {
            abortGame()
            player.removeBand(band: band)
        }
    }

    func removeBand(_ peripheral: CBPeripheral) {
        if let associatedBand = getAssociatedBand(peripheral) {
            removeBand(band: associatedBand)
        }
    }

    func abortGame() {
        if isGameStarted {
            isGameStarted = false
            mediator?.send(command: .logEvent, sender: self, contextObject: "\(Utility.currentDateToString()) Game::abortGame, game aborted" as AnyObject)
        }
    }

    func removeBand(band: Band) {
        mediator?.send(command: .logEvent, sender: self, contextObject: "\(Utility.currentDateToString()) Game::removeBand" as AnyObject)

        unbindBandFromUser(band)
        band.cleanup()

        self.bands.removeAll { b -> Bool in
            b.hasOwns(band.peripheral)
        }
        let tsMasterLost = band === timingMaster
        if tsMasterLost {
            timingMaster = nil
            var didOne = false
                for b in self.bands {
                    b.restartTimesync()
                    didOne = true
                }
            if didOne {
                timesyncGroup = generateRandomBytes()
            }
        }

        self.mediator?.send(command: .onBandsUpdated, sender: self, contextObject: nil)
    }

    func pruneBands() {
        mediator?.send(command: .logEvent, sender: self, contextObject: "\(Utility.currentDateToString()) Game::pruneBands" as AnyObject)
        var allExercises = allGesturesMask.rawValue
        self.players.forEach { player in
            //FIXME: hax ponieważ jeśli jest więcej playerów niż jeden to jego maska zawsze równa jest 0 co po & daje zero dla wszytskich uczestników gry
            if player.bands.isEmpty == false {
                allExercises = allExercises & player.availableGestures
            }
        }

        self.players.forEach { player in
            player.enableGestures(gestures: allExercises)
        }

        allowedExercises.removeAll()
        allowedExercises.append(contentsOf: allExercises.listOfBytes(mask: allExercises))
        allowedExercisesMask = allExercises
    }

    func getNextRandomGesture() -> Int {
        let prev = previousGesture
        let previousMask = UInt64(1 << prev)
        var invalidMask: UInt64
        if previousMask & pointGestureMask.rawValue != UInt64(0) {
            let shift = prev < pointLeftLegDown.rawValue ? 5 : 3
            let offset: Int = prev < pointLeftLegDown.rawValue ? Int(pointLeftHandDown.rawValue) : Int(pointLeftLegDown.rawValue)

            var sameLevelMask: UInt64
            if previousMask & pointAnyMask.rawValue != UInt64(0) {
                sameLevelMask = (UInt64(1) | (UInt64(1) << shift)) << (prev - offset - 2 * shift)
            } else {
                sameLevelMask = UInt64(1) << ((prev - offset) % shift + 2 * shift)
            }
            invalidMask = previousMask | sameLevelMask
        } else {
            invalidMask = previousMask
        }

        if allowedExercisesMask & ~invalidMask == UInt64(0) {
            return allowedExercises.randomElement()!
        }

        while true {
            let gesture = allowedExercises.randomElement()!
            if (UInt64(1) << UInt64(gesture) & invalidMask == UInt64(0)) {
                return gesture
            }
        }
    }

    func startNextRound(gesture: Int) {
        previousGesture = gesture

        players.forEach { player in
            player.reset(wanted: gesture)
        }
        numberOfHits = 0

        if self.timer == nil {
            self.timer = Timer.scheduledTimer(timeInterval: TimeInterval(self.roundTimeInSeconds), target: self, selector: #selector(timeout), userInfo: nil, repeats: false)
        }
    }

    func onPlayerHit(playerId: Int) {
        mediator?.send(command: .logEvent, sender: self, contextObject: "\(Utility.currentDateToString()) Game::onPlayerHit, player \(playerId) finished" as AnyObject)
        numberOfHits += 1
        if numberOfHits != numberOfPlayers {
            return
        }
        self.timer?.invalidate()
        self.timer = nil
        roundFinished()
    }

    func roundFinished() {
        var firstTimestamp: UInt64? = nil
        players.forEach { player in
            player.stopWaiting()
            player.hitTimestamp?.let { value in
                if firstTimestamp == nil || firstTimestamp! > value {
                    firstTimestamp = value
                }
            }
        }

//        if firstTimestamp == nil {
//            if isGameStarted {
//                mediator?.send(command: .logEvent, sender: self, contextObject: "\(Utility.currentDateToString()) Game::roundFinished with no matching gesture \n" as AnyObject)
//                let gesture = getNextRandomGesture()
//                mediator?.send(command: .logEvent, sender: self, contextObject: "\(Utility.currentDateToString()) Game::startNextRound, drawn gesture: \(gesture)" as AnyObject)
//                mediator?.send(command: .playExerciseSound, sender: self, contextObject: gesture as AnyObject)
//            }
//            return
//        }

        players.forEach { player in
            player.updateRoundStats(firstTimestamp: firstTimestamp ?? 0)
        }

        numberOfRoundsLeft -= 1
        if numberOfRoundsLeft > 0 {
            if isGameStarted {
                mediator?.send(command: .logEvent, sender: self, contextObject: "\(Utility.currentDateToString()) Game::roundFinished, rounds left: \(numberOfRoundsLeft) \n" as AnyObject)
                let gesture = getNextRandomGesture()
                mediator?.send(command: .logEvent, sender: self, contextObject: "\(Utility.currentDateToString()) Game::startNextRound, drawn gesture: \(getGestureName(gestureId: gesture))" as AnyObject)
                mediator?.send(command: .playExerciseSound, sender: self, contextObject: gesture as AnyObject)
            }
        } else {
            finishGame()
        }
    }

    func finishGame() {
        isGameStarted = false
        self.timer?.invalidate()
        self.timer = nil

        var bestPlayer: Player?
        var bestTimes: UInt64 = 0
        var bestCount = 0

        let betterPlayer: (Player) -> Bool = { player in
            if player.hitCompleted > bestCount {
                return true
            }
            if player.hitCompleted < bestCount {
                return false
            }
            return player.hitDelays < bestTimes
        }

        players.forEach { player in
            if betterPlayer(player) {
                bestPlayer = player
                bestTimes = player.hitDelays
                bestCount = player.hitCompleted
            }
        }

        guard let winner = bestPlayer else {
            mediator?.send(command: .logEvent, sender: self, contextObject: "\(Utility.currentDateToString()) Game::gameFinished, no one wins" as AnyObject)
            return
        }

        winner.vibeAll(vibes: getVibes(forWinner: true))

        mediator?.send(command: .logEvent, sender: self, contextObject: "\(Utility.currentDateToString()) Game::gameFinished, best player: \(winner.playerId)" as AnyObject)
        mediator?.send(command: .playPlayerWins, sender: self, contextObject: bestPlayer?.playerId as AnyObject)
    }

    override func receive(command: MediatorCommands, sender: AnyObject, contextObject: AnyObject?) {
        if command == .startGame {
            start()
        } else if command == .gestureDetected {
            onPlayerHit(playerId: contextObject as! Int)
        } else if command == .soundCompleted {
            if isGameStarted {
                startNextRound(gesture: contextObject as! Int)
            }
        }
    }

    func getVibes(forWinner: Bool) -> Data {
        var vibes = Data.init(repeating: 0x01, count: 8)
        if forWinner {
            vibes[2] = UInt8(0x8a)
            vibes[5] = UInt8(0x8a)
        }

        return vibes
    }

    func vibeBand(band: Band) {
        band.triggerVibe(vibes: getVibes(forWinner: false))
    }

    @objc func timeout() {
        self.timer?.invalidate()
        self.timer = nil
        roundFinished()
    }

    func start(rounds: Int = 5) {
        if checkConditionsToStartGame(rounds) {
            mediator?.send(command: .logEvent, sender: self, contextObject: "\(Utility.currentDateToString()) Game::start, started with: \(rounds) rounds" as AnyObject)
            successfullyStarted = true
            previousGesture = 0
            numberOfRoundsLeft = rounds
            isGameStarted = true
            let gesture = getNextRandomGesture()
            mediator?.send(command: .logEvent, sender: self, contextObject: "\(Utility.currentDateToString()) Game::startNextRound, drawn gesture: \(getGestureName(gestureId: gesture))" as AnyObject)
            mediator?.send(command: .playExerciseSound, sender: self, contextObject: gesture as AnyObject)
        }
    }

    func checkConditionsToStartGame(_ rounds: Int) -> Bool {
        if isGameStarted {
            mediator?.send(command: .logEvent, sender: self, contextObject: "\(Utility.currentDateToString()) Cannot start new game: game already started" as AnyObject)
            return false
        }
        if rounds <= 0 {
            mediator?.send(command: .logEvent, sender: self, contextObject: "\(Utility.currentDateToString()) Cannot start new game: actual number of rounds is insufficient" as AnyObject)
            return false
        }

        if numberOfPlayers == 0 {
            mediator?.send(command: .logEvent, sender: self, contextObject: "\(Utility.currentDateToString()) Cannot start new game: there are no players" as AnyObject)
            return false
        }

        var isAtLeastOneBandPresent = false
        players.forEach { player in
            if !player.bands.isEmpty {
                isAtLeastOneBandPresent = true
            }
        }
        if !isAtLeastOneBandPresent {
            mediator?.send(command: .logEvent, sender: self, contextObject: "\(Utility.currentDateToString()) Cannot start new game: no band associated with player present" as AnyObject)
            return false
        }
        pruneBands()
        if allowedExercises.isEmpty {
            mediator?.send(command: .logEvent, sender: self, contextObject: "\(Utility.currentDateToString()) Cannot start new game: no available exercises" as AnyObject)
            return false
        }
        return true
    }

    func cleanUp() {
        players.forEach { player in
            player.clean()
        }
        players.removeAll()
    }

    func getGestureName(gestureId: Int) -> String {
        switch gestureId {
        case 1:
            return "left hand down"
        case 2:
            return "left hand low"
        case 3:
            return "left hand level"
        case 4:
            return "left hand high"
        case 5:
            return "left hand up"
        case 6:
            return "right hand down"
        case 7:
            return "right hand low"
        case 8:
            return "right hand level"
        case 9:
            return "right hand high"
        case 10:
            return "right hand up"
        case 11:
            return "hand down"
        case 12:
            return "hand low"
        case 13:
            return "hand level"
        case 14:
            return "hand high"
        case 15:
            return "hand up"
        case 16:
            return "left leg down"
        case 17:
            return "left leg low"
        case 18:
            return "left leg level"
        case 19:
            return "right leg down"
        case 20:
            return "right leg low"
        case 21:
            return "right leg level"
        case 22:
            return "leg down"
        case 23:
            return "leg low"
        case 24:
            return "leg level"
        case 25:
            return "squat"
        case 26:
            return "steering wheel"
        case 27:
            return "guard up"
        case 28:
            return "guard down"
        case 29:
            return "punch"
        case 30:
            return "punch low"
        case 31:
            return "punch straight"
        case 32:
            return "punch high"
        case 33:
            return "left punch"
        case 34:
            return "left punch low"
        case 35:
            return "left punch straight"
        case 36:
            return "left punch high"
        case 37:
            return "right punch"
        case 38:
            return "right punch low"
        case 39:
            return "right punch straight"
        case 40:
            return "right punch high"
        default:
            return "none"
        }
    }
}
