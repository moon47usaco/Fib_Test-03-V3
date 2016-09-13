//
//  ViewController.swift
//
//  Created by Ryan Mooney on 8/17/16.
//  Copyright © 2016 Ryan Mooney. All rights reserved.
//

import Foundation
import Cocoa
import Alamofire
import SwiftyJSON
import Charts
import CoreGraphics

let indicatorCalc = IndicatorCalc()
let fibProjections = FibProjections()
let fibRetracements = FibRetracements()

//Prices are ["Open"=[0], "High"=[1], "Low"=[2], "Last"[3]]
var xValues = [String]()
var yValues: [[Double]] = []
var yValuesIndicatorOverlay: [[Double?]] = []
var yValuesIndicatorLower: [[Double?]] = []
var colorsIndicatorOverlay: [[NSUIColor]] = []
var colorsIndicatorLower: [[NSUIColor]] = []
var midPrice: Double = 0
var scaleFactor: Double = 0

var jsonCount = 0

class ViewController: NSViewController, ChartViewDelegate{
    
    
    
    @IBOutlet weak var combinedChartView: CombinedChartView!
    
    @IBOutlet weak var lineChartView: LineChartView!
    
    //__________________________________________________________________________________________________
    //__________________________________________________________________________________________________
    //__________________________________________________________________________________________________
    
    // Zoom Buttons
    
    @IBAction func zoomAll(sender: AnyObject) {
        combinedChartView.fitScreen()
        combinedChartView.zoom(scaleX: 1, scaleY: CGFloat(scaleFactor), xValue: 0, yValue: midPrice, axis: YAxis.AxisDependency.Right)
        lineChartView.fitScreen()
    }
    
    @IBAction func zoomIn(sender: AnyObject) {
        combinedChartView.zoom(scaleX: 1.5, scaleY: 1, x: self.view.frame.width, y: 0)
        lineChartView.zoom(scaleX: 1.5, scaleY: 1, x: self.view.frame.width, y: 0)
        print("Zoomed In")
        //print(combinedChartView.highestVisibleXIndex)
    }
    
    @IBAction func zoomOut(sender: AnyObject) {
        combinedChartView.zoom(scaleX: 2/3, scaleY: 1, x: self.view.frame.width, y: 0)
        lineChartView.zoom(scaleX: 2/3, scaleY: 1, x: self.view.frame.width, y: 0)
        print("Zoomed Out")
        //print(combinedChartView.lowestVisibleXIndex)
        //print(combinedChartView.highestVisibleXIndex)
    }
    
    //__________________________________________________________________________________________________
    //__________________________________________________________________________________________________
    //__________________________________________________________________________________________________
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        combinedChartView.delegate = self
        lineChartView.delegate = self
        
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 0.95).CGColor
        
        combinedChartView.noDataText = "Loading data..."
        lineChartView.noDataText = "Loading data..."
        //candleStickChartView.noDataTextDescription = "REASON"
        
        //Get Alamofire data from web and assign values with SwiftyJSON
        
        Alamofire.request(.GET, "https://marketdata.websol.barchart.com/getHistory.json?key=DUMMYKEY&symbol=ESU6&type=minutes&startDate=20160816000000&interval=30")
            .responseJSON { response in
                
                if let value = response.result.value {
                    
                    let json = JSON(value)
                    
                    let data = json["results"].arrayValue //All data arrays[[]]
                    
                    var prices = [Double]() //Temp array container
                    
                    for i in 0..<data.count {
                        xValues.append(data[i]["timestamp"].stringValue)
                        prices.append(data[i]["open"].doubleValue)
                        prices.append(data[i]["high"].doubleValue)
                        prices.append(data[i]["low"].doubleValue)
                        prices.append(data[i]["close"].doubleValue)
                        yValues.append(prices)
                        prices = [] //Empty the temp array
                        
                    }
                    self.createIndicators(xValues, yValues: yValues)
                    
                    //Print first and last xValues
                    print( xValues[0] )
                    print( xValues[xValues.count-1] )
                    print( xValues.count )
                    
                    //Set values of highest/lowest/mid price and highest/lowest indicator values
                    self.setMid_Scale(yValues, indicatorValues: yValuesIndicatorOverlay)
                    
                    //Call function to draw charts
                    self.setChart(xValues, valuesCandleChart: yValues, indicatorLowerValues: yValuesIndicatorLower, indicatorOverlayValues: yValuesIndicatorOverlay)
                }
        }
    }
    //}
    
    //__________________________________________________________________________________________________
    //__________________________________________________________________________________________________
    //__________________________________________________________________________________________________
    
    
    //Function to set chart values
    func setChart(xValues: [String], valuesCandleChart: [[Double]], indicatorLowerValues: [[Double?]], indicatorOverlayValues: [[Double?]]) {
        
        let combinedChartData = CombinedChartData(xVals: xValues)
        
        
        //__________________________________________________________________________________________________
        
        //Candle chart
        
        var yValsCandleChart : [CandleChartDataEntry] = []
        for i in 0..<valuesCandleChart.count {
            let high = valuesCandleChart[i][1]
            let low = valuesCandleChart[i][2]
            let open = valuesCandleChart[i][0]
            let close = valuesCandleChart[i][3]
            yValsCandleChart.append(CandleChartDataEntry(xIndex: i, shadowH: high, shadowL: low, open: open, close: close))
        }
        let candleChartDataSet = CandleChartDataSet(values: yValsCandleChart, label: "Price")
        
        candleChartDataSet.decreasingColor = NSColor.redColor()
        candleChartDataSet.increasingColor = NSColor.greenColor()
        candleChartDataSet.neutralColor = NSColor.blueColor()
        candleChartDataSet.shadowColorSameAsCandle = true
        candleChartDataSet.shadowWidth = 1
        candleChartDataSet.decreasingFilled = true
        candleChartDataSet.increasingFilled = false
        candleChartDataSet.drawValuesEnabled = false
        
        //__________________________________________________________________________________________________
        
        //Line chart overlays
        
        var indicatorOverlay_yValues_Multi: [[ChartDataEntry]] = []
        for ii in 0..<indicatorOverlayValues.count {
            var indicatorOverlay_yValues: [ChartDataEntry] = []
            for i in 0..<xValues.count {
                if let indicatorOverlay = indicatorOverlayValues[ii][i] {
                    let indicatorOverlay_yValue = ChartDataEntry(value: indicatorOverlay, xIndex: i)
                    indicatorOverlay_yValues.append(indicatorOverlay_yValue)
                }
            }
            indicatorOverlay_yValues_Multi.append(indicatorOverlay_yValues)
            indicatorOverlay_yValues = []
        }
        
        var lineChartDataSet_Overlay: [LineChartDataSet] = []
        
        if indicatorOverlay_yValues_Multi != [] {
            lineChartDataSet_Overlay.append(LineChartDataSet(values: indicatorOverlay_yValues_Multi[0], label: "ZigZag"))
            lineChartDataSet_Overlay[0].drawCirclesEnabled = false
            lineChartDataSet_Overlay[0].drawValuesEnabled = false
            lineChartDataSet_Overlay[0].colors = colorsIndicatorOverlay[0]
        }
        
        
        if indicatorOverlay_yValues_Multi.count > 1 {
            for i in 1..<indicatorOverlay_yValues_Multi.count {
                lineChartDataSet_Overlay.append(LineChartDataSet(values: indicatorOverlay_yValues_Multi[i], label: ""))
                lineChartDataSet_Overlay[i].drawCirclesEnabled = false
                lineChartDataSet_Overlay[i].drawValuesEnabled = false
                lineChartDataSet_Overlay[i].colors = colorsIndicatorOverlay[i]
            }
        }
        
        //__________________________________________________________________________________________________
        
        //Set to combined chart
        
        combinedChartData.candleData = CandleChartData(xVals: xValues, dataSets: [candleChartDataSet])
        combinedChartData.lineData = LineChartData(xVals: xValues, dataSets: lineChartDataSet_Overlay)
        combinedChartData.lineData.highlightEnabled = false
        combinedChartView.drawOrder = [3, 2]
        combinedChartView.data = combinedChartData
        combinedChartView.doubleTapToZoomEnabled = false
        combinedChartView.autoScaleMinMaxEnabled = true
        
        //Scale to price only
        combinedChartView.zoom(scaleX: 1, scaleY: CGFloat(scaleFactor), xValue: 0, yValue: midPrice, axis: YAxis.AxisDependency.Right)
        
        //__________________________________________________________________________________________________
        
        //Line chart indicators
        
        var indicatorLower_yValues_Multi: [[ChartDataEntry]] = []
        for ii in 0..<indicatorLowerValues.count {
            var indicatorLower_yValues: [ChartDataEntry] = []
            for i in 0..<xValues.count {
                if let indicatorLower = indicatorLowerValues[ii][i] {
                    let indicatorLower_yValue = ChartDataEntry(value: indicatorLower, xIndex: i)
                    indicatorLower_yValues.append(indicatorLower_yValue)
                }
            }
            indicatorLower_yValues_Multi.append(indicatorLower_yValues)
            indicatorLower_yValues = []
        }
        
        let lineChartData = LineChartData(xVals: xValues)
        var lineChartDataSet: [LineChartDataSet] = []
        for i in 0..<indicatorLower_yValues_Multi.count {
            lineChartDataSet.append(LineChartDataSet(values: indicatorLower_yValues_Multi[i], label: "Indicator\(i+1)"))//Get name or not show...
            lineChartData.addDataSet(lineChartDataSet[i])//Draw order by last on top
            lineChartDataSet[i].colors = colorsIndicatorLower[i]
            lineChartDataSet[i].drawCirclesEnabled = false
        }
        lineChartView.data = lineChartData
        lineChartView.doubleTapToZoomEnabled = false
        if lineChartView.contentRect.width > combinedChartView.contentRect.width {
            let padding = (lineChartView.contentRect.width - combinedChartView.contentRect.width)/2
            lineChartView.setExtraOffsets(left: padding, top: 0, right: padding, bottom: 0)
        }
        
        
    }
    
    
    //__________________________________________________________________________________________________
    //__________________________________________________________________________________________________
    //__________________________________________________________________________________________________
    
    
    func createIndicators(xValues: [String], yValues: [[Double]]) {
        
        yValuesIndicatorLower.append(indicatorCalc.indicatorLowerRSI(yValues))
        colorsIndicatorLower.append([NSUIColor(red: 0, green: 1, blue: 1, alpha: 1)])
    }
    
    //__________________________________________________________________________________________________
    //__________________________________________________________________________________________________
    //__________________________________________________________________________________________________
    
    
    func setMid_Scale(yValues: [[Double]], indicatorValues: [[Double?]]) {
        
        var lowestLow: Double = 0
        var highestHigh: Double = 0
        var highestInd: Double = 0
        var lowestInd: Double = 0
        
        if indicatorValues.isEmpty == false  {
            //Get highest and lowest yValues
            for i in 0..<yValues.count {
                if i == 0 {
                    highestHigh = yValues[i][1]
                }else if yValues[i][1] > highestHigh {
                    highestHigh = yValues[i][1]
                }
            }
            
            for i in 0..<yValues.count {
                if i == 0 {
                    lowestLow = yValues[i][2]
                }else if yValues[i][2] < lowestLow {
                    lowestLow = yValues[i][2]
                }
            }
            //Set the mid price for scaling to price
            midPrice = lowestLow+((highestHigh-lowestLow)/2)
            
            //Get highest and lowest indicator values
            for i in 0..<indicatorValues.count {
                
                //Remove zeros from indicator values to get minimum
                
                var indicatorVlauesUnwrap: [Double] = []
                for ii in 0..<yValues.count {
                    if let value = indicatorValues[i][ii] {
                        indicatorVlauesUnwrap.append(value)
                    }
                }
                
                
                if i == 0 {
                    if let highest = indicatorVlauesUnwrap.maxElement() {
                        highestInd = highest
                    }
                    if let lowest = indicatorVlauesUnwrap.minElement() {
                        lowestInd = lowest
                    }
                }else {
                    if let highest = indicatorVlauesUnwrap.maxElement() {
                        if highest > highestInd {
                            highestInd = highest
                        }
                    }
                    if let lowest = indicatorVlauesUnwrap.minElement() {
                        if lowest < lowestInd {
                            lowestInd = lowest
                        }
                    }
                }
            }
            
            //SEt scale factor to the range of all indicators devided by the range of price
            let minValue = min(lowestInd, lowestLow)
            let maxValue = max(highestInd, highestHigh)
            scaleFactor = (maxValue-minValue)/(highestHigh-lowestLow)
        }
        
    }
    
    //__________________________________________________________________________________________________
    //__________________________________________________________________________________________________
    //__________________________________________________________________________________________________
    
    func chartValueSelected(chartView: ChartViewBase, entry: ChartDataEntry, dataSetIndex: Int, highlight: Highlight) {
        if  chartView == combinedChartView {
            lineChartView.highlightValues([highlight])
            print(highlight)
        }else {
            combinedChartView.highlightValue(x: entry.x, dataSetIndex: 0)
            print(highlight)
            
            
        }
    }
    
    
    //__________________________________________________________________________________________________
    //__________________________________________________________________________________________________
    //__________________________________________________________________________________________________
    
    
    func chartTranslated(chartView: ChartViewBase, dX: CGFloat, dY: CGFloat) {
        
        if  chartView == combinedChartView {
            let newMatrix = chartView.viewPortHandler.touchMatrix
            let oldMatrix = lineChartView.viewPortHandler.touchMatrix
            let currentMatrix = CGAffineTransformMake(oldMatrix.a, oldMatrix.b, oldMatrix.c, oldMatrix.d, newMatrix.tx, oldMatrix.ty)
            lineChartView.viewPortHandler.refresh(newMatrix: currentMatrix, chart: lineChartView, invalidate: true)
        }else {
            let newMatrix = chartView.viewPortHandler.touchMatrix
            let oldMatrix = combinedChartView.viewPortHandler.touchMatrix
            let currentMatrix = CGAffineTransformMake(oldMatrix.a, oldMatrix.b, oldMatrix.c, oldMatrix.d, newMatrix.tx, oldMatrix.ty)
            combinedChartView.viewPortHandler.refresh(newMatrix: currentMatrix, chart: combinedChartView, invalidate: true)
        }
        
    }
    
    
    //__________________________________________________________________________________________________
    //__________________________________________________________________________________________________
    //__________________________________________________________________________________________________
    
    
    
}
