//
//  FibRetracements.swift
//
//  Created by Ryan Mooney on 9/6/16.
//  Copyright © 2016 Ryan Mooney. All rights reserved.
//

import Foundation
import Charts
class FibRetracements {
    //
    func calcRetracements(yValues: [[Double]], highValues: [Double], lowValues: [Double]) -> (L2H: [[Double?]], H2L: [[Double?]], L2H_Colors: [NSUIColor], H2L_Colors: [NSUIColor]) {
        
        //High and low values from ZigZag indicator
        let highPoints = highValues
        let lowPoints = lowValues
        let yCandles = yValues
        var highAtIndex: [(high: Double, index: Int)] = []
        var lowAtIndex: [(low: Double, index: Int)] = []
        
        //Multidemensional and color arrays for low to high retracements
        var L2H_Retracements: [[Double?]] = []
        var L2H_RetracementsColors: [NSUIColor] = []
        
        //Multidemensional  and color arrays for low to high retracements
        var H2L_Retracements: [[Double?]] = []
        var H2L_RetracementsColors: [NSUIColor] = []
        
        //_______________________________________________________________________________________________________
        
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
        
        var indexMaxL2H: Int
        
        if firstPoint == FirstPoint.high &&  highAtIndex.count == lowAtIndex.count {
           indexMaxL2H = lowAtIndex.count-1
        }else {
            indexMaxL2H = min(highAtIndex.count, lowAtIndex.count)
        }
        
        for ii in 0..<indexMaxL2H {
            var Retracements: [Double] = []
            var L2H_span: Double

            //Set the first high based on the first point in the high/low points
            var currentHigh: Double
            var currentHighIndex: Int
            if firstPoint == FirstPoint.low {
                currentHigh = highAtIndex[ii].high
                currentHighIndex = highAtIndex[ii].index
            } else {
                currentHigh = highAtIndex[ii+1].high
                currentHighIndex = highAtIndex[ii+1].index
            }
            
            //Get the span of the high to low
            L2H_span = currentHigh - lowAtIndex[ii].low
            
            //Calculate the retracements for the current swing
            Retracements.append( currentHigh - (L2H_span * 0.236) )
            Retracements.append( currentHigh - (L2H_span * 0.382) )
            Retracements.append( currentHigh - (L2H_span * 0.5) )
            Retracements.append( currentHigh - (L2H_span * 0.618) )
            Retracements.append( currentHigh - (L2H_span * 0.786) )
            Retracements.append( currentHigh - (L2H_span * 1.272) )
            Retracements.append( currentHigh - (L2H_span * 1.618) )
            Retracements.append( currentHigh - (L2H_span * 2.618) )
            
            //Set the retracement(s) to zero if they are no longer valid
            for iL in currentHighIndex..<yCandles.count {
                for iR in 0..<Retracements.count {
                    if getLow(yCandles, idx: iL) < Retracements[iR] {
                        Retracements[iR] = 0
                    }
                }
            }
            
            //_______________________________________________________________________________________________________
            
            //If retracement is not "0" then create the plot with nil values
            for iRet in 0..<Retracements.count {
                if Retracements[iRet] != 0 {
                    var L2H_Retracement: [Double?] = []
                    for i in 0..<lowPoints.count {
                        if i < lowAtIndex[ii].index {
                            L2H_Retracement.append(nil)
                        } else if i == lowAtIndex[ii].index {
                            L2H_Retracement.append(Retracements[iRet])
                        }else if i == highPoints.count-1 {
                            L2H_Retracement.append(Retracements[iRet])
                        } else { L2H_Retracement.append(nil) }
                    }
                    
                    //Add plot with nil values to multidemensional array
                    L2H_Retracements.append(L2H_Retracement)
                    
                    //Add color to array
                    switch iRet {
                    case 0:
                        L2H_RetracementsColors.append(NSUIColor(red: 102/255, green: 102/255, blue: 255/255, alpha: 1))
                    case 1:
                        L2H_RetracementsColors.append(NSUIColor(red: 51/255, green: 51/255, blue: 255/255, alpha: 1))
                    case 2:
                        L2H_RetracementsColors.append(NSUIColor(red: 0/255, green: 0/255, blue: 255/255, alpha: 1))
                    case 3:
                        L2H_RetracementsColors.append(NSUIColor(red: 255/255, green: 153/255, blue: 255/255, alpha: 1))
                    case 4:
                        L2H_RetracementsColors.append(NSUIColor(red: 204/255, green: 153/255, blue: 255/255, alpha: 1))
                    case 5:
                        L2H_RetracementsColors.append(NSUIColor(red: 102/255, green: 255/255, blue: 102/255, alpha: 1))
                    case 6:
                        L2H_RetracementsColors.append(NSUIColor(red: 0/255, green: 153/255, blue: 0/255, alpha: 1))
                    case 7:
                        L2H_RetracementsColors.append(NSUIColor(red: 0/255, green: 102/255, blue: 0/255, alpha: 1))
                    default: break
                    }
                    
                }
            }

        }
 
        
        //_______________________________________________________________________________________________________
        //_______________________________________________________________________________________________________

        var indexMaxH2L: Int
        
        if firstPoint == FirstPoint.low &&  highAtIndex.count == lowAtIndex.count {
            indexMaxH2L = highAtIndex.count-1
        }else {
            indexMaxH2L = min(highAtIndex.count, lowAtIndex.count)
        }
        
        for ii in 0..<indexMaxH2L {
            var Retracements: [Double] = []
            var H2L_span: Double
            
            //Set the first high based on the first point in the high/low points
            var currentLow: Double
            var currentLowIndex: Int
            if firstPoint == FirstPoint.high {
                currentLow = lowAtIndex[ii].low
                currentLowIndex = lowAtIndex[ii].index
            } else {
                currentLow = lowAtIndex[ii+1].low
                currentLowIndex = lowAtIndex[ii+1].index
            }
            
            //Get the span of the high to low
            H2L_span = highAtIndex[ii].high - currentLow
            
            //Calculate the retracements for the current swing
            Retracements.append( currentLow + (H2L_span * 0.236) )
            Retracements.append( currentLow + (H2L_span * 0.382) )
            Retracements.append( currentLow + (H2L_span * 0.5) )
            Retracements.append( currentLow + (H2L_span * 0.618) )
            Retracements.append( currentLow + (H2L_span * 0.786) )
            Retracements.append( currentLow + (H2L_span * 1.272) )
            Retracements.append( currentLow + (H2L_span * 1.618) )
            Retracements.append( currentLow + (H2L_span * 2.618) )
            
            //Set the retracement(s) to zero if they are no longer valid
            for iH in currentLowIndex..<yCandles.count {
                for iR in 0..<Retracements.count {
                    if getHigh(yCandles, idx: iH) > Retracements[iR] {
                        Retracements[iR] = 0
                    }
                }
            }
            
            //_______________________________________________________________________________________________________
            
            //If retracement is not "0" then create the plot with nul values
            for iRet in 0..<Retracements.count {
                if Retracements[iRet] != 0 {
                    var H2L_Retracement: [Double?] = []
                    for i in 0..<highPoints.count {
                        if i < highAtIndex[ii].index {
                            H2L_Retracement.append(nil)
                        } else if i == highAtIndex[ii].index {
                            H2L_Retracement.append(Retracements[iRet])
                        }else if i == highPoints.count-1 {
                            H2L_Retracement.append(Retracements[iRet])
                        } else { H2L_Retracement.append(nil) }
                    }
                    
                    //Add plot with zeros to multidemensional array
                    H2L_Retracements.append(H2L_Retracement)
                    
                    //Add color to array
                    switch iRet {
                    case 0:
                        H2L_RetracementsColors.append(NSUIColor(red: 102/255, green: 102/255, blue: 255/255, alpha: 1))
                    case 1:
                        H2L_RetracementsColors.append(NSUIColor(red: 51/255, green: 51/255, blue: 255/255, alpha: 1))
                    case 2:
                        H2L_RetracementsColors.append(NSUIColor(red: 0/255, green: 0/255, blue: 255/255, alpha: 1))
                    case 3:
                        H2L_RetracementsColors.append(NSUIColor(red: 255/255, green: 153/255, blue: 255/255, alpha: 1))
                    case 4:
                        H2L_RetracementsColors.append(NSUIColor(red: 204/255, green: 153/255, blue: 255/255, alpha: 1))
                    case 5:
                        H2L_RetracementsColors.append(NSUIColor(red: 102/255, green: 255/255, blue: 102/255, alpha: 1))
                    case 6:
                        H2L_RetracementsColors.append(NSUIColor(red: 0/255, green: 153/255, blue: 0/255, alpha: 1))
                    case 7:
                        H2L_RetracementsColors.append(NSUIColor(red: 0/255, green: 102/255, blue: 0/255, alpha: 1))
                    default: break
                    }
                }
            }
            
        }

        //_______________________________________________________________________________________________________
        
        
        //Return both L2H and H2L multi arrays with the color values for each
        return (L2H_Retracements, H2L_Retracements, L2H_RetracementsColors, H2L_RetracementsColors)
        
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