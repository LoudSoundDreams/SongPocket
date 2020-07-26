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
		guard
			let urlToFullSizeArtwork = Bundle.main.url(
				forResource: sampleArtworkFileNameWithExtension,
				withExtension: nil
			)//,
			// TO DO: Make sure the original image's dimensions are larger than the target thumbnail size.
		else {
			return nil
		}
		
		// Uses CGImageSource (Image I/O framework) instead of UIGraphicsImageRenderer, because CGImageSource can access the files without decoding them at first.
		
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
