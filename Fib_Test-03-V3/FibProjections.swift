//
//  FibProjections.swift
//
//  Created by Ryan Mooney on 9/5/16.
//  Copyright © 2016 Ryan Mooney. All rights reserved.
//

import Foundation
class FibProjections {
    
    func calcProjections(yValues: [[Double]], highValues: [Double], lowValues: [Double]) -> (L2H: [[Double?]], H2L: [[Double?]]) {

        //High and low values from ZigZag indicator
        let highPoints = highValues
        let lowPoints = lowValues
        let yCandles = yValues
        var highAtIndex: [(high: Double, index: Int)] = []
        var lowAtIndex: [(low: Double, index: Int)] = []
        
        //Multidemensional array for low to high projections
        var L2H_Projections: [[Double?]] = []
        //Multidemensional array for low to high projections
        var H2L_Projections: [[Double?]] = []
        
        //Put highs into a tuple array of (high price, index at high point)
        for i in 0..<highPoints.count {
            if highPoints[i] != 0{
                highAtIndex.append((highPoints[i], i))
            }
        }
        
        //Put lows into a tuple array of (low price, index at low point)
        for i in 0..<lowPoints.count {
            if lowPoints[i] != 0{
                lowAtIndex.append((lowPoints[i], i))
            }
        }

        //Determine if the first ZigZag point is a high or a low
        enum FirstPoint: Int {
            case initial = 1, high, low
            init() {
                self = .initial
            }
        }
        var firstPoint: FirstPoint
        
        //Set the enum with the lower (first) of the two points index values
        if highAtIndex[0].index < lowAtIndex[0].index {
            firstPoint = FirstPoint.high
        }else if lowAtIndex[0].index < highAtIndex[0].index{
            firstPoint = FirstPoint.low
        }else { firstPoint = FirstPoint.initial }
        
        //_______________________________________________________________________________________________________
        //_______________________________________________________________________________________________________
        
        //Get the last low and its index
        let lastLow = lowAtIndex[lowAtIndex.count-1].low
        let lastLowIndex = lowAtIndex[lowAtIndex.count-1].index
        
        var indexMaxL2H: Int
        
        if firstPoint == FirstPoint.high &&  highAtIndex.count == lowAtIndex.count {
            indexMaxL2H = lowAtIndex.count-1
        }else {
            indexMaxL2H = min(highAtIndex.count, lowAtIndex.count)
        }
        
        for ii in 0..<indexMaxL2H {
            var L2H_span: Double
            //Get the span of the high to low
            if firstPoint == FirstPoint.low {
                L2H_span = highAtIndex[ii].high - lowAtIndex[ii].low
            } else {
                L2H_span = highAtIndex[ii+1].high - lowAtIndex[ii].low
            }

            //Check to see if projection is above highs made since last low
            var SpanValid: Bool = true
            for iH in lastLowIndex..<yCandles.count {
                if getHigh(yCandles, idx: iH) > (lastLow + L2H_span) {
                    SpanValid = false
                }
            }
            
            var L2H_ProjectionValue: Double
            
            //Add the span to the last low if the projection is valid else "0"
            if SpanValid == true {
                L2H_ProjectionValue = (lastLow + L2H_span)
            } else { L2H_ProjectionValue = 0 }
            
            var L2H_Projection: [Double?] = []
            
            //If projection is not "0" then create the plot with zeros
            if L2H_ProjectionValue != 0 {
                for i in 0..<highPoints.count {
                    if i < lastLowIndex {
                        L2H_Projection.append(nil)
                    } else if i == lastLowIndex {
                        L2H_Projection.append(L2H_ProjectionValue)
                    }else if i == highPoints.count-1 {
                        L2H_Projection.append(L2H_ProjectionValue)
                    } else { L2H_Projection.append(nil) }
                }
                //Add plot with zeros to multidemensional array
                L2H_Projections.append(L2H_Projection)
            }
          }
 
        //_______________________________________________________________________________________________________
        //_______________________________________________________________________________________________________
        
        //Get the last high and its index
        let lastHigh = highAtIndex[highAtIndex.count-1].high
        let lastHighIndex = highAtIndex[highAtIndex.count-1].index
        
        var indexMaxH2L: Int
        
        if firstPoint == FirstPoint.low &&  highAtIndex.count == lowAtIndex.count {
            indexMaxH2L = highAtIndex.count-1
        }else {
            indexMaxH2L = min(highAtIndex.count, lowAtIndex.count)
        }
        
        for ii in 0..<indexMaxH2L {
            var H2L_span: Double
            //Get the span of the high to low
            if firstPoint == FirstPoint.high {
                H2L_span = highAtIndex[ii].high - lowAtIndex[ii].low
            } else {
                H2L_span = highAtIndex[ii].high - lowAtIndex[ii+1].low
            }
            
            //Check to see if projection is below lows made since last low
            var SpanValid: Bool = true
            for iL in lastHighIndex..<yCandles.count {
                if getLow(yCandles, idx: iL) < (lastHigh - H2L_span) {
                    SpanValid = false
                }
            }
            
            var H2L_ProjectionValue: Double
            
            //Add the span to the last low if the projection is valid else "0"
            if SpanValid == true {
                H2L_ProjectionValue = (lastHigh - H2L_span)
            } else { H2L_ProjectionValue = 0 }
            
            var H2L_Projection: [Double?] = []
            
            //If projection is not "0" then create the plot with zeros
            if H2L_ProjectionValue != 0 {
                for i in 0..<lowPoints.count {
                    if i < lastHighIndex {
                        H2L_Projection.append(nil)
                    } else if i == lastHighIndex {
                        H2L_Projection.append(H2L_ProjectionValue)
                    }else if i == highPoints.count-1 {
                        H2L_Projection.append(H2L_ProjectionValue)
                    } else { H2L_Projection.append(nil) }
                }
                //Add plot with zeros to multidemensional array
                H2L_Projections.append(H2L_Projection)
            }
        }
        
        //Return both L2H and H2L multi arrays
        return (L2H_Projections, H2L_Projections)
        
    }

    
    //__________________________________________________________________________________________________
    //__________________________________________________________________________________________________
    //__________________________________________________________________________________________________
    
    
    func getHigh(yValues: [[Double]], idx: Int) -> Double {
        return yValues[idx][1]
    }
    
    func getLow(yValues: [[Double]], idx: Int) -> Double {
        return yValues[idx][2]
    }
    
}