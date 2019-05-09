//
//  UlamSpiralView.swift
//  UlamSpiral
//
//  Created by Rafael Grigorian on 5/7/19.
//  Copyright © 2019 Rafael Grigorian. All rights reserved.
//

import Foundation
import ScreenSaver


final class UlamSpiralView: ScreenSaverView {

    private var context: CGContext! = nil
    private var shouldClearBackground: Bool! = nil
    private var shouldRepeat: Bool! = nil
    private var direction: Direction! = nil
    private var limit: NSInteger! = nil
    private var current: NSInteger! = nil
    private var counter: NSInteger! = nil
    private var offset: NSSize! = nil
    private var cellSize: NSSize! = nil
    private var gridSize: NSSize! = nil
    private var gridPoint: NSPoint! = nil
    private var primes: [NSPoint]! = nil
    private var points: [NSPoint]! = nil
    
    private var optionDebug: Bool! = false
    private var optionSize: NSInteger! = 8
    private var optionShowCurrent: Bool! = true
    private var optionSpeed: TimeInterval! = TimeInterval ( 0.01 )
    private var optionBackgroundColor: NSColor! = NSColor.black
    private var optionPrimeColor: NSColor! = NSColor.yellow
    private var optionNonPrimeColor: NSColor! = NSColor ( red: 1.0, green: 1.0, blue: 1.0, alpha: 0.1 )
    
    private enum Direction {
        case right, up, left, down
    }
    
    override init ? ( frame: NSRect, isPreview: Bool ) {
        // Run super constuctor
        super.init ( frame: frame, isPreview: isPreview )
        // Initialize class data
        self.setInitialValues ()
        // Override options for preview
        if ( isPreview ) {
            self.optionDebug = false
            self.optionSize = 16
            self.optionShowCurrent = false
            self.optionSpeed = TimeInterval ( 0.05 )
            self.optionBackgroundColor = NSColor.black
            self.optionPrimeColor = NSColor.yellow
            self.optionNonPrimeColor = NSColor ( red: 1.0, green: 1.0, blue: 1.0, alpha: 0.1 )
        }
    }
    
    required init ? ( coder: NSCoder ) {
        // Throw an error if this constructor is used
        fatalError ()
    }
    
    private func setInitialValues () {
        self.animationTimeInterval = self.optionSpeed
        self.shouldClearBackground = true
        self.shouldRepeat = true
        self.direction = Direction.right
        self.limit = 1
        self.current = 0
        self.counter = 1
        self.cellSize = NSSize ( width: self.optionSize, height: self.optionSize )
        self.gridSize = NSSize (
            width: NSInteger ( floor ( self.bounds.width / self.cellSize.width ) ),
            height: NSInteger ( floor ( self.bounds.height / self.cellSize.height ) )
        )
        if ( gridSize.width.truncatingRemainder ( dividingBy: 2 ) == 0 ) {
            gridSize.width += 1
        }
        if ( gridSize.height.truncatingRemainder ( dividingBy: 2 ) == 0 ) {
            gridSize.height += 1
        }
        self.gridPoint = NSPoint (
            x: NSInteger ( floor ( gridSize.width / 2 ) ),
            y: NSInteger ( floor ( gridSize.height / 2 ) )
        )
        self.points = [ self.gridPoint ]
        self.primes = []
        self.offset = NSSize (
            width: ( self.bounds.width - ( self.gridSize.width * self.cellSize.width ) ) / 2,
            height: ( self.bounds.height - ( self.gridSize.height * self.cellSize.height ) ) / 2
        )
    }
    
    override func draw ( _ rect: NSRect ) {
        // Run method from super class
        super.draw ( rect )
        // Save context internally
        context = NSGraphicsContext.current!.cgContext
        // Clear background, if needed
        self.clearBackground ()
        // Draw points on grid
        for point in self.primes {
            self.drawOnGrid ( point: point, color: self.optionPrimeColor )
        }
        for point in self.points {
            self.drawOnGrid ( point: point, color: self.optionNonPrimeColor )
        }
        // If option is checked to show current cell
        if ( self.optionShowCurrent ) {
            // Draw current cell on grid
            self.drawOnGrid ( point: self.gridPoint, color: self.optionPrimeColor )
        }
        // Draw variable values if debug mode is on
        if ( self.optionDebug ) {
            self.drawText ( text: "Direction: \(self.direction!)", point: NSPoint ( x: 25, y: 105 ) )
            self.drawText ( text: "Counter:   \(self.counter!)", point: NSPoint ( x: 25, y: 85 ) )
            self.drawText ( text: "Current:   \(self.current!)", point: NSPoint ( x: 25, y: 65 ) )
            self.drawText ( text: "Limit:     \(self.limit!)", point: NSPoint ( x: 25, y: 45 ) )
            self.drawText ( text: "Repeat:    \(self.shouldRepeat!)", point: NSPoint ( x: 25, y: 25 ) )
        }
    }
    
    override func animateOneFrame () {
        // Run method from super class
        super.animateOneFrame ()
        // Trigger redraw
        needsDisplay = true
        // Increment data
        if ( self.current >= self.limit ) {
            if ( self.shouldRepeat ) {
                self.shouldRepeat = false
            }
            else {
                self.shouldRepeat = true
                self.limit += 1
            }
            self.current = 0
            advanceDirection ()
        }
        self.current += 1
        self.counter += 1
        advanceGridPoint ()
        // Based on if current is prime, add to appropriate color array
        if ( self.isPrime ( self.counter ) ) {
            self.primes.append ( self.gridPoint )
        }
        else {
            self.points.append ( self.gridPoint )
        }
        // Test if everything should be reset
        let maxCounter = pow ( max ( self.gridSize.width, self.gridSize.height ), 2 )
        if ( NSInteger ( maxCounter ) < self.counter ) {
            self.setInitialValues ()
        }
    }
    
    private func drawText ( text: String, point: NSPoint, color: NSColor! = NSColor.white ) {
        let attributes = [
            NSAttributedString.Key.font: NSFont ( name: "Monaco", size: 16.0 ),
            NSAttributedString.Key.foregroundColor: color
        ]
        text.draw ( at: point, withAttributes: attributes as [NSAttributedString.Key : Any] )
    }
    
    private func drawOnGrid ( point: NSPoint, color: NSColor = NSColor.darkGray ) {
        context.setFillColor ( color.cgColor )
        context.fillEllipse (
            in: NSRect (
                x: ( point.x * self.cellSize.width ) + ( self.cellSize.width * 0.25 ) + self.offset.width,
                y: ( point.y * self.cellSize.height ) + ( self.cellSize.height * 0.25 ) + self.offset.height,
                width: self.cellSize.width * 0.5,
                height: self.cellSize.height * 0.5
            )
        )
    }
    
    private func advanceGridPoint () {
        switch self.direction! {
            case Direction.right:
                return self.gridPoint.x += 1
            case Direction.up:
                return self.gridPoint.y += 1
            case Direction.left:
                return self.gridPoint.x -= 1
            case Direction.down:
                return self.gridPoint.y -= 1
        }

    }
    
    private func advanceDirection () {
        switch self.direction! {
            case Direction.right:
                return self.direction = Direction.up
            case Direction.up:
                return self.direction = Direction.left
            case Direction.left:
                return self.direction = Direction.down
            case Direction.down:
                return self.direction = Direction.right
        }
    }
    
    private func clearBackground () {
        // Check to see if we should clear the screen
        if ( self.shouldClearBackground ) {
            // Reset flag and fill screen with background color
            self.shouldClearBackground = !self.shouldClearBackground
            context.setFillColor ( self.optionBackgroundColor.cgColor )
            context.fill ( self.bounds )
        }
        // Draw grid filled (debug mode)
        if ( self.optionDebug ) {
            for i in 0 ..< NSInteger ( self.gridSize.width ) {
                for j in 0 ..< NSInteger ( self.gridSize.height ) {
                    self.drawOnGrid ( point: NSPoint ( x: i, y: j ), color: self.optionNonPrimeColor )
                }
            }
            
        }
    }
    
    func isPrime ( _ n: Int ) -> Bool {
        guard n >= 2 else { return false }
        guard n != 2 else { return true }
        guard n % 2 != 0 else { return false }
        return !stride (
            from: 3,
            through: Int ( sqrt ( Double ( n ) ) ),
            by: 2
        ).contains { n % $0 == 0 }
    }
    
    override var hasConfigureSheet: Bool {
        return false
    }
    
    override var configureSheet: NSWindow? {
        return nil
    }
    
}
