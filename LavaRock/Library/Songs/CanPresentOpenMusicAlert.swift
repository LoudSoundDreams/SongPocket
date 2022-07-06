//
//  CanPresentOpenMusicAlert.swift
//  LavaRock
//
//  Created by h on 2022-07-06.
//

import UIKit

protocol CanPresentOpenMusicAlert: UIViewController {
	func maybeAlertOpenMusic(
		willPlayNextAsOpposedToLast: Bool,
		havingVerbedSongCount songCount: Int,
		firstSongTitle: String)
}

extension SongsTVC: CanPresentOpenMusicAlert {
	func maybeAlertOpenMusic(
		willPlayNextAsOpposedToLast: Bool,
		havingVerbedSongCount songCount: Int,
		firstSongTitle: String
	) {
		if Enabling.console {
			return
		}
		
		let defaults = UserDefaults.standard
		let defaultsKey = LRUserDefaultsKey.shouldExplainQueueAction.rawValue
		
		defaults.register(defaults: [defaultsKey: true])
		guard defaults.bool(forKey: defaultsKey) else { return }
		
		let dontShowAgainAction = UIAlertAction(
			title: LocalizedString.dontShowAgain,
			style: .default
		) { _ in
			self.willPlayLaterAlertIsPresented = false
			defaults.set(
				false,
				forKey: defaultsKey)
		}
		let openMusicAction = UIAlertAction(
			title: LocalizedString.openMusic,
			style: .default
		) { _ in
			UIApplication.shared.open(.music)
		}
		let okAction = UIAlertAction(
			title: LocalizedString.ok,
			style: .default
		) { _ in
			self.willPlayLaterAlertIsPresented = false
		}
		
		let alert = UIAlertController(
			title: {
				if songCount == 1 {
					// No plural rules required.
					let formatString: String
					if willPlayNextAsOpposedToLast {
						formatString = LocalizedString.format_didPrependOneSong
					} else {
						formatString = LocalizedString.format_didAppendOneSong
					}
					return String.localizedStringWithFormat(
						formatString,
						firstSongTitle)
				} else {
					// Plural rules required.
					let formatString: String
					if willPlayNextAsOpposedToLast {
						formatString = LocalizedString.format_didPrependMultipleSongs
					} else {
						formatString = LocalizedString.format_didAppendMultipleSongs
					}
					return String.localizedStringWithFormat(
						formatString,
						firstSongTitle,
						songCount - 1)
				}
			}(),
			message: LocalizedString.openMusicToEditTheQueue,
			preferredStyle: .alert)
		alert.addAction(dontShowAgainAction)
		alert.addAction(openMusicAction)
		alert.addAction(okAction)
		alert.preferredAction = okAction
		willPlayLaterAlertIsPresented = true
		present(alert, animated: true)
	}
}
