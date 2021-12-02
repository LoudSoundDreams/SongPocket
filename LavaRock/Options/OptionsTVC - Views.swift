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
	
	enum PreferredAppearance: Int {//, CaseIterable {
		// Match the order of the segmented controls in the storyboard.
		// Raw values are the values we persist in `UserDefaults`.
		case light = 1
		case dark = 2
		case system = 0
		
		// Each member must correspond to its counterpart case of `self`.
		static let correspondingUIUserInterfaceStyles: [UIUserInterfaceStyle] = [
			.light,
			.dark,
			.unspecified,
		]
		
		init(userInterfaceStyle: UIUserInterfaceStyle) {
			let index = Self.correspondingUIUserInterfaceStyles.firstIndex(of: userInterfaceStyle)!
			self.init(rawValue: index)!
		}
	}
	
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		segmentedControl.addTarget(
			self,
			action: #selector(saveAndSetAppearance),
			for: .valueChanged)
		
		segmentedControl.selectedSegmentIndex = {
			let preferredAppearance = PreferredAppearance(userInterfaceStyle: overrideUserInterfaceStyle)
			return preferredAppearance.rawValue
		}()
	}
	
	@objc private func saveAndSetAppearance() {
		let preferredAppearance = PreferredAppearance(rawValue: segmentedControl.selectedSegmentIndex)!
		
		let indexOfPreferredAppearance = preferredAppearance.rawValue
		UserDefaults.standard.set(
			indexOfPreferredAppearance,
			forKey: LRUserDefaultsKey.appearance.rawValue)
		
		window?.overrideUserInterfaceStyle = PreferredAppearance.correspondingUIUserInterfaceStyles[indexOfPreferredAppearance]
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
	}
	
	final override func tintColorDidChange() {
		super.tintColorDidChange()
		
		configure()
	}
}

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class TipReloadCell: UITableViewCell {
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
final class TipReadyCell: UITableViewCell {
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
		configuration.textProperties.color = .tintColor(ifiOS14: AccentColor.savedPreference())
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
