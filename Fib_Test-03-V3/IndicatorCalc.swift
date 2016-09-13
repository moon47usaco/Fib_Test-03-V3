//
//  IndicatorCalc.swift
//
//  Created by Ryan Mooney on 8/23/16.
//  Copyright © 2016 Ryan Mooney. All rights reserved.
//

import Foundation
class IndicatorCalc {

    func indicatorOverlaySMA(yValues: [[Double]]) -> [Double?]{
        
        //SMA vars
        var sum = 0.0
        var SMA: [Double?] = []
        
        //hlPivot vars
        let peroid = 14.0
        
        //Simple Moving Average........
        for i in 0..<Int(peroid) {
            sum  += yValues[i][3]
            if i < Int(peroid)-1 {
                SMA.append(nil)}
        }
        SMA.append(sum/peroid)
        for i in Int(peroid)..<yValues.count {
            sum = (sum - yValues[i - Int(peroid)][3]) + yValues[i][3]
            SMA.append(sum/peroid)
        }
        
        return SMA
        
    }
    
    
    //__________________________________________________________________________________________________
    //__________________________________________________________________________________________________
    //__________________________________________________________________________________________________
    
    
    func indicatorOverlayZZ(yValues: [[Double]]) -> (ZZ: [Double?], Highs: [Double], Lows: [Double], highPoint: [Double], nweMax: [Double], newState: [Double], state: [Double], lowPoint: [Double], newMin: [Double]){
        
        //hlPivot vars
        let peroid = 14.0
        let atrReversal = 2.0
        var TrueRange: [Double] = []
        var Pivot: [Double] = []
        var hlPivot: [Double] = []

        //High Low Pivot for ZigZag........
        for i in 0..<yValues.count {
            if i == 0 {
                TrueRange.append(yValues[i][1]-yValues[i][2])//change these to use highPionts/lowPoints from precalc below
            }
            else {
                let barsRange = yValues[i][1]-yValues[i][2]
                let prevClose_to_Low = yValues[i-1][3]-yValues[i][2]
                let prevClose_to_High = yValues[i][1]-yValues[i-1][3]
                TrueRange.append(max(max(barsRange, prevClose_to_Low), prevClose_to_High))
            }
        }
        Pivot.append(TrueRange[0])
        for i in 1..<yValues.count {
            Pivot.append( ((Pivot[i-1]*(peroid-1))+TrueRange[i])/peroid )
        }
        
        for i in 0..<yValues.count {
            hlPivot.append((Pivot[i]/yValues[i][3])*atrReversal)
        }

        //__________________________________________________________________________________________________

        //ZigZag........
        
        //Vars for state, price, max highs/lows, etc...
        enum State: Int {
            case undefined = 1, downtrend, uptrend
            init() {
                self = .undefined
            }
        }
        
        var priceH: Double
        var priceL: Double
        var currentState: [State] = []
        var maxPriceH: [Double] = []
        var minPriceL: [Double] = []
        var prevMaxH: Double
        var prevMinL: Double
        var newMax: [Bool] = []
        var newMin: [Bool] = []
        var newState: [Bool] = []
        
        //__________________________________________________________________________________________________

        
        //ZigZag State, Min & Max........
        for i in 0..<yValues.count {
            var barSw: Int
            priceH = getHigh(yValues, idx: i)
            priceL = getLow(yValues, idx: i)
            
            //Calculate the state/trend, the max/min price for the state, etc...
            if i == 0 {
                currentState.append(State())
                maxPriceH.append(priceH)
                minPriceL.append(priceL)
                prevMaxH = maxPriceH[i]
                prevMinL = minPriceL[i]
                newMax.append(true)
                newMin.append(true)
                barSw = 0
            }
            else {
                prevMaxH = maxPriceH[i-1]
                prevMinL = minPriceL[i-1]
                barSw = 1
                
                if currentState[i-1] == .undefined {
                    if priceH >= prevMaxH {
                        currentState.append(.uptrend)
                        maxPriceH.append(priceH)
                        minPriceL.append(prevMinL);
                        newMax.append(true)
                        newMin.append(false)
                    } else if priceL <= prevMinL {
                        currentState.append(.downtrend)
                        maxPriceH.append(prevMaxH)
                        minPriceL.append(priceL)
                        newMax.append(false)
                        newMin.append(true)
                    } else {
                        currentState.append(.undefined)
                        maxPriceH.append(prevMaxH)
                        minPriceL.append(prevMinL);
                        newMax.append(false)
                        newMin.append(false)
                    }
                } else if currentState[i-1] == State.uptrend {
                    if priceL <= prevMaxH - prevMaxH * hlPivot[i] {
                        currentState.append(.downtrend)
                        maxPriceH.append(prevMaxH)
                        minPriceL.append(priceL)
                        newMax.append(false)
                        newMin.append(true)
                    } else {
                        currentState.append(.uptrend)
                        if (priceH >= prevMaxH) {
                            maxPriceH.append(priceH)
                            newMax.append(true)
                        } else {
                            maxPriceH.append(prevMaxH)
                            newMax.append(false)
                        }
                        minPriceL.append(prevMinL);
                        newMin.append(false)
                    }
                } else {
                    if priceH >= prevMinL + prevMinL * hlPivot[i] {
                        currentState.append(.uptrend)
                        maxPriceH.append(priceH)
                        minPriceL.append(prevMinL);
                        newMax.append(true)
                        newMin.append(false)
                    } else {
                        currentState.append(.downtrend)
                        maxPriceH.append(prevMaxH)
                        newMax.append(false)
                        if (priceL <= prevMinL) {
                            minPriceL.append(priceL)
                            newMin.append(true)
                        } else {
                            minPriceL.append(prevMinL);
                            newMin.append(false)
                        }
                        
                        
                    }
                }

            }
            newState.append(currentState[i] != currentState[i-barSw])
        }
        
        //__________________________________________________________________________________________________


        //Vars for precalculations
        var priceHigh: [Double] = []//put these in to the state section so they are not redundant
        var priceLow: [Double] = []//put these in to the state section so they are not redundant
        var tH: [Double] = []//rename to something meaningfull
        var tL: [Double] = []//rename to something meaningfull
        var highPoints: [Double] = []
        var lowPoints: [Double] = []


        for i in 0..<yValues.count {
            priceHigh.append(getHigh(yValues, idx: i))
            priceLow.append(getLow(yValues, idx: i))
            tH.append(getHigh(yValues, idx: i))
            tL.append(getLow(yValues, idx: i))
            //Arrays for high/low points with initial zero values
            highPoints.append(0)
            lowPoints.append(0)

        }
        
        //__________________________________________________________________________________________________
        
        /*
         Could not recreate the TOS ZigZag logic for getting high and low points that uses the "fold" function. 
         That function is a confusing variation of a for/[while] loop that was not easy to translate into this code.
         
         Instead i used another logic that looks at each state/trend and finds the highest or lowest value in that trend. 
         
         It counts the bars in the trend, places all the highs/lows into a temp array, finds the highest/lowest value and its place in the data set then places that value into an array with all zeros. 
         
         The result is an array with all zeros except where there is a high/low point.
         */
 
        
        //count the number of bars in each trend change
        //NB if other "0" values are changed to "nil" these can stay as "0"
        var upBars: [Int] = []
        var dnBars: [Int] = []
        var trendBars: Int = 0
        for i in 0..<yValues.count {
            //Reset values to zero when trend changes
            if newState[i] {
                trendBars = 1
                upBars.append(trendBars)
                dnBars.append(trendBars)
            }
            else if currentState[i] == State.uptrend {
                trendBars += 1
                upBars.append(trendBars)
                dnBars.append(0)//Set these to -1 for drawing to a chart because of "0" value interpolation
            }
            else {
                trendBars += 1
                upBars.append(0)//Set these to -1 for drawing to a chart because of "0" value interpolation
                dnBars.append(trendBars)
            }
        }
        
        //__________________________________________________________________________________________________
        
        //Put high and low points into arrays
        for i in 0..<yValues.count-1 {
            //If at the bar just before the change
            if currentState[i] == State.uptrend && newState[i+1] {
                //Put all the high values into an array
                var trendBarsUp: [Double] = []
                for iH in 0..<upBars[i]{
                    trendBarsUp.append(getHigh(yValues, idx: i-iH))
                }
                //Put the array back in first to last order
                trendBarsUp = trendBarsUp.reverse()
                //Get the highest value in the trend find its place and insert it into the highPoints array
                if let max = trendBarsUp.maxElement() {
                    if let position = trendBarsUp.indexOf(max){
                        let barsBack = trendBarsUp.count-(position+1)
                        highPoints[i-barsBack] = getHigh(yValues, idx: i-barsBack)
                    }
                }
            }
            //Same as high points with low points
            if currentState[i] == State.downtrend && newState[i+1] {
                var trendBarsDn: [Double] = []
                for iL in 0..<dnBars[i]{
                    trendBarsDn.append(getLow(yValues, idx: i-iL))
                }
                trendBarsDn = trendBarsDn.reverse()
                if let min = trendBarsDn.minElement() {
                    if let position = trendBarsDn.indexOf(min){
                        let barsBack = trendBarsDn.count-(position+1)
                        lowPoints[i-barsBack] = getLow(yValues, idx: i-barsBack)
                    }
                }
            }

        }
        
        //__________________________________________________________________________________________________

        //Calculate the final values if the ZigZag
        var ZZ: [Double?] = []
        for i in 0..<yValues.count {
            
            //Change the names of these to avoid confusion
            //If in a up/down trend and prices are at the extream of the maxPriceH/minPriceL chan
            let highPoint = currentState[i] == State.uptrend && priceHigh[i] == maxPriceH[i];
            let lowPoint = currentState[i] == State.downtrend && priceLow[i] == minPriceL[i];
            //State at first bar will be undefined by default
            //Change this for better logic
            if i == 1 {
                if currentState[i] == State.uptrend {
                    ZZ.append(priceLow[i])
                } else if currentState[i] == State.downtrend {
                    ZZ.append(priceHigh[i])
                } else { ZZ.append(nil) }
            //If at the last bar use the current high/low
            } else if i == yValues.count-1 {
                if highPoint || currentState[i] == State.downtrend && priceLow[i] > minPriceL[i] {
                    ZZ.append(priceHigh[i])
                } else if lowPoint || currentState[i] == State.uptrend && priceHigh[i] < maxPriceH[i] {
                    ZZ.append(priceLow[i])
                } else { ZZ.append(nil) }
            //use high and low point arrays to get all points inbetween first and last bars
            } else {
                if highPoints[i] != 0 { ZZ.append(highPoints[i]) }
                else if lowPoints[i] != 0 { ZZ.append(lowPoints[i]) }
                else { ZZ.append(nil) }
            }
        }
        
        //__________________________________________________________________________________________________

        //Values for testing of ZigZag
        
        var highPt: [Double] = []
        var lowPt: [Double] = []
        var nState: [Double] = []
        var state: [Double] = []
        var nMax: [Double] = []
        var nMin: [Double] = []
        for i in 0..<yValues.count {
            
            if highPoints[i] > 0 {
                highPt.append(6)
            }else { highPt.append(5) }
            
            if newMax[i] == true {
                nMax.append(5)
            }else { nMax.append(4) }
            
            if newState[i] == true {
                nState.append(4)
            }else { nState.append(3) }
            
            if currentState[i] == State.undefined {
                state.append(1)
            }else if currentState[i] == State.uptrend {
                state.append(3)
            }else { state.append(2) }
            
            if lowPoints[i] > 0 {
                lowPt.append(-1)
            }else { lowPt.append(-2) }
            
            if newMin[i] == true {
                nMin.append(-3)
            }else { nMin.append(-4) }
            
            
            
        }
        
        //Return all values for calculation, high/low points for retracements/projections and testing values
        return (ZZ, highPoints, lowPoints, highPt, nMax, nState, state, lowPt, nMin)
        
    }
  
    
    //__________________________________________________________________________________________________
    //__________________________________________________________________________________________________
    //__________________________________________________________________________________________________
    
    
    func indicatorLowerRSI(yValues: [[Double]]) ->  [Double?]{

        let peroid = 14.0
        //RSI vars
        var RS: [Double] = []
        var RSI: [Double?] = []
        var sum_up = 0.0
        var sum_dn = 0.0
        
        //Relative Strength Index.......
        for i in 1..<Int(peroid) {
            if yValues[i][3] > yValues[i-1][3] {
                sum_up  += yValues[i][3] - yValues[i-1][3]
            }
            else if yValues[i][3] < yValues[i-1][3] {
                sum_dn  += yValues[i-1][3] - yValues[i][3]
            }
            RS.append(0.0)
        }
        var ave_up = (sum_up/peroid)
        var ave_dn = (sum_dn/peroid)
        RS.append(ave_up/ave_dn)
        var bar_up = 0.0
        var bar_dn = 0.0
        
        for i in Int(peroid)..<yValues.count {
            
            if yValues[i][3] > yValues[i-1][3] {
                bar_up = yValues[i][3] - yValues[i-1][3]
            } else { bar_up = 0.0 }
            if yValues[i][3] < yValues[i-1][3] {
                bar_dn = yValues[i-1][3] - yValues[i][3]
            }else { bar_dn = 0.0 }
            ave_up = ((ave_up*(peroid-1))+bar_up)/peroid
            ave_dn = ((ave_dn*(peroid-1))+bar_dn)/peroid
            
            RS.append(ave_up/ave_dn)
        }
        
        for i in 0..<yValues.count {
            if RS[i] != 0 {
                RSI.append(100 - (100/(1+RS[i])) )
            }else {
                RSI.append(nil)

            }
        }
        //.........
        
        return RSI
        
    }

    
    //__________________________________________________________________________________________________
    //__________________________________________________________________________________________________
    //__________________________________________________________________________________________________
    
    
    func indicatorLowerTest(yValues: [[Double]]) ->  [Double?]{
        
        //RSI vars
        var Test: [Double?] = []
        
        //Relative Strength Index.......
        for i in 0..<yValues.count{
            if i % 2 == 0 {
                Test.append(40)
            }else { Test.append(60) }
        }
        
        return Test
        
    }

    
    //__________________________________________________________________________________________________
    //__________________________________________________________________________________________________
    //__________________________________________________________________________________________________
    
    
    func getOpen(yValues: [[Double]], idx: Int) -> Double {
        return yValues[idx][0]
    }
    
    func getHigh(yValues: [[Double]], idx: Int) -> Double {
        return yValues[idx][1]
    }
    
    func getLow(yValues: [[Double]], idx: Int) -> Double {
        return yValues[idx][2]
    }

    func getClose(yValues: [[Double]], idx: Int) -> Double {
        return yValues[idx][3]
    }

}





