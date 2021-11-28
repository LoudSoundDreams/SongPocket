//
//  protocol AlbumOrganizer.swift
//  LavaRock
//
//  Created by h on 2021-11-27.
//

import UIKit

protocol AlbumOrganizer: UIViewController {
	var viewModel: LibraryViewModel { get }
	var albumOrganizerClipboard: AlbumOrganizerClipboard? { get }
}

extension AlbumOrganizer {
	
	func makeCommitOrganizeButton() -> UIBarButtonItem {
		let action = UIAction { _ in self.commitOrganize() }
		let button = UIBarButtonItem(
			systemItem: .save,
			primaryAction: action)
		button.style = .done
		return button
	}
	
	func commitOrganize() {
		guard
			let clipboard = albumOrganizerClipboard,
			!clipboard.didAlreadyCommitOrganize
		else { return }
		
		clipboard.didAlreadyCommitOrganize = true
		
		viewModel.context.tryToSave()
		viewModel.context.parent!.tryToSave()
		
		NotificationCenter.default.post(
			Notification(name: .LRUserDidUpdateDatabase)
		)
		
		dismiss(animated: true)
		clipboard.delegate?.didCommitOrganizeThenDismiss()
	}
	
}
