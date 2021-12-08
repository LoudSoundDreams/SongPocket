//
//  AlbumsTVC + OrganizeAlbumsDelegate.swift
//  LavaRock
//
//  Created by h on 2021-11-27.
//

extension AlbumsTVC: OrganizeAlbumsDelegate {
	
	final func didSaveOrganizeThenDismiss() {
		let viewModel = viewModel.updatedWithRefreshedData() as! AlbumsViewModel // Shadowing so that we don't accidentally refer to `self.viewModel`, which is incoherent at this point.
		let toKeepSelected = idsOfAlbumsToKeepSelected
		idsOfAlbumsToKeepSelected = []
		let toSelect = viewModel.indexPathsForAllItems().filter {
			let idOfAlbum = viewModel.albumNonNil(at: $0).objectID
			return toKeepSelected.contains(idOfAlbum)
		}
		setViewModelAndMoveRows(
			viewModel,
			andSelectRowsAt: Set(toSelect))
	}
	
}
