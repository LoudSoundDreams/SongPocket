//
//  QueueViewHostingController.swift
//  LavaRock
//
//  Created by h on 2020-07-26.
//

import UIKit
import SwiftUI

class QueueViewHostingController: UIHostingController<QueueView> {
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder, rootView: QueueView())
	}

}
