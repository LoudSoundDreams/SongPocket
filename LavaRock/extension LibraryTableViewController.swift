//
//  extension LibraryTableViewController.swift
//  LavaRock
//
//  Created by h on 2020-05-07.
//  Copyright © 2020 h. All rights reserved.
//

import UIKit
import CoreData

extension LibraryTableViewController {
	
	
	
	// MARK: injectSampleLibrary
	
	func injectSampleLibrary() {
		
		let appDelegate = UIApplication.shared.delegate as! AppDelegate
		let managedObjectContext = appDelegate.persistentContainer.viewContext
		
		struct SampleSong {
			let title: String
			let trackNumber: Int
			
			init(_ title: String, _ trackNumber: Int) {
				self.title = title
				self.trackNumber = trackNumber
			}
		}
		
		struct SampleAlbum {
			let title: String
			let year: Int
			let sampleArtworkTitle: String
			let sampleSongs: [SampleSong]
			
			init(_ title: String, _ year: Int, _ sampleArtworkTitle: String, sampleSongs: [SampleSong]) {
				self.title = title
				self.year = year
				self.sampleArtworkTitle = sampleArtworkTitle
				self.sampleSongs = sampleSongs
			}
		}
		
		func injectSampleSongs(_ sampleSongs: [SampleSong], toAlbum: Album) {
			for index in 0..<sampleSongs.count {
				let sampleSong = sampleSongs[index]
				let song = Song(context: managedObjectContext)
				song.index = Int64(index)
				song.title = sampleSong.title
				song.trackNumber = Int64(sampleSong.trackNumber)
				song.container = toAlbum
			}
		}
		
		func injectSampleAlbums(_ sampleAlbums: [SampleAlbum], toCollection: Collection) {
			for index in 0..<sampleAlbums.count {
				let sampleAlbum = sampleAlbums[index]
				let album = Album(context: managedObjectContext)
				album.albumArtist = toCollection.title
				album.index = Int64(index)
				album.sampleArtworkTitle = sampleAlbum.sampleArtworkTitle
				album.title = sampleAlbum.title
				album.year = Int64(sampleAlbum.year)
				album.container = toCollection
				injectSampleSongs(sampleAlbum.sampleSongs, toAlbum: album)
			}
		}
		
		func injectSampleCollection(_ title: String, sampleAlbums: [SampleAlbum]) {
			let collection = Collection(context: managedObjectContext)
			collection.title = title
			activeLibraryItems.append(collection) // Sets "index" attribute automatically
			injectSampleAlbums(sampleAlbums, toCollection: collection)
		}
		
		injectSampleCollection("Alexander Melkinov", sampleAlbums: [
			SampleAlbum("Shostakovich: Piano Concertos", 2012, "shostakovichPianoConcertos", sampleSongs: [
				SampleSong("Piano Concerto No. 2 in F Major, Op. 102 No. 1, Allegro", 1),
			]),
		])
		injectSampleCollection("Carly Rae Jepsen", sampleAlbums: [
			SampleAlbum("Dedicated Side B", 2020, "dedicatedSideB", sampleSongs: [
				SampleSong("This Love Isn’t Crazy", 1),
				SampleSong("Solo", 11),
			]),
			SampleAlbum("Dedicated", 2019, "dedicated", sampleSongs: [
				SampleSong("Now That I Found You", 3),
				SampleSong("Want You in My Room", 4),
				SampleSong("Happy Not Knowing", 6),
				SampleSong("Real Love", 13),
			]),
			SampleAlbum("E•mo•tion", 2015, "emotion", sampleSongs: [
				SampleSong("Run Away with Me", 1),
				SampleSong("E•mo•tion", 2),
				SampleSong("I Really Like You", 3),
				SampleSong("Boy Problems", 6),
				SampleSong("Your Type", 8),
				SampleSong("Let’s Get Lost", 9),
				SampleSong("When I Needed You", 12),
			]),
			SampleAlbum("Kiss", 2012, "kiss", sampleSongs: [
				SampleSong("Good Time", 5),
				SampleSong("Turn Me Up", 7),
			]),
		])
		injectSampleCollection("Charli XCX", sampleAlbums: [
			SampleAlbum("Pop 2", 2017, "pop2", sampleSongs: [
				SampleSong("Unlock It", 8),
			]),
		])
		injectSampleCollection("GFriend", sampleAlbums: [
			SampleAlbum("回:Labyrinth", 2020, "labyrinth", sampleSongs: [
				SampleSong("Labyrinth", 1),
				SampleSong("Crossroads", 2),
			]),
			SampleAlbum("Fallin’ Light", 2019, "fallinLight", sampleSongs: [
				SampleSong("Fallin’ Light", 1),
				SampleSong("La pam pam", 9),
			]),
			SampleAlbum("Fever Season", 2019, "feverSeason", sampleSongs: [ //
				SampleSong("Flower (Korean Ver.)", 7),
			]),
			SampleAlbum("Time for us", 2019, "timeForUs", sampleSongs: [ //
				SampleSong("Memoria (Korean Ver.)", 12),
			]),
			SampleAlbum("Sunny Summer", 2018, "sunnySummer", sampleSongs: [ //
				SampleSong("Sunny Summer", 1),
			]),
			SampleAlbum("Time for the moon night", 2018, "timeForTheMoonNight", sampleSongs: [
				SampleSong("Time for the Moon Night", 2),
				SampleSong("Time for the Moon Night (Inst.)", 8),
			]),
			SampleAlbum("Rainbow", 2017, "rainbow", sampleSongs: [
				SampleSong("Summer Rain", 3),
				SampleSong("Ave Maria", 5),
				SampleSong("Red Umbrella", 8),
				SampleSong("Summer Rain (Inst.)", 10),
			]),
			SampleAlbum("The Awakening", 2017, "theAwakening", sampleSongs: [ //
				SampleSong("Fingertip", 2),
				SampleSong("Please Save My Earth", 4),
			]),
			SampleAlbum("LOL", 2016, "lol", sampleSongs: [ //
				SampleSong("Water Flower", 6),
			]),
			SampleAlbum("Flower bud", 2015, "flowerBud", sampleSongs: [ //
				SampleSong("Under the Sky", 3),
			]),
		])
		injectSampleCollection("IU", sampleAlbums: [
			SampleAlbum("Palette", 2017, "palette", sampleSongs: [
				SampleSong("dlwlrma", 1),
				SampleSong("Palette", 2),
				SampleSong("Jam Jam", 5),
				SampleSong("Through the Night", 8),
			]),
			SampleAlbum("Chat-Shire", 2015, "chatShire", sampleSongs: [
				SampleSong("Shoes", 1),
				SampleSong("Twenty-Three", 3),
				SampleSong("Knees", 6),
			]),
			SampleAlbum("Modern Times – Epilogue", 2013, "modernTimesEpilogue", sampleSongs: [
				SampleSong("Love of B", 3),
				SampleSong("Everybody Has Secrets", 4),
				SampleSong("The Red Shoes", 6),
				SampleSong("Walk with Me, Girl", 10),
				SampleSong("Havana", 11),
			]),
			SampleAlbum("Real", 2010, "real", sampleSongs: [
				SampleSong("Good Day", 3),
				SampleSong("Merry Christmas in Advance", 6),
			]),
		])
		injectSampleCollection("Lee Jin-ah", sampleAlbums: [
			SampleAlbum("Full Course", 2018, "fullCourse", sampleSongs: [
				SampleSong("Yum Yum Yum (Rebooted Ver. with Tak)", 3),
				SampleSong("I’m Full", 4),
				SampleSong("Stairs", 6),
				SampleSong("Random", 7),
			]),
		])
		injectSampleCollection("Poppy", sampleAlbums: [
			SampleAlbum("I Disagree", 2020, "iDisagree", sampleSongs: [
				SampleSong("Concrete", 1),
				SampleSong("I Disagree", 2),
				SampleSong("BLOODMONEY", 3),
				SampleSong("Anything Like Me", 4),
				SampleSong("Fill The Crown", 5),
				SampleSong("Nothing I Need", 6),
				SampleSong("Sit / Stay", 7),
				SampleSong("Bite Your Teeth", 8),
				SampleSong("Sick of the Sun", 9),
				SampleSong("Don’t Go Outside", 10),
			]),
			SampleAlbum("Poppy.Remixes", 2018, "poppyRemixes", sampleSongs: [
				SampleSong("Moshi Moshi (Noboru Remix)", 2),
				SampleSong("Moshi Moshi (Mitch Murder Remix)", 3),
				SampleSong("Moshi Moshi (Clarabell Remix)", 4),
			]),
		])
		injectSampleCollection("Queen", sampleAlbums: [
			SampleAlbum("Jazz", 1978, "jazz", sampleSongs: [
				SampleSong("Fat Bottomed Girls", 2),
				SampleSong("Don’t Stop Me Now", 12),
			]),
		])
		injectSampleCollection("Sample Artist with a Terribly, Horribly, No-Good, Very Long Name, Whose Life’s Purpose Is to Try to Break UI Layouts", sampleAlbums: [
			SampleAlbum("Sample Album with a Terribly, Horribly, No-Good, Very Long Title, in Which Amazingly Few Discotheques Provide Jukeboxes", 3000, "wide", sampleSongs: [
				SampleSong("Sample Song with a Terribly, Horribly, No-Good, Very Long Title, in Which Quick Brown Foxes Jump Over Lazy Dogs", 88888),
			]),
		])
		injectSampleCollection("Sega", sampleAlbums: [
			SampleAlbum("Planetary Pieces: Sonic World Adventure", 2009, "planetaryPieces", sampleSongs: [
				SampleSong("Endless Possibility - Vocal Theme -", 1),
				SampleSong("Cutscene - Opening", 2),
				SampleSong("Apotos - Day", 4),
				SampleSong("Windmill Isle - Day", 5),
				SampleSong("Tornado Defense - 1st Battle", 12),
				SampleSong("Savannah Citadel - Day", 21),
				SampleSong("Cool Edge - Day", 28),
				SampleSong("Spagonia - Night", 29),
				SampleSong("The World Adventure - Orchestral Theme -", 1), // disc 2
				SampleSong("Gaia Gate", 2), // 2
				SampleSong("Chun-nan - Night", 3), // 2
				SampleSong("Rooftop Run - Day", 8), // 2
				SampleSong("Dragon Road - Day", 11), // 2
				SampleSong("Holoska - Night", 12), // 2
				SampleSong("Empire City - Night", 18), // 2
				SampleSong("Shamar - Night", 21), // 2
				SampleSong("The World Adventure - Piano Version", 29), // 2
			]),
		])
		
		appDelegate.saveContext()
		print("Injected and saved sample library.")
	}
	
}
