//
//  UITableViewCell - Protocols.swift
//  LavaRock
//
//  Created by h on 2021-11-29.
//

import UIKit

protocol CellTintingWhenSelected: UITableViewCell {
	// Adopting types must …
	// • Override `awakeFromNib` and call `tintSelectedBackgroundView`.
}
extension CellTintingWhenSelected {
	func tintSelectedBackgroundView() {
		let colorView = UIView()
		colorView.backgroundColor = .tintColor.translucent()
		selectedBackgroundView = colorView
	}
}

protocol CellHavingTransparentBackground: UITableViewCell {
	// Adopting types must …
	// • Override `awakeFromNib` and call `removeBackground`.
	// • Call `removeBackground` instead of `backgroundView = nil`.
}
extension CellHavingTransparentBackground {
	func removeBackground() {
		backgroundColor = nil
	}
}

protocol CellConfigurableAsButton: UITableViewCell {
	// Adopting types must …
	// • Override `awakeFromNib` and call `configureAsButton`.
	static var buttonText: String { get }
	var contentConfiguration: UIContentConfiguration? { get set }
}
extension CellConfigurableAsButton {
	func configureAsButton() {
		var configuration = UIListContentConfiguration.cell()
		configuration.text = Self.buttonText
		configuration.textProperties.color = .tintColor
		contentConfiguration = configuration
	}
}
