//
//  extension UIAlertController.swift
//  LavaRock
//
//  Created by h on 2021-07-04.
//

import UIKit

extension UIAlertController {
	
	final func addTextFieldForCollectionTitle(
		defaultTitle: String?
	) {
		addTextField { textField in
			// UITextField
			textField.text = defaultTitle
			textField.placeholder = LocalizedString.title
			textField.clearButtonMode = .whileEditing
			
			// UITextInputTraits
			textField.returnKeyType = .done
			textField.autocapitalizationType = .sentences
			textField.smartQuotesType = .yes
			textField.smartDashesType = .yes
		}
	}
	
}
