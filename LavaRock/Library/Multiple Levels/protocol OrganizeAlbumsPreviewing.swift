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
		let button = UIBarButtonItem(
			systemItem: .save,
			primaryAction: UIAction { [weak self] _ in self?.commitOrganize() })
		button.style = .done
		return button
	}
	
	private func commitOrganize() {
		guard
			let clipboard = organizeAlbumsClipboard,
			!clipboard.didAlreadyCommitOrganize
		else { return }
		
		clipboard.didAlreadyCommitOrganize = true
		
		Collection.deleteAllEmpty(via: viewModel.context) // You must do this because when we previewed changes in the context, we didn’t delete the source `Collection` even if we moved all the `Album`s out of it.
		
		viewModel.context.tryToSave()
		viewModel.context.parent!.tryToSave()
		
		NotificationCenter.default.post(
			name: .LRUserDidUpdateDatabase,
			object: nil)
		
		dismiss(animated: true)
		clipboard.delegate?.didOrganize()
	}
}
