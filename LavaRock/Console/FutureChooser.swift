//
//  FutureChooser.swift
//  LavaRock
//
//  Created by h on 2022-12-13.
//

import UIKit
import MediaPlayer
import SwiftUI

struct FutureChooserRep: UIViewRepresentable {
	typealias UIViewType = UISegmentedControl
	
	func makeUIView(
		context: Context
	) -> UISegmentedControl {
		return FutureChooser()
	}
	
	func updateUIView(
		_ uiView: UISegmentedControl,
		context: Context
	) {
	}
}

final class FutureChooser: UISegmentedControl {
	init() {
		super.init(frame: .zero)
		
		did_init()
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		did_init()
	}
	
	private enum Mode: Int, CaseIterable {
		case normal
		case repeatAll
		case repeat1
		
		var uiImage: UIImage {
			switch self {
			case .repeat1:
				return UIImage(systemName: "repeat.1")!
			case .repeatAll:
				return UIImage(systemName: "repeat")!
			case .normal:
				return UIImage(systemName: "circlebadge")!
			}
		}
		
		func apply(to player: MPMusicPlayerController) {
			switch self {
			case .repeat1:
				player.repeatMode = .one
			case .repeatAll:
				player.repeatMode = .all
			case .normal:
				player.repeatMode = .none
			}
		}
	}
	
	private var player: MPMusicPlayerController? { TapeDeck.shared.player }
	private func did_init() {
		removeAllSegments()
		Mode.allCases.forEach { mode in
			insertSegment(
				action: UIAction(
					image: mode.uiImage
				) { _ in
					// ARC2DO
					Task { await MainActor.run {
						if let player = self.player {
							mode.apply(to: player)
						}
					}}
				},
				at: numberOfSegments,
				animated: false)
		}
		
		Task { await MainActor.run {
			reflect_playback_mode()
			TapeDeck.shared.addReflector(weakly: self)
		}}
	}
}
extension FutureChooser: TapeDeckReflecting {
	func reflect_playback_mode() {
		guard
			let player = player,
			!Reel.mediaItems.isEmpty
		else {
			disable()
			selectedSegmentIndex = Mode.normal.rawValue
			return
		}
		enable()
		switch player.repeatMode {
		case .default:
			assertionFailure("`MPMusicPlayerController.repeatMode == .default")
			selectedSegmentIndex = Mode.normal.rawValue
		case .one:
			selectedSegmentIndex = Mode.repeat1.rawValue
		case .all:
			selectedSegmentIndex = Mode.repeatAll.rawValue
		case .none:
			selectedSegmentIndex = Mode.normal.rawValue
		@unknown default:
			assertionFailure("Unknown value for `MPMusicPlayerController.repeatMode")
			selectedSegmentIndex = Mode.normal.rawValue
		}
	}
	
	func reflect_now_playing_item() {}
}
