//
//  AlbumsTVC + AlbumOrganizerDelegate.swift
//  LavaRock
//
//  Created by h on 2021-11-27.
//

extension AlbumsTVC: AlbumOrganizerDelegate {
	
	final func didCommitOrganizeThenDismiss() {
		let viewModel = viewModel.updatedWithRefreshedData() as! AlbumsViewModel // Shadowing so we don't accidentally refer to `self.viewModel`.
		let toKeepSelected = idsOfAlbumsToKeepSelected
		idsOfAlbumsToKeepSelected = []
		let indexPathsToSelect = Set(viewModel.indexPathsForAllItems().filter {
			let idOfAlbum = viewModel.albumNonNil(at: $0).objectID
			return toKeepSelected.contains(idOfAlbum)
		})
		setViewModelAndMoveRows(
			viewModel,
			andSelectRowsAt: indexPathsToSelect)
	}
	
}
