//
//  OptionsTVC - Views.swift
//  LavaRock
//
//  Created by h on 2021-10-09.
//

import UIKit
import SwiftUI
import StoreKit

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class AccentColorCell: UITableViewCell {
	var representee: AccentColor? = nil {
		didSet {
			freshen_contentConfiguration()
			freshen_selectedBackgroundView()
			freshen_accessoryType()
		}
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		Task {
			accessibilityTraits.formUnion(.button)
		}
	}
	
	private func freshen_contentConfiguration() {
		let new_contentConfiguration: UIContentConfiguration
		defer {
			contentConfiguration = new_contentConfiguration
		}
		
		guard let representee = representee else {
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
	
	private func freshen_selectedBackgroundView() {
		let new_selectedBackgroundView: UIView?
		defer {
			selectedBackgroundView = new_selectedBackgroundView
		}
		
		// Similar to in `CellTintingWhenSelected`, except we need to do this manually to reflect “Increase Contrast”.
		let colorView = UIView()
		colorView.backgroundColor = representee?.uiColor
			.resolvedForIncreaseContrast()
			.withAlphaComponentOneHalf()
		new_selectedBackgroundView = colorView
	}
	
	private func freshen_accessoryType() {
		let new_accessoryType: AccessoryType
		defer {
			accessoryType = new_accessoryType
		}
		
		// Don’t compare `self.tintColor`, because if “Increase Contrast” is enabled, it won’t match any `AccentColor.uiColor`.
		if representee == AccentColor.preference {
			new_accessoryType = .checkmark
		} else {
			new_accessoryType = .none
		}
	}
	
	// UIKit does call this when “Increase Contrast” changes.
	override func tintColorDidChange() {
		super.tintColorDidChange()
		
		freshen_contentConfiguration()
		freshen_selectedBackgroundView()
		freshen_accessoryType()
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		separatorInset.left = directionalLayoutMargins.leading // We shouldn’t have to do this, but as of build 482, without this, if you close Options then open it again, something sets the left inset to 0.
		separatorInset.right = directionalLayoutMargins.trailing
	}
}

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class TipReloadCell: UITableViewCell {
	override func awakeFromNib() {
		super.awakeFromNib()
		
		tintSelectedBackgroundView()
		
		configureAsButton()
	}
}
extension TipReloadCell: CellTintingWhenSelected {}
extension TipReloadCell: CellConfigurableAsButton {
	static let buttonText = LRString.reload
}

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class TipReadyCell: UITableViewCell {
	override func awakeFromNib() {
		super.awakeFromNib()
		
		tintSelectedBackgroundView()
		
		contentConfiguration = UIHostingConfiguration {
			LabeledContent {
				Text(PurchaseManager.shared.tipPrice ?? "")
			} label: {
				Text(PurchaseManager.shared.tipTitle ?? "")
					.foregroundColor(.accentColor)
			}
			.accessibilityAddTraits(.isButton)
		}
	}
}
extension TipReadyCell: CellTintingWhenSelected {}
