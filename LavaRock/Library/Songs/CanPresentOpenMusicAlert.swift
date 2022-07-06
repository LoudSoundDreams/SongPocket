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
			title: (
				willPlayNextAsOpposedToLast
				? LocalizedString.playingNext
				: LocalizedString.playingLast
			),
			message: {
				if songCount == 1 {
					// No plural rules required.
					return String.localizedStringWithFormat(
						LocalizedString.format_quoted,
						firstSongTitle)
				} else {
					// Plural rules required.
					return String.localizedStringWithFormat(
						LocalizedString.format_sentenceCase_songTitleAndXMoreSongs,
						firstSongTitle,
						songCount - 1)
				}
			}(),
			preferredStyle: .alert)
		alert.addAction(dontShowAgainAction)
		alert.addAction(openMusicAction)
		alert.addAction(okAction)
		alert.preferredAction = okAction
		willPlayLaterAlertIsPresented = true
		present(alert, animated: true)
	}
}
