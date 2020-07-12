//
//  Album.swift
//  LavaRock
//
//  Created by h on 2020-07-10.
//

import UIKit
import CoreData
import CoreGraphics

extension Album {
	
	func saveDownsampledArtwork() {
		guard let artworkTitle = sampleArtworkTitle else { return }
		// Set nil if the original artwork's dimensions are already smaller than the thumbnail size, to save CPU and storage.
		
		
		
		// CGImageSource version.
		// Calculates "aspect fit" size with a convenient flag.
		// Slightly slower than the UIGraphicsImageRenderer version because it initializes 2 UIImages instead of 1.
		
		let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
		print("Creating CGImageSource.")
		let imageSource = CGImageSourceCreateWithData(
			NSData(data: UIImage(named: artworkTitle)!.jpegData(compressionQuality: 1.0)!), //
			imageSourceOptions
		)!
		print("Done.")
		
		let maximumWidthAndHeightInPixels = CGFloat(AlbumsTVC.rowHeightInPoints) * UIScreen.main.scale
		let downsampleOptions = [
			kCGImageSourceCreateThumbnailFromImageAlways: true,
			kCGImageSourceShouldCacheImmediately: true, // Do we need this?
			kCGImageSourceCreateThumbnailWithTransform: true,
			kCGImageSourceThumbnailMaxPixelSize: maximumWidthAndHeightInPixels
		] as CFDictionary
		
		let downsampledCGImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions)
		print("Creating JPEG data.")
		let downsampledUIImage = UIImage(cgImage: downsampledCGImage!)
		let downsampledJpegData = downsampledUIImage.jpegData(compressionQuality: 1.0)
		print("Done.")
		
		
		// UIGraphicsImageRenderer version.
		// Slightly faster than the CGImageSource version because it only initializes 1 UIImage instead of 2.
		// Needs you to manually calculate "aspect fit" size.
		
//		let originalImage = UIImage(named: artworkTitle)
//		let maximumWidthAndHeightInPoints = AlbumsTVC.rowHeightInPoints
//		let finalSize = CGSize(width: maximumWidthAndHeightInPoints, height: maximumWidthAndHeightInPoints) //
//
//		let renderer = UIGraphicsImageRenderer(size: finalSize)
//		let downsampledJpegData = renderer.jpegData(withCompressionQuality: 1.0, actions: { (context) in
////			context.cgContext.interpolationQuality = .high // No noticeable improvement as of iOS 14.0 beta 2 on iPhone X
//			originalImage?.draw(in: CGRect(origin: .zero, size: finalSize))
//		})
		
		
		downsampledArtwork = downsampledJpegData
		(UIApplication.shared.delegate as! AppDelegate).saveContext()
		
		print("Created and saved a downsampled thumbnail.")
	}
	
}
