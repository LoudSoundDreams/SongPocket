//
//  AlbumsTVC + AlbumOrganizerDelegate.swift
//  LavaRock
//
//  Created by h on 2021-11-27.
//

extension AlbumsTVC: AlbumOrganizerDelegate {
	
	final func didCommitOrganizeThenDismiss() {
		let newViewModel = viewModel.refreshed()
		setViewModelAndMoveRows(newViewModel)
	}
	
}
