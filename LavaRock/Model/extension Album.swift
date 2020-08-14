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
		
		// How do you use this thing? Would it kill Apple to put some example code on the Image I/O documentation page?
//		let imageSourcePropertyOptions = [
//			kCGImagePropertyPixelWidth: true,
//			kCGImagePropertyPixelHeight: true
//		] as CFDictionary
//		let imageSourceProperties = CGImageSourceCopyProperties(imageSource, nil) as NSDictionary?
//		print(imageSourceProperties![kCGImagePropertyPixelWidth]) as! Int
		
		
		
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
