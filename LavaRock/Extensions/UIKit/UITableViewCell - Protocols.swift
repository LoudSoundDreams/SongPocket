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
		configuration.textProperties.color = .tintColor
		contentConfiguration = configuration
	}
}
