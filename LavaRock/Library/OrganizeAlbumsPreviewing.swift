//
//  OrganizeAlbumsPreviewing.swift
//  LavaRock
//
//  Created by h on 2021-11-27.
//

import UIKit

@MainActor
protocol OrganizeAlbumsPreviewing: UIViewController {
	var viewModel: LibraryViewModel { get }
	var organizeAlbumsClipboard: OrganizeAlbumsClipboard? { get }
}
extension OrganizeAlbumsPreviewing {
	func commitOrganize() {
		guard
			let clipboard = organizeAlbumsClipboard,
			!clipboard.didAlreadyCommitOrganize
		else { return }
		
		clipboard.didAlreadyCommitOrganize = true
		
		viewModel.context.deleteEmptyCollections() // You must do this because when we previewed changes in the context, we didn’t delete the source folder even if we moved all the albums out of it.
		
		viewModel.context.tryToSave()
		viewModel.context.parent!.tryToSave()
		
		NotificationCenter.default.post(name: .LRUserUpdatedDatabase, object: nil)
		
		dismiss(animated: true)
		clipboard.delegate?.didOrganize()
	}
}
