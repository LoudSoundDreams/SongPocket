//
//  SettingsTVC - Views.swift
//  LavaRock
//
//  Created by h on 2021-10-09.
//

import UIKit
import SwiftUI

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class AccentColorCell: UITableViewCell {
	var representee: AccentColor? = nil {
		didSet {
			freshen_contentConfiguration()
		}
	}
	
	// UIKit does call this when “Increase Contrast” changes.
	override func tintColorDidChange() {
		super.tintColorDidChange()
		
		freshen_contentConfiguration()
	}
	
	private func freshen_contentConfiguration() {
		contentConfiguration = UIHostingConfiguration {
			if let representee {
				
				LabeledContent {
					// Don’t compare to the UI’s accent color, because if “Increase Contrast” is enabled, it might not match any `AccentColor`. Compare directly to `AccentColor.preference`.
					if representee == AccentColor.preference {
						Image(systemName: "checkmark")
							.foregroundColor(Color.accentColor)
							.font(.headline) // Similar to `UITableViewCell.AccessoryType.checkmark`
					}
				} label: {
					Text(representee.displayName)
						.foregroundStyle(
							Color(uiColor: representee.uiColor.resolvedForIncreaseContrast())
						)
				}
				.accessibilityAddTraits(.isButton)
				.alignmentGuide_separatorTrailing()
				
			}
		}
	}
}
private extension UIColor {
	@MainActor
	final func resolvedForIncreaseContrast() -> UIColor {
		let view = UIView()
		view.tintColor = self
		return view.tintColor
	}
}
