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

//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//
//    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
