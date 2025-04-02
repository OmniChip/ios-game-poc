//
//  BandTableViewCell.swift
//  Gameinn
//
//  Created by Bartlomiej Burzec on 24/09/2020.
//  Copyright © 2020 Embiq. All rights reserved.
//

import UIKit

class BandTableViewCell: UITableViewCell {
    @IBOutlet weak var bandNameLabel: UILabel!
    @IBOutlet weak var accXLabel: UILabel!
    @IBOutlet weak var accYLabel: UILabel!
    @IBOutlet weak var accZLabel: UILabel!
    
    @IBOutlet weak var roatationXLabel: UILabel!
    @IBOutlet weak var roatationYLabel: UILabel!
    @IBOutlet weak var rotationZLabel: UILabel!
    
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var calibrationLabel: UILabel!
    @IBOutlet weak var associationLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func updateWithModel(_ model: Band) {
        self.bandNameLabel.text =  model.peripheral.name // TODO: check if it us correct, maybe identifier?
        if let data = model.lastData {
            self.accXLabel.text = String(data.ax)
            self.accYLabel.text = String(data.ay)
            self.accZLabel.text = String(data.az)
            
            self.roatationXLabel.text = String(data.gx)
            self.roatationYLabel.text = String(data.gz)
            self.rotationZLabel.text = String(data.gy)
            
            self.timestampLabel.text = String(data.timestamp)
            self.associationLabel.text = model.associationName()
            
            //TODO: replace with Android flow and logic
            self.calibrationLabel.text = model.calibrationStatus
            /* */
        }
    }
    

}
