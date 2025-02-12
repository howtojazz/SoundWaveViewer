//
//  SWWaveFormViewController.swift
//  SoundWaveViewer
//
//  Created by Evan Seok on 2017. 11. 8..
//  Copyright © 2017년 Evan Seok. All rights reserved.
//

import UIKit
import CoreMedia

final class SVWaveFormViewController: UIViewController {
    
    let SVBriefWaveformCellIdentifier = "SVBriefWaveformCellIdentifier"
    let SVFullWaveformItemCellIdentifier = "SVFullWaveformItemCellIdentifier"
    
    var media:SVMedia?
    var playing:Bool = false
    @IBOutlet weak var tracksView: UITableView!
    @IBOutlet weak var detailWaveformView: UICollectionView!
    @IBOutlet weak var playStopButton: UIButton!
    
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    private var displayLink:CADisplayLink!
    var offset:CGFloat = 0.0
    var offsetStride:CGFloat = 0.0
    var mediaTime:CGFloat = 0.0
    var timestamp:TimeInterval = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    @objc func update(displayLink:CADisplayLink) {
//        let currentTime = displayLink.timestamp
//        let elapsedTime = currentTime - timestamp
        detailWaveformView.contentOffset = CGPoint(x: offset, y: 0)
        offset += 1
//        timestamp = currentTime
    }
    
    @IBAction func playStopPressed(_ sender: Any) {
        if playing {
            stoppedState()
        }else {
            playingState()
        }
    }
    func stoppedState() {
        self.playStopButton.setTitle("Play", for: .normal)
        detailWaveformView.setContentOffset(.zero, animated: true)
        if nil != displayLink {
            displayLink.invalidate()
            displayLink = nil
        }
        detailWaveformView.isUserInteractionEnabled = true
        playing = false
        offset = 0.0
        offsetStride = 0.0
    }
    func playingState() {
        playStopButton.setTitle("Stop", for: .normal)
        displayLink = CADisplayLink(target: self, selector: #selector(update(displayLink:)))
        displayLink.add(to: .current, forMode: .commonModes)
        detailWaveformView.isUserInteractionEnabled = false
        playing = true
        offset = 0.0
//        if let loadedMedia = media, let selectedTrack = tracksView.indexPathForSelectedRow?.row {
//
//            mediaTime =  CMTimeGetSeconds(loadedMedia.tracks[selectedTrack].asset.duration)
//
//            mediaTime = loadedMedia.tracks[selectedTrack].asset.duration
//
//        }
        
    }
    func loadTracks(mediaURL:URL!) {
        media = nil
        tracksView.reloadData()
        detailWaveformView.reloadData()
        view.isUserInteractionEnabled = false
        loadingIndicator.startAnimating()
        
        SVTrackLoader.loadTracks(mediaURL: mediaURL) { [weak self] (media, error) in
            
            guard let weakSelf = self else {
                return
            }
            
            self!.view.isUserInteractionEnabled = true
            self!.loadingIndicator.stopAnimating()
            
            guard nil == error, let loadedMedia = media else {
                let alertVC = UIAlertController(title: nil, message: error!.localizedDescription, preferredStyle: .alert)
                alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self!.present(alertVC, animated: true, completion: nil)
                return
            }
            weakSelf.media = loadedMedia
            weakSelf.tracksView.reloadData()
            weakSelf.tracksView.selectRow(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .top)
            weakSelf.tableView(weakSelf.tracksView, didSelectRowAt: IndexPath(row: 0, section: 0))
        }
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
extension SVWaveFormViewController: UITableViewDelegate, UITableViewDataSource
{
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier:SVBriefWaveformCellIdentifier , for: indexPath) as! SVBriefWaveformCell
        cell.setup(waveform: media!.tracks[indexPath.row])
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return media?.tracks.count ?? 0
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        stoppedState()
        detailWaveformView.reloadData()
        detailWaveformView.setContentOffset(.zero, animated: false)
    }
}
extension SVWaveFormViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
{
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SVFullWaveformItemCellIdentifier, for: indexPath) as! SVFullWaveformItemCell
        
        guard let indexPathOfSelectedTrack = tracksView.indexPathForSelectedRow else {
            return cell
        }
        
        let segmentDescription = SVWaveformSegmentDescription(size: cell.frame.size, indexOfSegment: indexPath.row)
        cell.setup(track: media!.tracks[indexPathOfSelectedTrack.row], segmentDescription: segmentDescription)
        return cell
    }
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let loadedMedia = media,
            let indexPathOfSelectedTrack = tracksView.indexPathForSelectedRow else {
            return 0
        }
        let selectedTrack = loadedMedia.tracks[indexPathOfSelectedTrack.row]
        let segmentDescription = SVWaveformSegmentDescription(size: collectionView.frame.size, indexOfSegment: 0)
        return selectedTrack.numberOfWaveformSegments(segmentDescription: segmentDescription)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.frame.size
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(0, collectionView.frame.width / 2, 0, collectionView.frame.width / 2)
    }
}

