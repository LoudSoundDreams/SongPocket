//
//  protocol ButtonCell.swift
//  LavaRock
//
//  Created by h on 2021-11-29.
//

import UIKit

protocol ButtonCell: UITableViewCell {
	// Conforming types must …
	// - Override `awakeFromNib` and call `configure`.
	// - Override `tintColorDidChange` and call `reflectAccentColor`.
	
	static var buttonText: String { get }
	
	var contentConfiguration: UIContentConfiguration? { get set }
}

extension ButtonCell {
	func configure() {
		var configuration = UIListContentConfiguration.cell()
		configuration.text = Self.buttonText
		configuration.textProperties.color = .tintColor_() // As of iOS 15.1 developer beta 3, `UIColor.tintColor` dims and undims with animations when we present and dismiss a modal view. It also automatically matches `window?.tintColor`, even if you don't override `tintColorDidChange()`.
		// - `AccentColor.savedPreference().uiColor` or `window?.tintColor` don't dim when we have a modal view presented.
		// - `UITableViewCell.tintColor`dims and undims with animations when we present and dismiss a modal view, but it returns the wrong color if you call it too early. It automatically matches `window?.tintColor`, even if you don't override `tintColorDidChange()`.
		// - Also don't use `contentView.tintColor`, because when we present a modal view, it doesn't dim, although it is dimmed if you change `window.tintColor` later.
		contentConfiguration = configuration
	}
	
	func reflectAccentColor() {
		if #available(iOS 15, *) {
			// See comment in `configure()`.
		} else {
			configure()
		}
	}
}

