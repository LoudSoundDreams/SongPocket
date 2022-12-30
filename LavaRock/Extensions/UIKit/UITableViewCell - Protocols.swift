//
//  UITableViewCell - Protocols.swift
//  LavaRock
//
//  Created by h on 2021-11-29.
//

import UIKit

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
