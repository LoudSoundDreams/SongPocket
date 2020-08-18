//
//  extension Album.swift
//  LavaRock
//
//  Created by h on 2020-07-10.
//

import UIKit
import CoreData
import ImageIO

extension Album {
	
	// There's a similar method in `extension Song`. Make this generic?
	func titleOrPlaceholder() -> String {
		if
			let storedTitle = title,
			storedTitle != ""
		{
			return storedTitle
		} else {
			return AlbumsTVC.unknownAlbumTitlePlaceholderText
		}
	}
	
	func releaseDateFormatted() -> String? {
		if let date = releaseDateEstimate {
			let dateFormatter = DateFormatter()
			
			// Insert date formatter options
////			dateFormatter.locale = Locale.current
//			dateFormatter.locale = Locale(identifier: "en_US_POSIX")
//			dateFormatter.dateFormat = "yyyy-MM-dd"
//			dateFormatter.timeZone = TimeZone.current// TimeZone(secondsFromGMT: 0)
////			dateFormatter.setLocalizedDateFormatFromTemplate("yyyy-MM-dd")
			
			dateFormatter.dateStyle = .medium
			dateFormatter.timeStyle = .none
			
			return dateFormatter.string(from: date)
		} else {
			return nil
		}
	}
	
//	func sampleArtworkDownsampledImage(maxWidthAndHeightInPixels: CGFloat) -> UIImage? {
//		let imageData = sampleArtworkDownsampledData(maxWidthAndHeightInPixels: maxWidthAndHeightInPixels)
//		if imageData != nil {
//			return UIImage(data: imageData!)
//		} else {
//			return nil
//		}
//	}
	
	func sampleArtworkDownsampledData(maxWidthAndHeightInPixels: CGFloat) -> Data? {
		guard let urlToFullSizeArtwork = Bundle.main.url(
			forResource: sampleArtworkFileNameWithExtension,
			withExtension: nil
		) else {
			return nil
		}
		
		// Uses CGImageSource (from the Image I/O framework) instead of UIGraphicsImageRenderer, because CGImageSource can access image data without decoding it at first.
		
		let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
		let imageSource = CGImageSourceCreateWithURL(urlToFullSizeArtwork as CFURL, imageSourceOptions)!
		
		let downsampleOptions = [
			kCGImageSourceCreateThumbnailFromImageAlways: true,
			kCGImageSourceShouldCacheImmediately: true,
			kCGImageSourceCreateThumbnailWithTransform: true,
			kCGImageSourceThumbnailMaxPixelSize: maxWidthAndHeightInPixels
		] as CFDictionary
		let thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions)
		return UIImage(cgImage: thumbnail!).jpegData(compressionQuality: 1.0)
	}
	
}
