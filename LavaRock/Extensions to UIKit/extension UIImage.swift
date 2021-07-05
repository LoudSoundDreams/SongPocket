//
//  extension UIImage.swift
//  LavaRock
//
//  Created by h on 2021-07-04.
//

import UIKit

extension UIImage {
	
	static let floatToTopSymbol: UIImage? = {
		if #available(iOS 15, *) {
			return UIImage(systemName: "arrow.up.to.line.compact") // As of iOS 15, this is the vertically short one; .alt doesn't exist anymore; arrow.up.to.line is the taller one
		} else { // iOS 14 and earlier
			return UIImage(systemName: "arrow.up.to.line") // As of iOS 14 and earlier, this is the vertically short one; .alt is taller; .compact doesn't exist yet
		}
	}()
	
	static let sinkToBottomSymbol: UIImage? = {
		if #available(iOS 15, *) {
			return UIImage(systemName: "arrow.down.to.line.compact")
		} else { // iOS 14 and earlier
			return UIImage(systemName: "arrow.down.to.line")
		}
	}()
	
}
