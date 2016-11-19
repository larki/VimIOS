//
//  VimView.swift
//  VimIOS
//
//  Created by Lars Kindler on 31/10/15.
//  Copyright © 2015 Lars Kindler. All rights reserved.
//

import UIKit
import CoreText

struct font{
    static let name = "Menlo-Regular"
    static let size =  CGFloat(14)
}

struct FontProperties{
}

class VimView: UIView {
    var dirtyRect = CGRect.zero
    var shellLayer : CGLayer?
    var shellSize = 1366
    
    var char_ascent=CGFloat(0)
    var char_width=CGFloat(0)
    var char_height=CGFloat(0)
    
    var bgcolor:CGColor?
    var fgcolor:CGColor?
    var spcolor:CGColor?
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        shellSize = max(Int(UIScreen.main.bounds.width), Int(UIScreen.main.bounds.height))
        
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    override func draw(_ rect: CGRect) {
        guard let layer = shellLayer else {
            let scale = UIScreen.main.scale
            
            shellLayer = CGLayer(UIGraphicsGetCurrentContext()!, size: CGSize(width: CGFloat(shellSize)*scale, height: CGFloat(shellSize)*scale), auxiliaryInfo: nil)
            let layerContext = shellLayer!.context
            
            layerContext!.scaleBy(x: scale,y: scale)
            return
        }
        //print("DrawRect \(rect)")
        
        if( !rect.equalTo(CGRect.zero)) {
            let context = UIGraphicsGetCurrentContext()
            context!.saveGState()
            context!.beginPath()
            context!.addRect(rect)
            context!.clip()
            let bounds = CGRect(x: 0,y: 0,width: CGFloat(shellSize),height: CGFloat(shellSize))
            context!.draw(layer, in: bounds)
            context!.restoreGState()
            dirtyRect=CGRect.zero
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        resizeShell()
    }
    
    func resizeShell() {
        print("Resizing to \(frame)")
        gui_resize_shell(CInt(frame.width), CInt(frame.height))
    }
    
    
    
    func CGLayerCopyRectToRect(_ layer: CGLayer? , sourceRect: CGRect , targetRect: CGRect) {
        guard let layer = layer else {return}
        
        let context = layer.context
        
        var destinationRect = targetRect
        destinationRect.size.width = min(targetRect.size.width, sourceRect.size.width)
        destinationRect.size.height = min(targetRect.size.height, sourceRect.size.height)
        
        context!.saveGState()
        
        context!.beginPath()
        context!.addRect(destinationRect)
        context!.clip()
        let size = layer.size
        
        context!.draw(layer, in: CGRect(x: destinationRect.origin.x - sourceRect.origin.x, y: destinationRect.origin.y - sourceRect.origin.y, width: size.width/2, height: size.height/2))
        //    CGContextDrawLayerAtPoint(context, CGPointMake(destinationRect.origin.x - sourceRect.origin.x, destinationRect.origin.y - sourceRect.origin.y), layer);
        
        
        dirtyRect = dirtyRect.union(destinationRect)
        context!.restoreGState()
    }
    func CGLayerCopyRectToRect(_ sourceRect: CGRect , targetRect: CGRect) {
        CGLayerCopyRectToRect(shellLayer, sourceRect: sourceRect, targetRect: targetRect)
    }

    func flush(){
        shellLayer!.context!.flush()
        self.setNeedsDisplay(dirtyRect)
//        if(dirtyRect.height>1) {
//                print(dirtyRect)
//        }
        
        
    }
    
    func clearAll() {
        if let layer = shellLayer {
        let  size = layer.size
        
        fillRectWithColor(CGRect(x: 0,y: 0,width: size.width,height: size.height), color: bgcolor ?? UIColor.black.cgColor)
        dirtyRect=self.bounds
   //         print("ClearALL \(CGColorGetComponents(bgcolor)), \(size.width), \(size.height), \(self.bounds)")
        self.setNeedsDisplay(dirtyRect)
        }
    }
    
    func fillRectWithColor(_ rect: CGRect, color: CGColor?) {
            //print("In fillRectWithColor \(rect), \(color)")
        if let layer = shellLayer, let color = color {
            let context = layer.context
            context!.setFillColor(color)
            context!.fill(rect)
            dirtyRect = dirtyRect.union(rect)
            self.setNeedsDisplay(dirtyRect)
            }
    }
    
    func drawString(_ s:NSAttributedString,
        font: CTFont,
        pos_x:CGFloat,
        pos_y: CGFloat,
        rect:CGRect,
        p_antialias: Bool,
        transparent: Bool,
        cursor: Bool) {
            
            guard let context = shellLayer!.context else{ return}
            context.setShouldAntialias(p_antialias);
            context.setAllowsAntialiasing(p_antialias);
            context.setShouldSmoothFonts(p_antialias);
            
            context.setCharacterSpacing(0);
            context.setTextDrawingMode(.fill)
            
            
            if(transparent) {
                context.setFillColor(bgcolor!)
                context.fill(rect)
            }
            
            
            context.setFillColor(fgcolor!);
//            let attributes : [String:AnyObject] = ([NSFontAttributeName:font, (kCTForegroundColorFromContextAttributeName as String):true])
//            
//            let attributesNeu = NSDictionary(dictionaryLiteral: (NSFontAttributeName, font) (kCTForegroundColorFromContextAttributeName, true))
//            
//            let attString = NSAttributedString(string: s as String, attributes: attributes)
            
            
            let line = CTLineCreateWithAttributedString(s)
            context.textPosition = CGPoint(x: pos_x, y: pos_y)
            CTLineDraw(line, context)
            
            if(cursor) {
                context.saveGState();
                context.setBlendMode(.difference)
                context.fill(rect)
                context.restoreGState()
            }
            
            
            
            
            dirtyRect = dirtyRect.union(rect);
          //  print("Draw String \(s) at \(pos_x), \(pos_y) and \(dirtyRect)")
            
    }
    
    func initFont() -> CTFont {
        let rawFont = CTFontCreateWithName(font.name as CFString, font.size, nil)
        
        var boundingRect = CGRect.zero;
        var glyph = CTFontGetGlyphWithName(rawFont, "0" as CFString)
       
        let glyphPointer = withUnsafePointer(to: &glyph) {(pointer: UnsafePointer<CGGlyph>) -> UnsafePointer<CGGlyph> in return pointer}
        
        withUnsafeMutablePointer(to: &boundingRect) { (pointer:UnsafeMutablePointer<CGRect>) in
        CTFontGetBoundingRectsForGlyphs(rawFont, .horizontal, glyphPointer, pointer, 1)
        }
        
        
        char_ascent = CTFontGetAscent(rawFont)
        char_width = boundingRect.width
        char_height = boundingRect.height+3


        var advances = CGSize.zero
        withUnsafeMutablePointer(to: &advances, {(pointer: UnsafeMutablePointer<CGSize>) in
            CTFontGetAdvancesForGlyphs(rawFont, .horizontal, glyphPointer, pointer, 1)});
        
        var transform = CGAffineTransform(scaleX: boundingRect.width/advances.width, y: -1)
        
        return withUnsafePointer(to: &transform, {
            (t:UnsafePointer<CGAffineTransform>) -> CTFont in
            return CTFontCreateCopyWithAttributes(rawFont, font.size,t , nil)})
    
    }

    
    
    
}
