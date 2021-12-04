//
//  OptionsTVC - Views.swift
//  LavaRock
//
//  Created by h on 2021-10-09.
//

import UIKit
import StoreKit

final class AppearanceCell: UITableViewCell {
	@IBOutlet private var segmentedControl: UISegmentedControl!
	
	enum Appearance: Int, CaseIterable {
		// Match the order of the segmented controls in the storyboard.
		// Raw values are the raw values of `UIUserInterfaceStyle`, which we also persist in `UserDefaults`.
		case light = 1
		case dark = 2
		case system = 0
		
		static func indexInDisplayOrder(_ style: UIUserInterfaceStyle) -> Int {
			let result = Self.allCases.firstIndex { preferredAppearance in
				preferredAppearance.rawValue == style.rawValue
			}!
			return result
		}
		
		init(indexInDisplayOrder: Int) {
			self = Self.allCases[indexInDisplayOrder]
		}
	}
	
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		selectionStyle = .none
		
		segmentedControl.addTarget(
			self,
			action: #selector(saveAndSetAppearance),
			for: .valueChanged)
		
		let savedStyleValue = UserDefaults.standard.integer(
			forKey: LRUserDefaultsKey.appearance.rawValue) // Returns `0` when there's no saved value, which happens to be `.unspecified`, which is what we want.
		let savedStyle = UIUserInterfaceStyle(rawValue: savedStyleValue)!
		segmentedControl.selectedSegmentIndex = Appearance.indexInDisplayOrder(savedStyle)
	}
	
	@objc private func saveAndSetAppearance() {
		let selectedAppearance = Appearance(
			indexInDisplayOrder: segmentedControl.selectedSegmentIndex)
		
		UserDefaults.standard.set(
			selectedAppearance.rawValue,
			forKey: LRUserDefaultsKey.appearance.rawValue)
		
		window?.overrideUserInterfaceStyle = UIUserInterfaceStyle(
			rawValue: selectedAppearance.rawValue)!
	}
}

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class AccentColorCell: UITableViewCell {
	final var accentColor: AccentColor? = nil {
		didSet {
			configure()
		}
	}
	
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		accessibilityTraits.formUnion(.button)
	}
	
	private func configure() {
		guard let accentColor = accentColor else {
			contentConfiguration = defaultContentConfiguration()
			return
		}
		
		var configuration = UIListContentConfiguration.cell()
		configuration.text = accentColor.displayName
		configuration.textProperties.color = accentColor.uiColor
		contentConfiguration = configuration
		
		if accentColor == AccentColor.savedPreference() { // Don't use `self.tintColor`, because if Increase Contrast is enabled, it won't match any `AccentColor.uiColor`.
			accessoryType = .checkmark
		} else {
			accessoryType = .none
		}
		
		refreshSelectedBackgroundView()
	}
	
	private func refreshSelectedBackgroundView() {
		let colorView = UIView()
		colorView.backgroundColor = accentColor?.uiColor.translucentVibrant()
		selectedBackgroundView = colorView
	}
	
	final override func tintColorDidChange() {
		super.tintColorDidChange()
		
		configure()
	}
	
	final override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)
		
		if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
			refreshSelectedBackgroundView()
		}
	}
}

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class TipReloadCell: LRTableCell {
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		accessibilityTraits.formUnion(.button)
		
		configure()
	}
	
	final override func tintColorDidChange() {
		super.tintColorDidChange()
		
		reflectAccentColor()
	}
}
extension TipReloadCell: ButtonCell {
	static let buttonText = LocalizedString.reload
}

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class TipReadyCell: LRTableCell {
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		accessibilityTraits.formUnion(.button)
		
		configure()
	}
	
	private func configure() {
		guard
			let tipProduct = PurchaseManager.shared.tipProduct,
			let tipPriceFormatter = PurchaseManager.shared.tipPriceFormatter
		else {
			contentConfiguration = defaultContentConfiguration()
			return
		}
		
		var configuration = UIListContentConfiguration.valueCell()
		configuration.text = tipProduct.localizedTitle
		configuration.textProperties.color = .tintColor_()
		configuration.secondaryText = tipPriceFormatter.string(from: tipProduct.price)
		contentConfiguration = configuration
	}
	
	final override func tintColorDidChange() {
		super.tintColorDidChange()
		
		if #available(iOS 15, *) {
		} else {
			configure()
		}
	}
}

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class TipThankYouCell: UITableViewCell {
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		isUserInteractionEnabled = false
		
		configure()
	}
	
	private func configure() {
		var configuration = UIListContentConfiguration.cell()
		let heartEmoji = AccentColor.savedPreference().heartEmoji
		let thankYouMessage = heartEmoji + LocalizedString.tipThankYouMessageWithPaddingSpaces + heartEmoji
		configuration.text = thankYouMessage
		configuration.textProperties.color = .secondaryLabel
		configuration.textProperties.alignment = .center
		contentConfiguration = configuration
	}
	
	final override func tintColorDidChange() {
		super.tintColorDidChange()
		
		configure()
	}
}
