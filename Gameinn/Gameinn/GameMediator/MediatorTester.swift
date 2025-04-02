//
//  MediatorTester.swift
//  Gameinn
//
//  Created by Bartlomiej Burzec on 03/09/2020.
//  Copyright © 2020 Embiq. All rights reserved.
//

import Foundation

class MediatorTester: GameElement {
    
    override func receive(command: MediatorCommands, sender: AnyObject, contextObject: AnyObject?) {
        super.receive(command: command, sender: sender, contextObject: contextObject)
    }
    
    override func send(command: MediatorCommands, contextObject: AnyObject?) {
        super.send(command: command, contextObject: self)
        self.mediator!.send(command: command, sender: self, contextObject: contextObject)
        
    }
    
}
