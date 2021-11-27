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
		cancelHandler: (() -> Void)?,
		saveHandler: @escaping (_ textFieldText: String?) -> Void
	) -> Self {
		let dialog = Self(
			title: alertTitle,
			message: nil,
			preferredStyle: .alert)
		dialog.addTextFieldForEditingCollectionTitle(textFieldText: textFieldText)
		
		let cancelAction = UIAlertAction.cancel { _ in cancelHandler?() }
		let saveAction = UIAlertAction(
			title: LocalizedString.save,
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
	
	private func addTextFieldForEditingCollectionTitle(textFieldText: String?) {
		addTextField { textField in
			// UITextField
			textField.text = textFieldText
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
