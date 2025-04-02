//
//  Utils.swift
//  Gameinn
//
//  Created by Bartlomiej Burzec on 03/09/2020.
//  Copyright © 2020 Embiq. All rights reserved.
//

import Foundation

extension NSObject {
    var className: String {
        NSStringFromClass(type(of: self))
    }
}

class Utility {
    class func classNameAsString(_ obj: Any) -> String {
        String(describing: type(of: obj))
    }

    class func currentDateToString() -> String {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"

        return formatter.string(from: date)
    }
}
