//
//  Album.swift
//  LavaRock
//
//  Created by h on 2020-07-10.
//

import UIKit
import CoreData
import ImageIO

extension Album {
	
	func sampleArtworkImageFullSize() -> UIImage? {
		if let pathToSampleArtwork = Bundle.main.path(
			forResource: sampleArtworkFileName,
			ofType: sampleArtworkFileNameExtension
		) {
			return UIImage(contentsOfFile: pathToSampleArtwork)
		} else {
			return nil
		}
	}
	
	func sampleArtworkThumbnailData() -> Data? {
		guard
			let urlToFullSizeArtwork = Bundle.main.url(
				forResource: sampleArtworkFileName,
				withExtension: sampleArtworkFileNameExtension
			)//,
			// TO DO: Make sure the original image's dimensions are larger than the target thumbnail size.
		else {
			return nil
		}
		
		// Uses CGImageSource (Image I/O framework) instead of UIGraphicsImageRenderer, because CGImageSource can access the files without decoding them at first.
		
		let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
		let imageSource = CGImageSourceCreateWithURL(urlToFullSizeArtwork as CFURL, imageSourceOptions)!
		
		let maximumWidthAndHeightInPixels = CGFloat(AlbumsTVC.rowHeightInPoints) * UIScreen.main.scale
		let downsampleOptions = [
			kCGImageSourceCreateThumbnailFromImageAlways: true,
			kCGImageSourceShouldCacheImmediately: true, // Do we need this?
			kCGImageSourceCreateThumbnailWithTransform: true,
			kCGImageSourceThumbnailMaxPixelSize: maximumWidthAndHeightInPixels
		] as CFDictionary
		
		let thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions)
		return UIImage(cgImage: thumbnail!).jpegData(compressionQuality: 1.0)
	}
	
}
