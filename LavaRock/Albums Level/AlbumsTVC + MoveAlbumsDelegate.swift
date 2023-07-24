//
//  AlbumsTVC + MoveAlbumsDelegate.swift
//  LavaRock
//
//  Created by h on 2020-09-16.
//

extension AlbumsTVC: MoveAlbumsDelegate {
	// Similar to `freshenLibraryItems`.
	// Call this from the modal `AlbumsTVC` in the “move albums” sheet after completing the animation for inserting the `Album`s we moved. This instance here, the base-level `AlbumsTVC`, should be the modal `AlbumsTVC`’s delegate, and this method removes the rows for those `Album`s.
	// That timing looks good: we remove the `Album`s while dismissing the sheet, so you catch just a glimpse of the `Album`s disappearing, even though it technically doesn’t make sense.
	func didMove() {
		let newViewModel = viewModel.updatedWithFreshenedData()
		Task {
			setEditing(false, animated: true)
			
			let _ = await setViewModelAndMoveAndDeselectRowsAndShouldContinue(newViewModel)
		}
	}
}