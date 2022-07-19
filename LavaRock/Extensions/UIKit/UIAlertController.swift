//
//  UIAlertController.swift
//  LavaRock
//
//  Created by h on 2021-07-04.
//

import UIKit

extension UIAlertController {
	static func forEditingCollectionTitle(
		alertTitle: String,
		textFieldText: String?,
		textFieldDelegate: UITextFieldDelegate?,
		cancelHandler: (() -> Void)?,
		saveHandler: @escaping (_ textFieldText: String?) -> Void
	) -> Self {
		let dialog = Self(
			title: alertTitle,
			message: nil,
			preferredStyle: .alert)
		dialog.addTextField { textField in
			// UITextField
			textField.text = textFieldText
			textField.placeholder = LRString.title
			textField.clearButtonMode = .always
			
			// UITextInputTraits
			textField.returnKeyType = .done
			textField.autocapitalizationType = .sentences
			textField.smartQuotesType = .yes
			textField.smartDashesType = .yes
			
			textField.delegate = textFieldDelegate
		}
		
		let cancelAction = UIAlertAction.cancelWithHandler { _ in cancelHandler?() }
		let saveAction = UIAlertAction(
			title: LRString.save,
			style: .default
		) { _ in
			let textFieldText = dialog.textFields?.first?.text
			saveHandler(textFieldText)
		}
		
		dialog.addAction(cancelAction)
		dialog.addAction(saveAction)
		dialog.preferredAction = saveAction
		
		return dialog
	}
}
