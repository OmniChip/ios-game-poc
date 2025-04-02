//
//  AppDelegate.swift
//  Gameinn
//
//  Created by Sebastian Kroszka on 05/08/2020.
//  Copyright © 2020 Embiq. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    let gameMediator = GameMediator()
    let game = Game()
    let soundPlayer = SoundPlayer()
    let btManager = BluetoothManager.shared()
    
    let logMediatorCommands = false
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch
        game.mediator = self.gameMediator
        game.register()
        btManager.mediator = self.gameMediator
        btManager.register()
        soundPlayer.mediator = self.gameMediator
        soundPlayer.register()
        
        /* Creating Players */
        game.addNewPlayer(with: 1)
        game.addNewPlayer(with: 2)
        game.addNewPlayer(with: 3)
        game.addNewPlayer(with: 4)
        /*  */
        
        return true
    }
}

