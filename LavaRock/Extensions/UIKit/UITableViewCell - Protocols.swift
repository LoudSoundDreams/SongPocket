//
//  UITableViewCell - Protocols.swift
//  LavaRock
//
//  Created by h on 2021-11-29.
//

import UIKit

protocol CellHavingTransparentBackground: UITableViewCell {
	// Conforming types must …
	// - Override `awakeFromNib` and call `setTransparentBackground`.
	// - Call `setTransparentBackground` instead of `backgroundView = nil`.
}

extension CellHavingTransparentBackground {
	func setTransparentBackground() {
		backgroundColor = nil
	}
}

protocol CellConfiguredAsButton: UITableViewCell {
	// Conforming types must …
	// - Override `awakeFromNib` and call `configureAsButton`.
	static var buttonText: String { get }
	var contentConfiguration: UIContentConfiguration? { get set }
}

extension CellConfiguredAsButton {
	func configureAsButton() {
		var configuration = UIListContentConfiguration.cell()
		configuration.text = Self.buttonText
		configuration.textProperties.color = .tintColor // As of iOS 15.1 developer beta 3, `UIColor.tintColor` dims and undims with animations when we present and dismiss a modal view. It also automatically matches `window?.tintColor`, even if you don't override `tintColorDidChange()`.
		// - `AccentColor.savedPreference().uiColor` or `window?.tintColor` don't dim when we have a modal view presented.
		// - `UITableViewCell.tintColor`dims and undims with animations when we present and dismiss a modal view, but it returns the wrong color if you call it too early. It automatically matches `window?.tintColor`, even if you don't override `tintColorDidChange()`.
		// - Also don't use `contentView.tintColor`, because when we present a modal view, it doesn't dim, although it is dimmed if you change `window.tintColor` later.
		contentConfiguration = configuration
	}
}

