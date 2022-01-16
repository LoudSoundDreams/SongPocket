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
	
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		selectionStyle = .none
		
		(0 ..< segmentedControl.numberOfSegments).forEach { indexOfSegment in
			let appearance = Appearance(indexInDisplayOrder: indexOfSegment)
			let image = UIImage(systemName: appearance.sfSymbolName)
			image?.accessibilityLabel = appearance.name
			segmentedControl.setImage(image, forSegmentAt: indexOfSegment)
		}
		
		segmentedControl.addTarget(
			self,
			action: #selector(saveAndSetAppearance),
			for: .valueChanged)
		
		segmentedControl.selectedSegmentIndex = Appearance.savedPreference().indexInDisplayOrder
	}
	
	@objc private func saveAndSetAppearance() {
		let selected = Appearance(
			indexInDisplayOrder: segmentedControl.selectedSegmentIndex)
		selected.saveAsPreference()
		window?.overrideUserInterfaceStyle = selected.uiUserInterfaceStyle
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
		configuration.textProperties.color = accentColor.uiColor // Don’t use `UIColor(accentColor.color)`, because it doesn’t respect “Increase Contrast”.
		contentConfiguration = configuration
		
		if accentColor == AccentColor.savedPreference() { // Don’t use `self.tintColor`, because if “Increase Contrast” is enabled, it won’t match any `AccentColor.uiColor`.
			accessoryType = .checkmark
		} else {
			accessoryType = .none
		}
		
		refreshSelectedBackgroundView()
	}
	
	// Similar to counterpart in `TintedSelectedCell`.
	private func refreshSelectedBackgroundView() {
		let colorView = UIView()
		// Don’t use `UIColor(accentColor.color).resolvedColor`, because it doesn’t respect “Increase Contrast”.
		// For some reason, to get this to respect “Increase Contrast”, you must use `resolvedColor`, even though you don’t need to for the text.
		colorView.backgroundColor = accentColor?.uiColor.resolvedColor(with: traitCollection).translucent()
		selectedBackgroundView = colorView
	}
	
	// UIKit does call this when “Increase Contrast” changes.
	final override func tintColorDidChange() {
		super.tintColorDidChange()
		
		configure()
	}
}

private extension AccentColor {
	var uiColor: UIColor {
		switch persistentValue {
		case .strawberry:
			return .systemPink
		case .tangerine:
			return .systemOrange
		case .lime:
			return .systemGreen
		case .blueberry:
			return .systemBlue
		case .grape:
			return .systemPurple
		}
	}
}

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class TipLoadingCell: UITableViewCell {
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		disableWithAccessibilityTrait()
		
		var configuration = UIListContentConfiguration.cell()
		configuration.text = LocalizedString.loadingEllipsis
		configuration.textProperties.color = .secondaryLabel
		contentConfiguration = configuration
	}
}

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class TipReloadCell: TintedSelectedCell {
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		accessibilityTraits.formUnion(.button)
		
		configureAsButton()
	}
}
extension TipReloadCell: CellConfiguredAsButton {
	static let buttonText = LocalizedString.reload
}

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class TipReadyCell: TintedSelectedCell {
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		accessibilityTraits.formUnion(.button)
		
		guard
			let tipProduct = PurchaseManager.shared.tipProduct,
			let tipPriceFormatter = PurchaseManager.shared.tipPriceFormatter
		else {
			contentConfiguration = defaultContentConfiguration()
			return
		}
		var configuration = UIListContentConfiguration.valueCell()
		configuration.text = tipProduct.localizedTitle
		configuration.textProperties.color = .tintColor
		configuration.secondaryText = tipPriceFormatter.string(from: tipProduct.price)
		contentConfiguration = configuration
	}
}

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class TipConfirmingCell: UITableViewCell {
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		disableWithAccessibilityTrait()
		
		var configuration = UIListContentConfiguration.cell()
		configuration.text = LocalizedString.confirmingEllipsis
		configuration.textProperties.color = .secondaryLabel
		contentConfiguration = configuration
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
