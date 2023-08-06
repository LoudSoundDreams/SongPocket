//
//  AlbumsTVC + OrganizeAlbumsDelegate.swift
//  LavaRock
//
//  Created by h on 2021-11-27.
//

extension AlbumsTVC: OrganizeAlbumsDelegate {
	func didOrganize() {
		let viewModel = viewModel.updatedWithFreshenedData() as! AlbumsViewModel // Shadowing so that we don’t accidentally refer to `self.viewModel`, which is incoherent at this point.
		let toKeepSelected = idsOfAlbumsToKeepSelected
		idsOfAlbumsToKeepSelected = []
		let toSelect = tableView.allIndexPaths().filter { someIndexPath in
			guard viewModel.pointsToSomeItem(row: someIndexPath.row) else {
				return false
			}
			let idOfAlbum = viewModel.albumNonNil(atRow: someIndexPath.row).objectID
			return toKeepSelected.contains(idOfAlbum)
		}
		Task {
			if toSelect.isEmpty {
				setEditing(false, animated: true)
			}
			
			let _ = await setViewModelAndMoveAndDeselectRowsAndShouldContinue(
				viewModel,
				thenSelecting: Set(toSelect)
			)
		}
	}
}
