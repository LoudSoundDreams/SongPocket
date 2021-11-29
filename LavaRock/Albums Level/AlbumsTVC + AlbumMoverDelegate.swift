//
//  AlbumsTVC + AlbumMoverDelegate.swift
//  LavaRock
//
//  Created by h on 2020-09-16.
//

extension AlbumsTVC: AlbumMoverDelegate {
	
	// Similar to `LibraryTVC.refreshLibraryItemsPart2`.
	// Call this from the modal `AlbumsTVC` in the “move albums” sheet after completing the animation for inserting the `Album`s we moved. This instance here, the non-modal `AlbumsTVC`, should be the modal `AlbumsTVC`’s delegate, and this method removes the rows for those `Album`s.
	// That timing looks good: we remove the `Album`s while dismissing the sheet, so you catch just a glimpse of the `Album`s disappearing, even though it technically doesn’t make sense.
	final func didMoveThenDismiss() {
		let newViewModel = viewModel.updatedWithRefreshedData()
		setViewModelAndMoveRows(newViewModel)
	}
	
}

