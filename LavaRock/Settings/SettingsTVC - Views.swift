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
			freshen_accessoryType()
		}
	}
	
	// UIKit does call this when “Increase Contrast” changes.
	override func tintColorDidChange() {
		super.tintColorDidChange()
		
		freshen_contentConfiguration()
		freshen_accessoryType()
	}
	
	private func freshen_contentConfiguration() {
		contentConfiguration = UIHostingConfiguration {
			if let representee {
				Text(representee.displayName)
					.foregroundStyle(
						Color(uiColor: representee.uiColor.resolvedForIncreaseContrast())
					)
					.accessibilityAddTraits(.isButton)
			}
		}
	}
	
	private func freshen_accessoryType() {
		// Don’t compare `self.tintColor`, because if “Increase Contrast” is enabled, it won’t match any `AccentColor.uiColor`.
		accessoryType = (representee == AccentColor.preference)
		? .checkmark
		: .none
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		separatorInset.left = directionalLayoutMargins.leading // We shouldn’t have to do this, but as of build 482, without this, if you close Settings then open it again, something sets the left inset to 0.
		separatorInset.right = directionalLayoutMargins.trailing
	}
}
