//
//  AppDelegate.swift
//  VimIOS
//
//  Created by Lars Kindler on 27/10/15.
//  Copyright © 2015 Lars Kindler. All rights reserved.
//

import UIKit


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        var url: URL?
        
        url = launchOptions?[UIApplicationLaunchOptionsKey.url] as? URL
        
        
        //Start Vim!
        performSelector(onMainThread: #selector(AppDelegate.VimStarter(_:)), with: url, waitUntilDone: false)
        return true
        
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        if(url.isFileURL) {
            let file = "Inbox/"+url.lastPathComponent
            do_cmdline_cmd("tabedit \(file)".char)
            do_cmdline_cmd("redraw!".char)
            return true
        }
        return false
    }
    
    
    func VimStarter(_ url: URL?) {
        guard let vimPath = Bundle.main.resourcePath else {return}
        let runtimePath = vimPath + "/runtime"
        vim_setenv("VIM".char, vimPath.char)
        vim_setenv("VIMRUNTIME".char, runtimePath.char)
        //            print("VimPath: \(vimPath)")
        //            print("VimRuntime: \(runtimePath)")
        
        
        
        let workingDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        //print("WorkingDir: \(workingDir)")
        
        vim_setenv("HOME".char, workingDir.char)
        FileManager.default.changeCurrentDirectoryPath(workingDir)
        
        var numberOfArguments = 0
        var file: String?

        if let url = url, url.isFileURL {
            let filename = url.lastPathComponent
            file = "Inbox/" + filename
            numberOfArguments += 1
        }
        
        vimHelper(Int32(numberOfArguments),file)
    }
    
}




extension String {
    // In Swift 3 compiler automatically translates String to "const char *"
    var char: String {
        return self
    }
    
    func each(_ closure: (String) -> Void ) {
        for digit in self.characters
        {
            closure(String(digit))
        }
    }
    
}
