//
//  protocol OrganizeAlbumsPreviewing.swift
//  LavaRock
//
//  Created by h on 2021-11-27.
//

import UIKit

protocol OrganizeAlbumsPreviewing: UIViewController {
	var viewModel: LibraryViewModel { get }
	var organizeAlbumsClipboard: OrganizeAlbumsClipboard? { get }
}

extension OrganizeAlbumsPreviewing {
	
	func makeSaveOrganizeButton() -> UIBarButtonItem {
		let action = UIAction { _ in self.commitOrganize() }
		let button = UIBarButtonItem(
			systemItem: .save,
			primaryAction: action)
		button.style = .done
		return button
	}
	
	private func commitOrganize() {
		guard
			let clipboard = organizeAlbumsClipboard,
			!clipboard.didAlreadyCommitOrganize
		else { return }
		
		clipboard.didAlreadyCommitOrganize = true
		
		Collection.deleteAllEmpty(via: viewModel.context)
		
		viewModel.context.tryToSave()
		viewModel.context.parent!.tryToSave()
		
		NotificationCenter.default.post(
			Notification(name: .LRUserDidUpdateDatabase)
		)
		
		dismiss(animated: true)
		clipboard.delegate?.didSaveOrganizeThenDismiss()
	}
	
}
