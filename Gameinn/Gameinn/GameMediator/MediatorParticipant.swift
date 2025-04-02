//
//  MediatorComponent.swift
//  Gameinn
//
//  Created by Bartlomiej Burzec on 02/09/2020.
//  Copyright © 2020 Embiq. All rights reserved.
//

import Foundation
import UIKit

protocol MediatorParticipant: class {
    var mediator: Mediator? { get set }
    func send(command: MediatorCommands, contextObject: AnyObject?)
    func receive(command: MediatorCommands, sender: AnyObject, contextObject: AnyObject?)
    func register()
    func unregister()
}

class GameElement: NSObject, MediatorParticipant {
    
    weak var mediator: Mediator?
    
    var appDelegate: AppDelegate? {
          get {
              UIApplication.shared.delegate as? AppDelegate
          }
      }
    
    override init() {
        super.init()
    }
    
    init(_ mediator: Mediator?) {
        super.init()
        self.mediator = mediator
    }
    
    func send(command: MediatorCommands, contextObject: AnyObject?) {
        guard let _ = self.mediator else {
            print("[MED][\(self.className)] not regsiter a Mediator! ")
            return
        }
    }
    
    func receive(command: MediatorCommands, sender: AnyObject, contextObject: AnyObject?) {
        if appDelegate?.logMediatorCommands ?? false {
            print("[MED][\(self.className)] << rcv command: \(command) from: \(Utility.classNameAsString(sender)) \n object: \(contextObject ?? "NULL" as AnyObject)")
        }
    }
    
    func register() {
        self.mediator?.register(participant: self)
    }
    
    func unregister() {
        self.mediator?.unregister(participant: self)
    }
    
}

class GameBaseViewController: UIViewController, MediatorParticipant  {
    weak var mediator: Mediator?
    
    var appDelegate: AppDelegate? {
        get {
            UIApplication.shared.delegate as? AppDelegate
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            self.mediator = appDelegate.gameMediator
        }
    }
    
    func send(command: MediatorCommands, contextObject: AnyObject?) {}
    
    func receive(command: MediatorCommands, sender: AnyObject, contextObject: AnyObject?) {
        if appDelegate?.logMediatorCommands ?? false {
            print("[MED][\(self.className)] << rcv command: \(command) from: \(Utility.classNameAsString(sender)) \n object: \(contextObject ?? "NULL" as AnyObject)")
        }
    }
    
    func register() {
        self.mediator?.register(participant: self)
    }
    
    func unregister() {
        self.mediator?.unregister(participant: self)
    }
    
}
