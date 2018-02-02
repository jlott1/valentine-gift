//
//  SoundPlayer.swift
//  Valentine
//
//  Created by Jonathan Lott on 1/23/18.
//  Copyright © 2018 Chris Voss. All rights reserved.
//

import Foundation
import AVFoundation


// Now we should try recording the audio and playing it back with text
class SoundPlayer {
    var audioPlayer: AVAudioPlayer?
    var itunesResults: iTunesSearchResults?
    
    struct iTunesSearchResults : Codable {
        var resultCount: Int?
        var results: [iTunesSearchResultItem]?
        func trackPreviewURL() -> URL? {
            if let item = results?.first,
                let urlStr = item.previewUrl,
                let url = URL(string: urlStr) {
                return url
            }
            return nil
        }
        
        func trackDescription() -> String {
            if let item = results?.first,
                let artist = item.artistName,
                let track = item.trackName {
                return "\(track)\nby \(artist)"
            }
            return "Unknown"
        }
        
        func trackId() -> String? {
            return "\(results?.first?.trackId ?? 0)"
        }
    }
    
    struct iTunesSearchResultItem : Codable {
        var previewUrl: String?
        var artistName: String?
        var trackName: String?
        var trackId: Int?
    }
    
    // song previews: https://affiliate.itunes.apple.com/resources/blog/song-previews/
    // sample url:  http://itunes.apple.com/us/lookup?id=823593456
    // BEST SINGLE EVER!!!!  https://itunes.apple.com/us/album/my-bride-wedding-song/1212743580?i=1212743725
    func playiTunesSongPreview(withId id: String = "1212743725", volume: Float = 0.4, completion: ((iTunesSearchResults?, Error?) -> Void)? = nil) {
        do {
            if let itunesResults = itunesResults, let url = itunesResults.trackPreviewURL(), itunesResults.trackId() == id {
                playSound(withURL: url, volume: volume)
                completion?(itunesResults, nil)
                return
            }
            
            let jsonStr = try String(contentsOf: URL(string: "http://itunes.apple.com/us/lookup?id=\(id)")!)
            print("got json = \(jsonStr)")
            let data = jsonStr.data(using: .utf8)!
            let object = try JSONDecoder().decode(iTunesSearchResults.self, from: data)
            if let url = object.trackPreviewURL() {
                itunesResults = object
                print("playing track at url \(url)")
                playSound(withURL: url, volume: volume)
                completion?(itunesResults, nil)
            } else {
                throw "Cannot find track url"
            }
            
        } catch {
            print("error fetching details \(error.localizedDescription)")
            completion?(nil, error)
        }
    }
    
    func playSound(withName fileName: String, volume: Float = 0.25) {
        if let filePath: String = Bundle.main.path(forResource: fileName, ofType: "") {
            print("playing sound from path \(filePath)")
            playSound(withURL: URL(fileURLWithPath: filePath), volume: volume)
        }
    }
    
    func playSound(withURL fileURL: URL, volume: Float = 0.25) {
        do {
            if fileURL.isFileURL {
                let player = try AVAudioPlayer(contentsOf: fileURL)
                player.prepareToPlay()
                player.volume = volume
                player.play()
                player.numberOfLoops = -1
                audioPlayer = player
            }
            else {
                let data = try Data(contentsOf: fileURL)
                let player = try AVAudioPlayer(data: data)
                player.prepareToPlay()
                player.volume = volume
                player.play()
                player.numberOfLoops = -1
                audioPlayer = player
            }
            
        }
        catch {
            print("error playing file \(error.localizedDescription)")
        }
    }
    
    func stopSound() {
        audioPlayer?.stop()
    }
    
}
