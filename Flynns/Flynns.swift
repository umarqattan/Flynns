//
//  Flynns.swift
//  Flynns
//
//  Created by Umar Qattan on 12/15/18.
//  Copyright © 2018 ukaton. All rights reserved.
//

import Foundation
import UIKit

struct Constants {
    static let sensorCount = 8
    static let sensorSensitivity = 25
    static let labelCount = 4
}

enum SensorPosition {
    case upper, lower, whole
}

struct Sensor {
    var position: SensorPosition
    var value: Int
    
    init(position: SensorPosition, value: Int) {
        self.position = position
        self.value = value
    }
}

class Flynns {
    
    var left: [Sensor] = [Sensor]()
    var right: [Sensor] = [Sensor]()
    var currentRotation: CGFloat = 0
    var currentScroll: CGFloat = 0
    var currentSlide: Float = 0
    
    init(leftSensorValues: [Int], rightSensorValues: [Int]) {
        for i in 0..<Constants.sensorCount {
            if i < Constants.sensorCount / 2 {
                self.left.append(Sensor(position: .lower, value: leftSensorValues[i]))
                self.right.append(Sensor(position: .lower, value: rightSensorValues[i]))
            } else {
                self.left.append(Sensor(position: .upper, value: leftSensorValues[i]))
                self.right.append(Sensor(position: .upper, value: rightSensorValues[i]))
            }
        }
    }
    
    func update(leftSensorValues: [Int], rightSensorValues: [Int]) {
        for i in 0..<Constants.sensorCount {
            if i < Constants.sensorCount / 2 {
                self.left.append(Sensor(position: .lower, value: leftSensorValues[i]))
                self.right.append(Sensor(position: .lower, value: rightSensorValues[i]))
            } else {
                self.left.append(Sensor(position: .upper, value: leftSensorValues[i]))
                self.right.append(Sensor(position: .upper, value: rightSensorValues[i]))
            }
        }
    }
    
    func upperLeftSensors() -> [Sensor] {
        return self.left.filter({ $0.position == .upper })
    }
    
    func lowerRightSensors() -> [Sensor] {
        return self.right.filter({ $0.position == .lower })
    }
    
    func leftSum(position: SensorPosition) -> Int {
        return self.left.filter({$0.position == position}).map({$0.value}).reduce(0, +)
    }
    
    func rightSum(position: SensorPosition) -> Int {
        return self.right.filter({$0.position == position}).map({$0.value}).reduce(0, +)
    }
    
    func normalizeRotation() -> CGFloat {
        // 1. Divide the currentRotation by the product of the number of sensors per insole and the maximum value
        //    a sensor can read
        //    [-100 * Constants.sensorCount, 100 * Constants.sensorCount]
        // 2. Multiply the normalized currentRotation by 2 * pi to get the rotation in terms of a circle
        //    [-1, 1]
        // 3. [-2 * pi, 2 * pi]
        return self.currentRotation / CGFloat(Constants.sensorCount * 100) * 2 * .pi
    }
    
    func normalizeScroll() -> CGFloat {
        return self.currentScroll / CGFloat(Constants.sensorCount * 100)
    }
    
    func normalizeSlide() -> Float {
        return self.currentSlide / Float(Constants.sensorCount * 100)
    }
    
    func updateRotation(for view: UIView) {
        guard self.leftSum(position: .whole) > Constants.sensorSensitivity || self.rightSum(position: .whole) > Constants.sensorSensitivity else {
            debugPrint("Pressure does not meet the minimum threshold.")
            return
        }
        
        // sensors that influence clockwise rotation
        self.currentRotation -= CGFloat(self.rightSum(position: .upper))
        self.currentRotation -= CGFloat(self.leftSum(position: .lower))
        
        // sensors that influence counter clockwise rotation
        self.currentRotation += CGFloat(self.rightSum(position: .lower))
        self.currentRotation += CGFloat(self.leftSum(position: .upper))
        
        self.currentRotation = self.normalizeRotation()
        view.transform = CGAffineTransform(rotationAngle: self.currentRotation)
    }
    
    func updateScroll(for scrollView: UIScrollView) {
        guard self.leftSum(position: .whole) > Constants.sensorSensitivity || self.rightSum(position: .whole) > Constants.sensorSensitivity else {
            debugPrint("Pressure does not meet the minimum threshold.")
            return
        }

        // right sensors influence upward scrolling
        self.currentScroll -= CGFloat(self.rightSum(position: .whole))
        // left sensors influence downward scrolling
        self.currentScroll += CGFloat(self.leftSum(position: .whole))
        
        self.currentScroll = self.normalizeScroll()
        
        var bounds = scrollView.bounds
        bounds.origin = CGPoint(x: scrollView.contentOffset.x, y: scrollView.contentOffset.y + self.currentScroll)
        scrollView.bounds = bounds
    }
    
    func updateSlide(for slider: UISlider) {
        guard self.leftSum(position: .whole) > Constants.sensorSensitivity || self.rightSum(position: .whole) > Constants.sensorSensitivity else {
            debugPrint("Pressure does not meet the minimum threshold.")
            return
        }
        // right sensors move slider to the right
        self.currentSlide += Float(self.rightSum(position: .whole))
        
        // left sensors move slider to the left
        self.currentSlide -= Float(self.leftSum(position: .whole))
        
        self.currentSlide = self.normalizeSlide()
        slider.setValue(self.currentSlide, animated: true)
    }
    
    func updateLabels(for labels: [UILabel]) {
        guard labels.count == Constants.labelCount else { fatalError("Label count must equal Constants.label count.")}
        
        // labels order: lower right, upper right, lower left, upper left
        let sensorContributionCount = Constants.sensorCount / Constants.labelCount
        labels[0].text = "\(self.rightSum(position: .lower) / sensorContributionCount)"
        labels[1].text = "\(self.rightSum(position: .upper) / sensorContributionCount)"
        labels[2].text = "\(self.leftSum(position: .lower) / sensorContributionCount)"
        labels[3].text = "\(self.rightSum(position: .upper) / sensorContributionCount)"
    }
}

enum Feature {
    case rotate
    case scroll
    case slide
    case pan
}
