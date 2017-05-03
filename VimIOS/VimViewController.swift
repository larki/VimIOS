//
//  ViewController.swift
//  VimIOS
//
//  Created by Lars Kindler on 27/10/15.
//  Copyright © 2015 Lars Kindler. All rights reserved.
//

import UIKit


enum blink_state {
    case none     /* not blinking at all */
    case off     /* blinking, cursor is not shown */
    case on        /* blinking, cursor is shown */
}


//let hotkeys = "1234567890[]{}()!@#$%^&*/.,;"
let hotkeys = "1234567890!@#$%^&*()_={}\\/.,<>?:|`~[]"
let shiftableHotkeys = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

let kMenuCommandModifiers = 0
let kMenuShiftModifier  = (1 << 0)
let kMenuOptionModifier = (1 << 1)
let kMenuControlModifier = (1 << 2)
let kMenuNoCommandModifier = (1 << 3)
let MOD_MASK_SHIFT : UInt8 = 0x02
let MOD_MASK_CTRL : UInt8 = 0x04
let MOD_MASK_ALT :UInt8 = 0x08
let MOD_MASK_META :UInt8 = 0x10
let KS_MODIFIER : UInt8 = 252
let MOD_MASK_CMD : UInt8 = 0x80
let CSI : UInt8 = 0x9b	/* Control Sequence Introducer */

let vk_Return   :CChar = 0x28
let vk_Esc      :CChar = 0x29
let vk_Delete   :CChar = 0x30
let vk_Tab      :CChar = 0x31
let vk_F1       :CChar = 0x3a
let vk_F2       :CChar = 0x3b
let vk_F3       :CChar = 0x3c
let vk_F4       :CChar = 0x3d
let vk_F5       :CChar = 0x3e
let vk_F6       :CChar = 0x3f
let vk_F7       :CChar = 0x40
let vk_F8       :CChar = 0x41
let vk_F9       :CChar = 0x42
let vk_F10      :CChar = 0x43
let vk_F11      :CChar = 0x44
let vk_F12      :CChar = 0x45
let vk_F13      :CChar = 0x46
let vk_F14      :CChar = 0x47
let vk_F15      :CChar = 0x48
let vk_Right    :CChar = 0x4F
let vk_Left     :CChar = 0x50
let vk_Down     :CChar = 0x51
let vk_Up       :CChar = 0x52
let special_keys: [[CChar]] = [
        [vk_Up,  "k".utf8CString[0], "u".utf8CString[0]],
        [vk_Down,"k".utf8CString[0], "d".utf8CString[0]],
        [vk_Left,"k".utf8CString[0], "l".utf8CString[0]],
        [vk_Right, "k".utf8CString[0], "r".utf8CString[0]],
        [vk_Delete,"k".utf8CString[0], "b".utf8CString[0]],
        [vk_F1,    "k".utf8CString[0], "1".utf8CString[0]],
        [vk_F2,    "k".utf8CString[0], "2".utf8CString[0]],
        [vk_F3,    "k".utf8CString[0], "3".utf8CString[0]],
        [vk_F4,    "k".utf8CString[0], "4".utf8CString[0]],
        [vk_F5,    "k".utf8CString[0], "5".utf8CString[0]],
        [vk_F6,    "k".utf8CString[0], "6".utf8CString[0]],
        [vk_F7,    "k".utf8CString[0], "7".utf8CString[0]],
        [vk_F8,    "k".utf8CString[0], "8".utf8CString[0]],
        [vk_F9,    "k".utf8CString[0], "9".utf8CString[0]],
        [vk_F10,   "k".utf8CString[0], ";".utf8CString[0]],
        [vk_F11,   "F".utf8CString[0], "1".utf8CString[0]],
        [vk_F12,   "F".utf8CString[0], "2".utf8CString[0]],
        [vk_F13,   "F".utf8CString[0], "3".utf8CString[0]],
        [vk_F14,   "F".utf8CString[0], "4".utf8CString[0]],
        [vk_F15,   "F".utf8CString[0], "5".utf8CString[0]],
        [0,0, 0]
]

let a_char = "a".utf8CString[0]
let z_char = "z".utf8CString[0]
let need_ime = ["zh-Hans","zh-Hant","ja-JP","ko-KR"]



class VimViewController: UIViewController, UIKeyInput, UITextInputTraits{
    var vimView: VimView?
    var hasBeenFlushedOnce = false
    var lastKeyPress = Date()
    var in_ime = false
    
    var blink_wait:CLong = 1000
    var blink_on:CLong = 1000
    var blink_off:CLong = 1000
    var state:blink_state = .none
    var blinkTimer : Timer?
    
    var keyCommandArray: [UIKeyCommand]?
    
    var documentController:UIDocumentInteractionController?
    var activityController:UIActivityViewController?
    var ime_input = UITextField()
    
    override var keyCommands: [UIKeyCommand]? {
        if self.in_ime == true{
            return [
                UIKeyCommand(input:UIKeyInputEscape, modifierFlags: [], action: #selector(VimViewController.exit_ime_and_esc(_:))),
                UIKeyCommand(input: "[", modifierFlags: [.control], action: #selector(VimViewController.exit_ime_and_esc(_:))),
                UIKeyCommand(input: "\r", modifierFlags: [], action: #selector(VimViewController.ime_on_enter_pressed(_:))),
                UIKeyCommand(input: "`", modifierFlags: [.command], action: #selector(VimViewController.exit_ime(_:))),
            ]
        }
        return self.keyCommandArray!
    }
    
    func ime_on_change(_ sender:UITextField){
        let newPosition = sender.endOfDocument
        sender.selectedTextRange = sender.textRange(from: newPosition, to: newPosition)
    }
    
    
    func exit_ime_and_esc(_ sender:Any){
        self.exit_ime(self)
        insertText(UnicodeScalar(Int(keyESC))!.description)
    }
    
    func exit_ime(_ sender:Any){
        ime_input.isHidden = true
        in_ime = false
    }
    
    func start_ime(_ sender:Any){
        ime_input.isHidden = false
        ime_input.becomeFirstResponder()
        in_ime = true
    }
    
    

    func ime_on_enter_pressed(_ sender:Any){
        if self.in_ime == true{
            if let result = ime_input.text
            {
                ime_input.text = ""
                if result != ""
                {
                    insertText(result)
                }
                else
                {
                    insertText("\n")
                }
                ime_input.becomeFirstResponder()
            }
        }
    }

    
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(VimViewController.keyboardWillShow(_:)), name:NSNotification.Name.UIKeyboardWillShow, object:nil)
        NotificationCenter.default.addObserver(self, selector: #selector(VimViewController.keyboardDidShow(_:)), name:NSNotification.Name.UIKeyboardDidShow, object:nil)
        NotificationCenter.default.addObserver(self, selector: #selector(VimViewController.keyboardWillHide(_:)), name:NSNotification.Name.UIKeyboardWillHide, object:nil)
        NotificationCenter.default.addObserver(self,selector: #selector(self.change_ime(_:)),name: NSNotification.Name.UITextInputCurrentInputModeDidChange,object: nil)
    }
    
    func change_ime(_ sender:Any){
        if let lang = self.view.window?.textInputMode?.primaryLanguage{
            if need_ime.index(of: lang) == nil
            {
                if in_ime == true
                {
                    exit_ime(self)
                }
            }
            else
            {
                start_ime(self)
            }
        }
    }
    
    override func viewDidLoad() {
        print("DidLoad Bounds \(UIScreen.main.bounds)")
        vimView = VimView(frame: view.frame)
        vimView!.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        vimView?.addSubview(ime_input)
        let y_start = vimView!.frame.height - 20
        let x_start = vimView!.frame.width - 300
        ime_input.frame = CGRect(x: x_start, y: y_start, width: 300, height: 15)
        ime_input.backgroundColor = .black
        ime_input.textColor = .white
        ime_input.isHidden = true
        ime_input.addTarget(self, action: #selector(self.ime_on_change(_:)), for: .editingChanged)
        self.view.addSubview(vimView!)
        registerHotkeys()
        vimView?.addGestureRecognizer(UITapGestureRecognizer(target:self,action:#selector(VimViewController.click(_:))))
        vimView?.addGestureRecognizer(UILongPressGestureRecognizer(target:self,action:#selector(VimViewController.longPress(_:))))
        let scrollRecognizer = UIPanGestureRecognizer(target:self, action:#selector(VimViewController.scroll(_:)))
        vimView?.addGestureRecognizer(scrollRecognizer)
        scrollRecognizer.minimumNumberOfTouches=1
        scrollRecognizer.maximumNumberOfTouches=1
        let mouseRecognizer = UIPanGestureRecognizer(target:self, action:#selector(VimViewController.pan(_:)))
        mouseRecognizer.minimumNumberOfTouches=2
        mouseRecognizer.maximumNumberOfTouches=2
        vimView?.addGestureRecognizer(mouseRecognizer)
        inputAssistantItem.leadingBarButtonGroups=[]
        inputAssistantItem.trailingBarButtonGroups=[]
    }
    
    override func viewDidAppear(_ animated: Bool) {
        #if  FEAT_GUI
        //print("Hallo!")
        #endif
    }
    
    func click(_ sender: UITapGestureRecognizer) {
        becomeFirstResponder()
        let clickLocation = sender.location(in: sender.view)
        gui_send_mouse_event(0, Int32(clickLocation.x), Int32(clickLocation.y), 1,0)
    }
    func longPress(_ sender: UILongPressGestureRecognizer) {
        if(sender.state == .began) {
        becomeFirstResponder()
        toggleKeyboardBar()
        }
    }
    
    func flush() {
        if(!hasBeenFlushedOnce) {
            hasBeenFlushedOnce = true
            DispatchQueue.main.async{ self.becomeFirstResponder()}
        }
        vimView?.flush()
    }
    
    func blinkCursorTimer() {
        blinkTimer?.invalidate()
        if(state == .on) {
            gui_undraw_cursor()
            state = .off
            let off_time = Double(blink_off)/1000.0
            blinkTimer = Timer.scheduledTimer(timeInterval: off_time, target:self, selector:#selector(VimViewController.blinkCursorTimer), userInfo:nil, repeats:false)
        }
        else if (state == .off) {
            gui_update_cursor(1, 0)
            state = .on
            let on_time = Double(blink_on)/1000.0
            blinkTimer = Timer.scheduledTimer(timeInterval: on_time, target:self, selector:#selector(VimViewController.blinkCursorTimer), userInfo:nil, repeats:false)
        }
        vimView?.setNeedsDisplay((vimView?.dirtyRect)!)
        
        
        
    }
    
    func startBlink() {
        blinkTimer?.invalidate()
        blinkTimer = Timer.scheduledTimer(timeInterval: Double(blink_wait)/1000.0, target: self,  selector: #selector(VimViewController.blinkCursorTimer), userInfo: nil, repeats: false)
        state = .on
        gui_update_cursor(1,0)
    }
    
    func stopBlink() {
        blinkTimer?.invalidate()
        state = .none
        blinkTimer=nil
    }

    
   override var canBecomeFirstResponder : Bool {
        return hasBeenFlushedOnce
    }
    
    override var canResignFirstResponder : Bool {
        return true
    }
    
    
   // MARK: UIKeyInput
    var hasText : Bool {
        return false
    }
    
    func insertText(_ text: String) {
        var escapeString = text.char
        if(text=="\n") {
            //print("Enter!")
            escapeString = UnicodeScalar(Int(keyCAR))!.description.char
        }
        
        becomeFirstResponder()
        let length = text.lengthOfBytes(using: String.Encoding.utf8)
        add_to_input_buf(escapeString, Int32(length))

        flush()
        vimView?.setNeedsDisplay((vimView?.dirtyRect)!)
    }
    
    func deleteBackward() {
            insertText(UnicodeScalar(Int(keyBS))!.description)
        
    }
    
    // Mark: UITextInputTraits
    
    var autocapitalizationType = UITextAutocapitalizationType.none
    var keyboardType = UIKeyboardType.default
    var autocorrectionType = UITextAutocorrectionType.no
    
    
    func toggleKeyboardBar() {
        if(inputAssistantItem.leadingBarButtonGroups.count == 0){
            let escButton = UIBarButtonItem(title: "ESC", style: .plain, target: self, action: #selector(VimViewController.handleBarButton(_:)))
            let tabButton = UIBarButtonItem(title: "TAB", style: .plain, target: self, action: #selector(VimViewController.handleBarButton(_:)))
            let f1Button = UIBarButtonItem(title: "F1", style: .plain, target: self, action: #selector(VimViewController.handleBarButton(_:)))
            inputAssistantItem.leadingBarButtonGroups += [UIBarButtonItemGroup(barButtonItems: [escButton, tabButton, f1Button], representativeItem: nil)]
        }
        else {
            inputAssistantItem.leadingBarButtonGroups=[]
            inputAssistantItem.trailingBarButtonGroups=[]
        }
        resignFirstResponder()
        becomeFirstResponder()
    }
    
    
    
    //MARK: OnScreen Keyboard Handling
    func keyboardWillShow(_ notification: Notification) {
        guard let vView = vimView else { return}
        let keyboardRect = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as AnyObject).cgRectValue
        let keyboardRectInViewCoordinates = view!.window!.convert(keyboardRect!, to: vimView)
        print("KeyboardWillShow \(keyboardRectInViewCoordinates)")
        
        vView.frame = CGRect(x: vView.frame.origin.x, y: vView.frame.origin.y, width: vView.frame.size.width, height: keyboardRectInViewCoordinates.origin.y)
        print("Did show!")
        
    
    }
    
    func keyboardDidShow(_ notification: Notification) {
    
    }
    func keyboardWillHide(_ notification: Notification) {
        keyboardWillShow(notification)
        print("Will Hide!")
    }
    
    func handleBarButton(_ sender: UIBarButtonItem) {
        switch sender.title! {
        case "ESC":
            insertText(UnicodeScalar(Int(keyESC))!.description)
        case "TAB":
            insertText(UnicodeScalar(Int(keyTAB))!.description)
        case "F1":
            do_cmdline_cmd("call feedkeys(\"\\<F1>\")".char)
        default: break
        }
    }

    
    func registerHotkeys(){
        keyCommandArray = []
        hotkeys.each { letter in
            [[], [.control], [.command],[.alternate]].map( {
            self.keyCommandArray! += [UIKeyCommand(input:  letter, modifierFlags:$0, action: #selector(VimViewController.keyPressed(_:)))]
            })
        }
        shiftableHotkeys.each{ letter in
            [[],[.control], [.shift], [.command],[.alternate]].map( {
            self.keyCommandArray! += [UIKeyCommand(input:  letter, modifierFlags: $0 , action: #selector(VimViewController.keyPressed(_:)))]
            })
        }
        self.keyCommandArray! += [UIKeyCommand(input:UIKeyInputEscape, modifierFlags: [], action: #selector(VimViewController.keyPressed(_:)))]
        self.keyCommandArray! += [UIKeyCommand(input:UIKeyInputDownArrow, modifierFlags: [], action: #selector(VimViewController.keyPressed(_:)))]
        self.keyCommandArray! += [UIKeyCommand(input:UIKeyInputUpArrow, modifierFlags: [], action: #selector(VimViewController.keyPressed(_:)))]
        self.keyCommandArray! += [UIKeyCommand(input:UIKeyInputLeftArrow, modifierFlags: [], action: #selector(VimViewController.keyPressed(_:)))]
        self.keyCommandArray! += [UIKeyCommand(input:UIKeyInputRightArrow, modifierFlags: [], action: #selector(VimViewController.keyPressed(_:)))]
        //print("Number of Hotkeys \(keyCommands?.count)")
    }
    
    func keyPressed(_ sender: UIKeyCommand) {
        let value = sender.input.lowercased().utf8CString[0]
        lastKeyPress = Date()
        //print("Input \(sender.input), Modifier \(sender.modifierFlags)")
        var vimModifier : UInt8 = 0x00
        var key:Any? {
            switch sender.modifierFlags.rawValue {
            case 0:
                switch sender.input {
                case UIKeyInputEscape:
                    return UnicodeScalar(Int(keyESC))!.description
                case UIKeyInputDownArrow:
                    do_cmdline_cmd("call feedkeys(\"\\<Down>\")".char)
                    return ""
                case UIKeyInputUpArrow:
                    do_cmdline_cmd("call feedkeys(\"\\<Up>\")".char)
                    return ""
                case UIKeyInputLeftArrow:
                    do_cmdline_cmd("call feedkeys(\"\\<Left>\")".char)
                    return ""
                case UIKeyInputRightArrow:
                    do_cmdline_cmd("call feedkeys(\"\\<Right>\")".char)
                    return ""
                default:
                    return sender.input.lowercased()
                }
                //                if(sender.input == UIKeyInputEscape){
                //                    return String(UnicodeScalar(Int(keyESC)))
                //                }
                //                else {
                //                    return sender.input.lowercaseString
            //                }
            case UIKeyModifierFlags.shift.rawValue:
                return sender.input
            case UIKeyModifierFlags.control.rawValue:
                let ret = Int(getCTRLKeyCode(sender.input))
                if ret == 0
                {
                    vimModifier |= MOD_MASK_CTRL
                    let result : [UInt8] = [CSI,KS_MODIFIER,vimModifier,UInt8(sender.input.lowercased().utf8CString[0])]
                    return result
                }
                else
                {
                    let result = UnicodeScalar(ret)!.description
                    return result
                }
            case UIKeyModifierFlags.command.rawValue:
                if sender.input == "`"
                {
                    self.start_ime(self)
                    return nil
                }
                vimModifier |= MOD_MASK_CMD
                let result : [UInt8] = [CSI,KS_MODIFIER,vimModifier,UInt8(sender.input.lowercased().utf8CString[0])]
                return result
            case UIKeyModifierFlags.alternate.rawValue:
                vimModifier |= MOD_MASK_ALT
                let result : [UInt8] = [CSI,KS_MODIFIER,vimModifier,UInt8(sender.input.lowercased().utf8CString[0])]
                return result
            default: return nil
            }
        }
        if let k = key as? String{
            insertText(k)
        }
        else if let k = key as? [UInt8]{
            becomeFirstResponder()
            add_to_input_buf(k, Int32(k.count))
            //print("called ",k)
            flush()
            vimView?.setNeedsDisplay((vimView?.dirtyRect)!)
        }
        
    }
    

    
    func waitForChars(_ wtime: Int) -> Int {
     //   //print("Wait \(wtime)")
        let passed = Date().timeIntervalSince(lastKeyPress)*1000
        var wait = wtime
        //print("Passed \(passed)")
        
        if(passed < 1000) {
            wait = 10
        } else if(wtime < 0 ){
            wait = 4000
        }
        
     
     //print("Wait2 \(wait)")
     
     let expirationDate = Date(timeIntervalSinceNow: Double(wait)/1000.0)
        RunLoop.current.acceptInput(forMode: RunLoopMode.defaultRunLoopMode, before: expirationDate)
     let delay = expirationDate.timeIntervalSinceNow
     return delay < 0 ? 0 : 1
    
    }
   
    
    func handle_select(_ selected_text: String){
        print("text is ",selected_text)
        UIPasteboard.general.setValue(selected_text, forPasteboardType: "public.text")
    }
    
    func showShareSheetForURL(_ url: URL, mode: String) {
        let height = view.bounds.size.height
        if(mode == "Share") {
            documentController = UIDocumentInteractionController(url:url);
            documentController?.presentOptionsMenu(from: CGRect(x: 0,y: height-10,width: 10,height: 10), in:view, animated: true)
        } else if (mode == "Activity") {
            do{
                let string = try String(contentsOf: url)
                activityController = UIActivityViewController(activityItems: [string], applicationActivities: nil)
                activityController?.popoverPresentationController?.sourceRect=CGRect(x: 0,y: height-10,width: 10,height: 10)
                activityController?.popoverPresentationController?.sourceView=vimView!
                present(activityController!, animated: true) {}
                
            }catch {}
            
        }
    }
    
    
    func pan(_ sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: vimView!)
        
        let diffX = translation.x/(vimView!.char_width)
        print("diffX \(diffX)")
        
        
        if(diffX <= 0) {
            let command = "call feedkeys(\"\(Int(floor(abs(diffX))))\\<C-w><\")"
            print(command)
            do_cmdline_cmd(command.char)
            //insertText("\(floor(diffX))"+String(UnicodeScalar(Int(getCTRLKeyCode("W"))))+"<")
            sender.setTranslation(CGPoint(x: translation.x-ceil(diffX)*vimView!.char_width, y:0 ), in: vimView!)
        }
        if(diffX > 0) {
            let command = "call feedkeys(\"\(Int(ceil(diffX)))\\<C-w>>\")"
            print(command)
            do_cmdline_cmd(command.char)
            //insertText("\(ceil(diffX))"+String(UnicodeScalar(Int(getCTRLKeyCode("W"))))+"<")
            sender.setTranslation(CGPoint(x: translation.x-floor(diffX)*vimView!.char_width, y:0), in: vimView!)
        }
        
        //while(diffX <= -1) {
        //    //do_cmdline_cmd("call feedkeys(\"\\<C-w><\")".char)
        //    insertText(String(UnicodeScalar(Int(getCTRLKeyCode("W"))))+"<")
        //    diffX++
        //}
        //while(diffX >= 1) {
        //    //do_cmdline_cmd("call feedkeys(\"\\<C-w>>\")".char)
        //    insertText(String(UnicodeScalar(Int(getCTRLKeyCode("W"))))+">")
        //    diffX--
        //}
        

    }
    /*
    func clickPan(sender: UIPanGestureRecognizer) {
        let clickLocation = sender.locationInView(vimView!)
        var event = mouseDRAG
        switch sender.state {
        case .Began:
            event = mouseLEFT;
            break
        case .Ended:
            event = mouseRELEASE
            break
        default:
            event = mouseDRAG
            break
        }
        gui_send_mouse_event(event, Int32(clickLocation.x), Int32(clickLocation.y), 1, 0)
        
    }*/
    func scroll(_ sender: UIPanGestureRecognizer) {
        if(sender.state == .began) {
            becomeFirstResponder()
            let clickLocation = sender.location(in: sender.view)
            gui_send_mouse_event(0, Int32(clickLocation.x), Int32(clickLocation.y), 1,0)
        }
        
        let translation = sender.translation(in: vimView!)
    
        var diffY = translation.y/(vimView!.char_height)
        
        
//        print("Vorher \(diffY): \(ceil(diffY))")
        
        if(diffY <= -1) {
            sender.setTranslation(CGPoint(x: 0, y: translation.y-ceil(diffY)*vimView!.char_height), in: vimView!)
        }
        if(diffY >= 1) {
            sender.setTranslation(CGPoint(x:0,y: translation.y-floor(diffY)*vimView!.char_height), in: vimView!)
        }
        while(diffY <= -1){
            //gui_send_mouse_event(MOUSE_5, Int32(clickLocation.x), Int32(clickLocation.y), 0, 0);
            insertText(UnicodeScalar(Int(getCTRLKeyCode("E")))!.description)
            diffY += 1
        }
        while(diffY >= 1) {
            insertText(UnicodeScalar(Int(getCTRLKeyCode("Y")))!.description)
            //gui_send_mouse_event(MOUSE_4, Int32(clickLocation.x), Int32(clickLocation.y), 0, 0);
            diffY -= 1
            
        }
    }
    
    
    func get_pasteboard_text(_ sender:Any?) -> String?{
        if let data = UIPasteboard.general.data(forPasteboardType: "public.text"),
        let k = String(data: data,encoding: .utf8)
        {
            return k
        }
        return nil
    }
    
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action.description == "paste:" {
            var vimModifier : UInt8 = 0x00
            vimModifier |= MOD_MASK_CMD
            let result : [UInt8] = [CSI,KS_MODIFIER,vimModifier,UInt8("v".utf8CString[0])]
            becomeFirstResponder()
            add_to_input_buf(result, Int32(result.count))
            flush()
            vimView?.setNeedsDisplay((vimView?.dirtyRect)!)
            return false
        }
        else if action.description == "copy:"{
            return false
        }
        return true
    }
    
}
