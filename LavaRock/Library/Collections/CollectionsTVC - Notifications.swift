//
//  CollectionsTVC - Notifications.swift
//  LavaRock
//
//  Created by h on 2020-09-10.
//

import UIKit
import SwiftUI

extension CollectionsTVC {
	// MARK: Library Items
	
	final override func shouldDismissAllViewControllersBeforeFreshenLibraryItems() -> Bool {
		if
			(presentedViewController as? UINavigationController)?.viewControllers.first is OptionsTVC
				|| presentedViewController is UIHostingController<OptionsView>
		{
			return false
		}
		
		return super.shouldDismissAllViewControllersBeforeFreshenLibraryItems()
	}
	
	final override func freshenLibraryItems() {
		switch purpose {
		case .willOrganizeAlbums:
			return
		case .organizingAlbums:
			return
		case .movingAlbums:
			return
		case .browsing:
			break
		}
		
		switch viewState {
		case
				.loading,
				.noCollections:
			// We have placeholder rows in the Collections section. Remove them before `LibraryTVC` calls `setItemsAndMoveRows`.
			needsRemoveRowsInCollectionsSection = true // `viewState` is now `.wasLoadingOrNoCollections`
			reflectViewState()
			needsRemoveRowsInCollectionsSection = false // WARNING: `viewState` is now `.loading` or `.noCollections`, but the UI doesn’t reflect that.
		case
				.allowAccess,
				.wasLoadingOrNoCollections,
				.someCollections:
			break
		}
		
		if viewModelBeforeCombining != nil {
			revertCombine(thenSelect: [])
		}
		
		super.freshenLibraryItems()
	}
}
