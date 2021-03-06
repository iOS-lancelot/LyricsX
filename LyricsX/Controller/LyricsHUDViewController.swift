//
//  LyricsHUDViewController.swift
//  LyricsX
//
//  Created by 邓翔 on 2017/2/10.
//  Copyright © 2017年 ddddxxx. All rights reserved.
//

import Cocoa

class LyricsHUDViewController: NSViewController, ScrollLyricsViewDelegate, DragNDropDelegate {
    
    @IBOutlet weak var dragNDropView: DragNDropView!
    @IBOutlet weak var lyricsScrollView: ScrollLyricsView!
    
    dynamic var isTracking = true
    
    override func awakeFromNib() {
        view.window?.titlebarAppearsTransparent = true
        view.window?.titleVisibility = .hidden
        view.window?.styleMask.insert(.borderless)
        
        let accessory = self.storyboard?.instantiateController(withIdentifier: "LyricsHUDAccessory") as! LyricsHUDAccessoryViewController
        accessory.layoutAttribute = .right
        view.window?.addTitlebarAccessoryViewController(accessory)
        
        dragNDropView.dragDelegate = self
        
        lyricsScrollView.delegate = self
        lyricsScrollView.setupTextContents(lyrics: AppController.shared.currentLyrics)
        
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(handlePositionChange), name: .PositionChange, object: nil)
        nc.addObserver(self, selector: #selector(handleLyricsChange), name: .LyricsChange, object: nil)
        nc.addObserver(self, selector: #selector(handleScrollViewWillStartScroll), name: .NSScrollViewWillStartLiveScroll, object: lyricsScrollView)
    }
    
    override func viewDidDisappear() {
        NotificationCenter.default.removeObserver(self)
    }
    
    func doubleClickLyricsLine(at position: TimeInterval) {
        let pos = position - (AppController.shared.currentLyrics?.timeDelay ?? 0)
        MusicPlayerManager.shared.player?.playerPosition = pos
        isTracking = true
    }
    
    // MARK: - handler
    
    func handleLyricsChange(_ n: Notification) {
        DispatchQueue.main.async {
            self.lyricsScrollView.setupTextContents(lyrics: AppController.shared.currentLyrics)
        }
    }
    
    func handlePositionChange(_ n: Notification) {
        guard var pos = n.userInfo?["position"] as? TimeInterval else {
            return
        }
        pos += AppController.shared.currentLyrics?.timeDelay ?? 0
        lyricsScrollView.highlight(position: pos)
        guard isTracking else {
            return
        }
        DispatchQueue.main.async {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.3
                context.allowsImplicitAnimation = true
                context.timingFunction = CAMediaTimingFunction(controlPoints: 0.2, 0.1, 0.2, 1)
                self.lyricsScrollView.scroll(position: pos)
            })
        }
    }
    
    func handleScrollViewWillStartScroll(_ n: Notification) {
        isTracking = false
    }
    
    // MARK: DragNDrop Delegate
    
    func dragFinished(content: String) {
        AppController.shared.importLyrics(content)
    }
    
}

class LyricsHUDAccessoryViewController: NSTitlebarAccessoryViewController {
    
    override func viewWillAppear() {
        view.window?.level = Int(CGWindowLevelForKey(.normalWindow))
    }
    
    @IBAction func lockAction(_ sender: NSButton) {
        if sender.state == NSOnState {
            view.window?.level = Int(CGWindowLevelForKey(.modalPanelWindow))
        } else {
            view.window?.level = Int(CGWindowLevelForKey(.normalWindow))
        }
    }
    
}
