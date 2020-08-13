//
//  SampleLibrary.swift
//  LavaRock
//
//  Created by h on 2020-05-07.
//  Copyright © 2020 h. All rights reserved.
//

import UIKit
import CoreData

struct SampleLibrary {
	
	// MARK: Structures
	
	private struct SampleCollection {
		let title: String
		let albums: [SampleAlbum]
		
		init(
			_ title: String,
			 _ albums: [SampleAlbum]
		) {
			self.title = title
			self.albums = albums
		}
	}
	
	private struct SampleAlbum {
		let title: String
		let albumArtist: String?
		let year: Int?
		let artworkFileName: String?
		let songs: [SampleSong]
		
		init(
			_ title: String,
			albumArtistIfDifferentFromCollectionTitle: String? = nil,
			_ year: Int?,
			_ artworkFileNameWithExtension: String?,
			_ songs: [SampleSong]
		) {
			self.title = title
			self.albumArtist = albumArtistIfDifferentFromCollectionTitle
			self.year = year
			self.artworkFileName = artworkFileNameWithExtension
			self.songs = songs
		}
	}
	
	private struct SampleSong {
		let title: String
		let trackNumber: Int?
		let discNumber: Int?
		
		init(
			_ title: String,
			 _ trackNumber: Int?,
			disc: Int? = 1
		) {
			self.title = title
			self.trackNumber = trackNumber
			self.discNumber = disc
		}
	}
	
	// MARK: Methods
	
//	static func setThumbnailsInBackground(_ collections: [Collection]) {
//
//		let managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
//
//		let queue = OperationQueue()
//		queue.qualityOfService = .userInitiated
//
//		for collection in collections {
//
//			guard collection.contents != nil else {
//				continue
//			}
//
//			for element in collection.contents! {
//				let album = element as! Album
//
//				let operation = BlockOperation(block: {
//					album.artworkThumbnail = album.sampleArtworkDownsampledData()
////					do {
////						try managedObjectContext.save()
////					} catch {
////						fatalError("Made a thumbnail, but couldn’t save it: \(error)")
////					}
//				} )
//				operation.completionBlock = {
//					print("Made and saved thumbnail for album: \(album)")
//				}
//				queue.addOperation(operation)
//			}
//
//		}
//
//	}
	
	static func inject() {
		
		let managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
		
		func injectSampleSongs(_ songs: [SampleSong], toAlbum: Album) {
			for index in 0..<songs.count {
				let song = songs[index]
				
				let newSong = Song(context: managedObjectContext)
				newSong.discNumber = Int64(song.discNumber ?? SongsTVC.impossibleDiscNumber)
				newSong.index = Int64(index)
				newSong.title = song.title
				newSong.trackNumber = Int64(song.trackNumber ?? SongsTVC.impossibleTrackNumber)
				newSong.container = toAlbum
			}
		}
		
		func injectSampleAlbums(_ albums: [SampleAlbum], toCollection: Collection) {
			for index in 0..<albums.count {
				let album = albums[index]
				
				let newAlbum = Album(context: managedObjectContext)
				if let albumArtist = album.albumArtist {
					newAlbum.albumArtist = albumArtist
				} else {
					newAlbum.albumArtist = toCollection.title
				}
				newAlbum.index = Int64(index)
				newAlbum.sampleArtworkFileNameWithExtension = album.artworkFileName
				newAlbum.title = album.title
				newAlbum.year = Int64(album.year ?? AlbumsTVC.impossibleYear)
				newAlbum.container = toCollection
				
				// TO DO: Do this concurrently.
				newAlbum.artworkThumbnail = newAlbum.sampleArtworkDownsampledData(
					maxWidthAndHeightInPixels: CGFloat(AlbumsTVC.rowHeightInPoints) * UIScreen.main.scale
				)
				// .scale is the ratio of rendered pixels to points (3.0 on an iPhone Plus).
				// .nativeScale is the ratio of physical pixels to points (2.608 on an iPhone Plus).
				print("Created a thumbnail.")
				
				injectSampleSongs(album.songs, toAlbum: newAlbum)
			}
		}
		
		func injectSampleCollections(_ collections: [SampleCollection]) {
			for index in 0..<collections.count {
				let collection = collections[index]
				
				let newCollection = Collection(context: managedObjectContext)
				newCollection.title = collection.title
				newCollection.index = Int64(index)
				
				injectSampleAlbums(collection.albums, toCollection: newCollection)
			}
		}
		
		injectSampleCollections([
			
//			SampleCollection("Albums", [
			
			
//			SampleCollection("Alexander Melkinov", [
//				SampleAlbum("Shostakovich: Piano Concertos", 2012, "shostakovichPianoConcertos.jpg", [
//					SampleSong("Piano Concerto No. 2 in F Major, Op. 102 No. 1, Allegro", 1),
//				]),
//			]),
			
//			SampleCollection("AOA", [
//				SampleAlbum("Angel’s Knock", 2017, "angelsKnock.jpg", [
//					SampleSong("Excuse Me", 1),
//				]),
//				SampleAlbum("Good Luck", 2016, "goodLuck.jpg", [
//					SampleSong("Crazy Boy", 4),
//				]),
//				SampleAlbum("Heart Attack", 2015, "heartAttack.jpg", [
//					SampleSong("Heart Attack", 1),
//				]),
//				SampleAlbum("Like a Cat", 2014, "likeACat.jpg", [
//					SampleSong("AOA", 1),
//					SampleSong("Like a Cat", 2),
//				]),
//				SampleAlbum("Short Hair", 2014, "shortHair.jpg", [
//					SampleSong("Short Hair", 2),
//				]),
//				SampleAlbum("Miniskirt", 2014, "miniskirt.jpg", [
//					SampleSong("Under the Street Light", 2),
//					SampleSong("Mini Skirt", 2),
//				]),
//				SampleAlbum("Red Motion", 2013, "redMotion.jpg", [
//					SampleSong("Confused", 1),
//				]),
//				SampleAlbum("Wannabe", 2012, "wannabe.jpg", [
//					SampleSong("Get Out", 1),
//				]),
//				SampleAlbum("Angels’ Story", 2012, "angelsStory.jpg", [
//					SampleSong("Elvis", 4),
//				]),
//			]),
			
//			SampleCollection("Apink", [
//				SampleAlbum("Pink Blossom", 2014, "pinkBlossom.jpg", [
//					SampleSong("Mr. Chu (On Stage)", 2),
//					SampleSong("Mr. Chu (On Stage) Inst.", 7),
//					SampleSong("Mr. Chu", 6),
//				]),
//			]),
			
			SampleCollection("Carly Rae Jepsen", [
				SampleAlbum("Dedicated Side B", 2020, "dedicatedSideB.jpg", [
					SampleSong("This Love Isn’t Crazy", 1),
					SampleSong("Solo", 11),
				]),
				SampleAlbum("Dedicated", 2019, "dedicated.jpg", [
					SampleSong("Too Much", 8),
					SampleSong("Real Love", 13),
				]),
				SampleAlbum("E•mo•tion", 2015, "emotion.jpg", [
					SampleSong("Run Away with Me", 1),
					SampleSong("E•mo•tion", 2),
					SampleSong("I Really Like You", 3),
					SampleSong("Boy Problems", 6),
					SampleSong("Your Type", 8),
					SampleSong("Let’s Get Lost", 9),
					SampleSong("When I Needed You", 12),
				]),
				SampleAlbum("Kiss", 2012, "kiss.jpg", [
					SampleSong("Good Time", 5),
					SampleSong("Turn Me Up", 7),
				]),
			]),
			
			SampleCollection("Disasterpeace", [
				SampleAlbum("Fez", 2012, "Fez.jpg", [
					SampleSong("Home", 24),
					SampleSong("Compass", 9),
					SampleSong("Knowledge", 16),
					SampleSong("Puzzle", 2),
					SampleSong("Fear", 13),
					SampleSong("Flow", 6),
					SampleSong("Age", 21),
					SampleSong("Reflection", 25),
					SampleSong("Nocturne", 20),
					SampleSong("Beacon", 5),
					SampleSong("Spirit", 14),
					SampleSong("Formations", 7),
					SampleSong("Nature", 15),
					SampleSong("Forgotten", 10),
					SampleSong("Progress", 4),
					SampleSong("Death", 17),
					SampleSong("Beyond", 3),
					SampleSong("Continuum", 23),
					SampleSong("Love", 26),
					SampleSong("Legend", 8),
					SampleSong("Memory", 18),
					SampleSong("Majesty", 22),
					SampleSong("Adventure", 1),
				]),
			]),
			
			SampleCollection("Falk", [
				SampleAlbum("Rooftop Run: Interactive Music Re-score - Side 1", 2011, "Be Cool.jpg", [
					SampleSong("Be Cool", 1),
				]),
				SampleAlbum("Rooftop Run: Interactive Music Re-score - Side 2", 2011, "Be Wild.jpg", [
					SampleSong("Be Wild", 2),
				]),
			]),
			
//			SampleCollection("Fountains Of Wayne", [
//				SampleAlbum("Sky Full of Holes", 2011, "Sky Full of Holes.jpg", [
//					SampleSong("Action Hero", 5),
//				]),
//				SampleAlbum("Welcome Interstate Managers", 2003, "welcomeInterstateManagers.jpg", [
//					SampleSong("Hey Julie", 9),
//					SampleSong("Hung Up On You", 11),
//				]),
//			]),
			
//			SampleCollection("GFriend", [
//				SampleAlbum("回:Song of the Sirens", 2020, "songOfTheSirens.jpg", [
//					SampleSong("Tarot Cards", 4),
//				]),
//				SampleAlbum("回:Labyrinth", 2020, "labyrinth.jpg", [
//					SampleSong("Labyrinth", 1),
//					SampleSong("Crossroads", 2),
//				]),
//				SampleAlbum("Fallin’ Light", 2019, "fallinLight.jpg", [
//					SampleSong("Fallin’ Light", 1),
//					SampleSong("La pam pam", 9),
//				]),
//				SampleAlbum("Fever Season", 2019, "feverSeason.jpg", [
//					SampleSong("Flower (Korean Ver.)", 7),
//				]),
//				SampleAlbum("Time for us", 2019, "timeForUs.jpg", [
//					SampleSong("Memoria (Korean Ver.)", 12),
//				]),
//				SampleAlbum("Sunny Summer", 2018, "sunnySummer.jpg", [
//					SampleSong("Sunny Summer", 1),
//				]),
//				SampleAlbum("Time for the moon night", 2018, "timeForTheMoonNight.jpg", [
//					SampleSong("Time for the Moon Night", 2),
//					SampleSong("Time for the Moon Night (Inst.)", 8),
//				]),
//				SampleAlbum("Rainbow", 2017, "rainbow.jpg", [
//					SampleSong("Summer Rain", 3),
//					SampleSong("Summer Rain (Inst.)", 10),
//					SampleSong("Ave Maria", 5),
//					SampleSong("Red Umbrella", 8),
//				]),
//				SampleAlbum("The Awakening", 2017, "theAwakening.jpg", [
//					SampleSong("Fingertip", 2),
//					SampleSong("Please Save My Earth", 4),
//				]),
//				SampleAlbum("LOL", 2016, "lol.jpg", [
//					SampleSong("Navillera", 3),
//					SampleSong("Water Flower", 6),
//				]),
//				SampleAlbum("Flower bud", 2015, "flowerBud.jpg", [
//					SampleSong("Under the Sky", 3),
//				]),
//			]),
			
			SampleCollection("IU", [
				SampleAlbum("Love poem", 2019, "lovePoem.jpg", [
					SampleSong("unlucky", 1),
				]),
				SampleAlbum("Palette", 2017, "palette.jpg", [
					SampleSong("dlwlrma", 1),
					SampleSong("Jam Jam", 5),
					SampleSong("Palette", 2),
					SampleSong("Through the Night", 8),
				]),
				SampleAlbum("Chat-Shire", 2015, "chatShire.jpg", [
					SampleSong("Shoes", 1),
					SampleSong("Twenty-Three", 3),
					SampleSong("Knees", 6),
				]),
				SampleAlbum("Modern Times – Epilogue", 2013, "modernTimesEpilogue.jpg", [
					SampleSong("Everybody Has Secrets", 4),
					SampleSong("The Red Shoes", 6),
					SampleSong("Walk with Me, Girl", 10),
					SampleSong("Love of B", 3),
					SampleSong("Havana", 11),
				]),
				SampleAlbum("Real", 2010, "real.jpg", [
					SampleSong("Good Day", 3),
					SampleSong("Merry Christmas in Advance", 6),
				]),
			]),
			
//			SampleCollection("James Horner", [
//				SampleAlbum("Star Trek II: The Wrath of Khan", 1982, "starTrekII.jpg", [
//					SampleSong("Main Title", 1),
//					SampleSong("Khan’s Pets", 5),
//					SampleSong("Enterprise Clears Moorings", 6),
//					SampleSong("Spock", 3),
//					SampleSong("Surprise Attack", 2),
//					SampleSong("Kirk’s Explosive Reply", 4),
//					SampleSong("Battle in the Mutara Nebula", 7),
//					SampleSong("Genesis Countdown", 8),
//					SampleSong("Epilogue / End Title", 9),
//				]),
//			]),
			
//			SampleCollection("Poppy", [
//				SampleAlbum("Poppy.Remixes", 2018, "poppyRemixes.jpg", [
//					SampleSong("Moshi Moshi (Noboru Remix)", 2),
//					SampleSong("Moshi Moshi (Clarabell Remix)", 4),
//					SampleSong("Moshi Moshi (Mitch Murder Remix)", 3),
//				]),
//			]),
			
//			SampleCollection("Sample Collection with a Terribly, Horribly, No-Good, Very Long Title that Was Written to Break UI Layouts", [
//				SampleAlbum("Sample Album with an Amazingly Long Title, in Which Amazingly Few Discotheques Provide Jukeboxes", albumArtistIfDifferentFromCollectionTitle: "", nil, nil, [
//					SampleSong("", nil),
//					SampleSong("", -2),
//					SampleSong("", 0),
//					SampleSong("Sample Song with a Very Long Title, in Which Quick Brown Foxes Jump Over Lazy Dogs", 88888),
//				]),
//				SampleAlbum("Jazz", albumArtistIfDifferentFromCollectionTitle: "Queen", 1978, "jazz.jpg", [
//					SampleSong("Fat Bottomed Girls", 2),
//					SampleSong("Don’t Stop Me Now", 12),
//				]),
//			]),
			
//			SampleCollection("supercell", [
//				SampleAlbum("Zigaexperientia", 2013, "zigaexperientia.jpg", [
//					SampleSong("My Dearest (Album Mix)", 4),
//				]),
//				SampleAlbum("My Dearest", 2011, "myDearest.jpg", [
//					SampleSong("My Dearest -Instrumental-", 5),
//				]),
//				SampleAlbum("君の知らない物語", 2009, "君の知らない物語.jpg", [
//					SampleSong("君の知らない物語", 1),
//				]),
//			]),
			
//			SampleCollection("Taylor Swift", [
//				SampleAlbum("folklore", 2020, "folklore.jpg", [
//					SampleSong("mirrorball", 6),
//					SampleSong("august", 8),
//					SampleSong("this is me trying", 9),
//				]),
//			]),
			
			SampleCollection("Tee Lopes", [
				SampleAlbum("Sonic Mania", 2017, "sonicMania.jpg", [
					SampleSong("Rise of the Icon (Sonic Mania Alternate Intro)", 47),
					SampleSong("Discovery (Title Screen)", 1),
					SampleSong("Prime Time (Studiopolis Zone Act 2)", 4),
					SampleSong("Dimension Heist (UFO Special Stage)", 30),
					SampleSong("Flying Battery Zone (Act 1)", 5),
					SampleSong("Flying Battery Zone (Act 2)", 6),
					SampleSong("Blue Spheres", 35),
					SampleSong("Skyway Octane (Mirage Saloon Zone Act 1 ST Mix)", 13),
					SampleSong("Hi-Spec Robo Go! (Hard Boiled Heavy Boss)", 25),
					SampleSong("Metallic Madness Zone (Act 1)", 18),
					SampleSong("Metallic Madness Zone (Act 2)", 19),
					SampleSong("Egg Reverie (Egg Reverie Zone)", 27),
					SampleSong("Guided Tour (Credits)", 29),
				]),
			]),
			
			SampleCollection("Various Artists", [
				SampleAlbum("FZ: Side Z", 2013, "FZ- Side Z.jpg", [
					SampleSong("FZ: Side E - Trail", 17),
				]),
				SampleAlbum("Planetary Pieces: Sonic World Adventure", 2009, "planetaryPieces.png", [
					SampleSong("Endless Possibility - Vocal Theme -", 1),
					SampleSong("Cutscene - Opening", 2),
					SampleSong("Apotos - Day", 4),
					SampleSong("Windmill Isle - Day", 5),
					SampleSong("Apotos - Night", 10),
					SampleSong("Tornado Defense - 1st Battle", 12),
					SampleSong("The World Adventure - Orchestral Theme -", 1, disc: 2),
					SampleSong("Holoska - Night", 12, disc: 2),
					SampleSong("Cool Edge - Day", 28),
					SampleSong("The World Adventure - Piano Version", 29, disc: 2),
					SampleSong("Spagonia - Night", 29),
					SampleSong("Rooftop Run - Day", 8, disc: 2),
					SampleSong("Chun-nan - Night", 3, disc: 2),
					SampleSong("Gaia Gate", 2, disc: 2),
					SampleSong("Dragon Road - Day", 11, disc: 2),
					SampleSong("Shamar - Night", 21, disc: 2),
					SampleSong("Savannah Citadel - Day", 21),
					SampleSong("Empire City - Night", 18, disc: 2),
				]),
			]),
			
		])
		
		do {
			try managedObjectContext.save()
		} catch {
			fatalError("Injected the sample library, but couldn’t save it.")
		}
		
		print("Injected and saved sample library.")
		
	}
	
}
