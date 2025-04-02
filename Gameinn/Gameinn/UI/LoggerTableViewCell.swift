//
//  LoggerTableViewCell.swift
//  Gameinn
//
//  Created by Bartlomiej Burzec on 23/09/2020.
//  Copyright © 2020 Embiq. All rights reserved.
//

import UIKit

class LoggerTableViewCell: UITableViewCell {
    @IBOutlet weak var contentLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func updateWithLogModel(_ model: LogModel) {
        self.contentLabel.text = model.logContent
    }
    
}
