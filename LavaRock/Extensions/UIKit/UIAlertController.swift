//
//  UIAlertController.swift
//  LavaRock
//
//  Created by h on 2021-07-04.
//

import UIKit

extension UIAlertController {
	static func make_Rename_dialog(
		existing_title: String?,
		textFieldDelegate: UITextFieldDelegate,
		done_handler: @escaping (_ textFieldText: String?) -> Void
	) -> Self {
		let dialog = Self(
			title: LRString.renameFolder,
			message: nil,
			preferredStyle: .alert)
		dialog.addTextField { textField in
			// UITextField
			textField.text = existing_title
			textField.placeholder = existing_title
			textField.clearButtonMode = .always
			
			// UITextInputTraits
			textField.returnKeyType = .done
			textField.autocapitalizationType = .sentences
			textField.smartQuotesType = .yes
			textField.smartDashesType = .yes
			
			textField.delegate = textFieldDelegate
		}
		
		let cancelAction = UIAlertAction(title: LRString.cancel, style: .cancel)
		let saveAction = UIAlertAction(
			title: LRString.save,
			style: .default
		) { _ in
			let textFieldText = dialog.textFields?.first?.text
			done_handler(textFieldText)
		}
		
		dialog.addAction(cancelAction)
		dialog.addAction(saveAction)
		dialog.preferredAction = saveAction
		
		return dialog
	}
}
