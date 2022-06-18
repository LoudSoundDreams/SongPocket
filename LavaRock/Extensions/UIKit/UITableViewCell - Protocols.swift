//
//  UITableViewCell - Protocols.swift
//  LavaRock
//
//  Created by h on 2021-11-29.
//

import UIKit

@MainActor
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

@MainActor
protocol CellHavingTransparentBackground: UITableViewCell {
	// Adopting types must …
	// • Override `awakeFromNib` and call `removeBackground`.
	// • Call `removeBackground` instead of `backgroundView = nil`.
}
extension CellHavingTransparentBackground {
	func removeBackground() {
		backgroundColor = .clear
	}
}

@MainActor
protocol CellConfigurableAsButton: UITableViewCell {
	// Adopting types must …
	// • Override `awakeFromNib` and call `configureAsButton`.
	
	static var buttonText: String { get }
}
extension CellConfigurableAsButton {
	func configureAsButton() {
		accessibilityTraits.formUnion(.button)
		
		var content = UIListContentConfiguration.cell()
		content.text = Self.buttonText
		content.textProperties.color = .tintColor
		contentConfiguration = content
	}
}
