//
//  SettingsTVC - Views.swift
//  LavaRock
//
//  Created by h on 2021-10-09.
//

import UIKit

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class AccentColorCell: UITableViewCell {
	var representee: AccentColor? = nil {
		didSet {
			freshen_contentConfiguration()
			freshen_accessoryType()
		}
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		Task {
			accessibilityTraits.formUnion(.button)
		}
	}
	
	// UIKit does call this when “Increase Contrast” changes.
	override func tintColorDidChange() {
		super.tintColorDidChange()
		
		freshen_contentConfiguration()
		freshen_accessoryType()
	}
	
	private func freshen_contentConfiguration() {
		let new_contentConfiguration: UIContentConfiguration
		defer {
			contentConfiguration = new_contentConfiguration
		}
		
		guard let representee else {
			// Should never run
			new_contentConfiguration = defaultContentConfiguration()
			return
		}
		
		var content = UIListContentConfiguration.cell()
		// Text
		content.text = representee.displayName
		// Text color
		content.textProperties.color = representee.uiColor
			.resolvedForIncreaseContrast()
		new_contentConfiguration = content
	}
	
	private func freshen_accessoryType() {
		accessoryType = {
			// Don’t compare `self.tintColor`, because if “Increase Contrast” is enabled, it won’t match any `AccentColor.uiColor`.
			if representee == AccentColor.preference {
				return .checkmark
			} else {
				return .none
			}
		}()
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		separatorInset.left = directionalLayoutMargins.leading // We shouldn’t have to do this, but as of build 482, without this, if you close Settings then open it again, something sets the left inset to 0.
		separatorInset.right = directionalLayoutMargins.trailing
	}
}
