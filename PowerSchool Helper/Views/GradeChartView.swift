//
//  GradeChartView.swift
//  PowerSchool Helper
//
//  Created by Branson Campbell on 12/17/22.
//

import SwiftUI
import SwiftUICharts

struct GradeChartView: View {
    
    init() {
        UISegmentedControl.appearance().selectedSegmentTintColor = Util.getThemeColor()
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
    
    }
    
    
    @EnvironmentObject private var text: NameScreenData
    @Environment(\.dismiss) private var dismiss

    @State var pickerSelectedItem = 0
    let pickerOptions: [String] = ["1 Week", "2 Weeks", "1 Month"]

    
    var body: some View {
        let data: LineChartData = weekOfData()
        GeometryReader { geometry in
            VStack {
                Picker("", selection: $pickerSelectedItem) {
                    ForEach(Array(pickerOptions.enumerated()), id: \.offset) { (index, option) in
                        Text(option)
                            .font(.footnote)
                            .fontWeight(.bold)
                            .tag(index)
                    }

                }
                .pickerStyle(SegmentedPickerStyle()).foregroundColor(.red)
                
                Image(systemName: "arrow.right.circle.fill")
                    .position(x: geometry.size.width-30, y: 70)
                    .font(Font.system(.largeTitle))
                    .foregroundColor(Color(Util.getThemeColor()))
                    .onTapGesture(count: 1) {
                        dismiss()
                    }
            
                LineChart(chartData: data)
                    .pointMarkers(chartData: data)
                    .touchOverlay(chartData: data, specifier: "%.0f")
                    .xAxisGrid(chartData: data)
                    .yAxisGrid(chartData: data)
                    .xAxisLabels(chartData: data)
                    .yAxisLabels(chartData: data)
                    .infoBox(chartData: data)
                    .headerBox(chartData: data)
                    .id(data.id)
                    .padding(.trailing, 15)
                    .padding(.top, 15)
                    .padding(.bottom,40)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                
                
            }.background(Color.black)
        }
        
    }
    

    
    func weekOfData() -> LineChartData {
        var gradesDataPoints = [LineChartDataPoint]()
        for assignment in text.assignments[pickerSelectedItem] {
            let grade = assignment["grade"]!
            let date = assignment["date"]!
            
            let roundedGrade: Double = Double(round(100 * Double(grade)!) / 100)
            gradesDataPoints.append(
                LineChartDataPoint(value: roundedGrade, xAxisLabel: date, description: "(\(roundedGrade)%) \(date)")
            )
        }
        
        gradesDataPoints.reverse()
        let data = LineDataSet(dataPoints: gradesDataPoints,
                               legendTitle: "Grade History",
                               pointStyle: PointStyle(pointSize: 6, fillColour: Color(Util.getThemeColor()), pointType: .filled),
                               style: LineStyle(lineColour: ColourStyle(colour: Color(Util.getThemeColor())), lineType: .line))
        
        let metadata = ChartMetadata(title: "Grades",subtitle: "Past \(pickerOptions[pickerSelectedItem])", titleFont: Font.system(size: 40, weight: .bold), titleColour: .white, subtitleFont: Font.system(size: 20), subtitleColour: .white)

        
        let gridStyle  = GridStyle(numberOfLines: text.assignments[pickerSelectedItem].count,
                                   lineColour   : Color(.lightGray).opacity(0.4),
                                   lineWidth    : 1,
                                   dash         : [1],
                                   dashPhase    : 0)
        
        let chartStyle = LineChartStyle(infoBoxPlacement    :  .infoBox(isStatic: false),
                                        
                                        infoBoxValueColour: .white,
                                        infoBoxDescriptionColour: .white,
                                        infoBoxBackgroundColour: .black,
                                        
                                        infoBoxBorderColour : Color(Util.getThemeColor()),
                                        infoBoxBorderStyle  : StrokeStyle(lineWidth: 1),
                                        
                                        markerType          : .vertical(attachment: .line(dot: .style(DotStyle())), colour: Color(Util.getThemeColor())),
                                        
                                        xAxisGridStyle      : gridStyle,
                                        xAxisLabelPosition  : .bottom,
                                        xAxisLabelFont      : Font.system(size: 11, weight: .bold),
                                        xAxisLabelColour    : Color.white,
                                        
                                        xAxisLabelsFrom     : .dataPoint(rotation: .degrees(80)),
                                        
                                        yAxisGridStyle      : gridStyle,
                                        yAxisLabelPosition  : .leading,
                                        yAxisLabelFont      : Font.system(size: 15, weight: .bold),
                                        yAxisLabelColour    : Color.white,
                                        yAxisNumberOfLabels : 5,
                                        yAxisTitleColour    : Color.white,

                            
                
                                        
                                        baseline            : .minimumWithMaximum(of: 50),
                                        topLine             : .maximum(of: 100),
                                        
                                        globalAnimation     : .easeOut(duration: 1))
        
        return LineChartData(dataSets       : data,
                             metadata       : metadata,
                             chartStyle     : chartStyle)
    }
    
}



struct LineChartDemoView: View {
    init() {
        UISegmentedControl.appearance().selectedSegmentTintColor = Util.getThemeColor()
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
    
    }
    
    @State var pickerSelectedItem = 2
    @Environment(\.dismiss) private var dismiss
    let pickerOptions: [String] = ["1 Week", "2 Weeks", "1 Month"]


    var body: some View {
        let data: LineChartData = weekOfData()
        

        GeometryReader { geometry in
            VStack {
                Picker("", selection: $pickerSelectedItem) {
                    ForEach(Array(pickerOptions.enumerated()), id: \.offset) { (index, option) in
                        Text(option)
                            .font(.footnote)
                            .fontWeight(.bold)
                            .tag(index)
                    }
                    
                }.pickerStyle(SegmentedPickerStyle()).foregroundColor(.red)
                
                Image(systemName: "arrow.right.circle.fill")
                    .position(x: geometry.size.width-30, y: 70)
                    .font(Font.system(.largeTitle))
                    .foregroundColor(Color(Util.getThemeColor()))
                    .onTapGesture(count: 1) {
                        dismiss()
                    }

                LineChart(chartData: data)
                    .pointMarkers(chartData: data)
                    .touchOverlay(chartData: data, specifier: "%.0f")
                    .xAxisGrid(chartData: data)
                    .yAxisGrid(chartData: data)
                    .xAxisLabels(chartData: data)
                    .yAxisLabels(chartData: data)
                    .infoBox(chartData: data)
                    .headerBox(chartData: data)
                    .id(data.id)
                    .padding(.trailing, 15)
                    .padding(.top, 20)
                    .padding(.bottom,50)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                
                
                
            }.background(Color.black)
        }
        
    }
    

    let gradePointDataList: [[LineChartDataPoint]] = [
                        [LineChartDataPoint(value: 100, xAxisLabel: "12/10"),
                           LineChartDataPoint(value: 97, xAxisLabel: "12/11"),
                           LineChartDataPoint(value: 96, xAxisLabel: "12/12"),
                           LineChartDataPoint(value: 95, xAxisLabel: "12/13"),
                           LineChartDataPoint(value: 96, xAxisLabel: "12/14"),
                           LineChartDataPoint(value: 99, xAxisLabel: "12/15"),
                           LineChartDataPoint(value: 98, xAxisLabel: "12/16"),
                           LineChartDataPoint(value: 92, xAxisLabel: "12/17"),
                           LineChartDataPoint(value: 91, xAxisLabel: "12/18"),
                           LineChartDataPoint(value: 93, xAxisLabel: "12/19"),
                           LineChartDataPoint(value: 94, xAxisLabel: "12/20"),
                           LineChartDataPoint(value: 95, xAxisLabel: "12/21"),
                           LineChartDataPoint(value: 97, xAxisLabel: "12/22"),
                           LineChartDataPoint(value: 98, xAxisLabel: "12/23"),
                           LineChartDataPoint(value: 100, xAxisLabel: "12/24")],
                        [LineChartDataPoint(value: 100, xAxisLabel: "12/10"),
                           LineChartDataPoint(value: 95, xAxisLabel: "12/11"),
                           LineChartDataPoint(value: 99, xAxisLabel: "12/12"),
                           LineChartDataPoint(value: 99, xAxisLabel: "12/13"),
                           LineChartDataPoint(value: 99, xAxisLabel: "12/14"),
                           LineChartDataPoint(value: 94, xAxisLabel: "12/15"),
                           LineChartDataPoint(value: 93, xAxisLabel: "12/16"),
                           LineChartDataPoint(value: 91, xAxisLabel: "12/17"),
                           LineChartDataPoint(value: 90, xAxisLabel: "12/18"),
                           LineChartDataPoint(value: 93, xAxisLabel: "12/19"),
                           LineChartDataPoint(value: 94, xAxisLabel: "12/20"),
                           LineChartDataPoint(value: 95, xAxisLabel: "12/21"),
                           LineChartDataPoint(value: 97, xAxisLabel: "12/22"),
                           LineChartDataPoint(value: 98, xAxisLabel: "12/23"),
                           LineChartDataPoint(value: 100, xAxisLabel: "12/24")],
                        [LineChartDataPoint(value: 85, xAxisLabel: "12/10"),
                           LineChartDataPoint(value: 84, xAxisLabel: "12/11"),
                           LineChartDataPoint(value: 90, xAxisLabel: "12/12"),
                           LineChartDataPoint(value: 88, xAxisLabel: "12/13"),
                           LineChartDataPoint(value: 89, xAxisLabel: "12/14"),
                           LineChartDataPoint(value: 83, xAxisLabel: "12/15"),
                           LineChartDataPoint(value: 85, xAxisLabel: "12/16"),
                           LineChartDataPoint(value: 91, xAxisLabel: "12/17"),
                           LineChartDataPoint(value: 90, xAxisLabel: "12/18"),
                           LineChartDataPoint(value: 93, xAxisLabel: "12/19"),
                           LineChartDataPoint(value: 94, xAxisLabel: "12/20"),
                           LineChartDataPoint(value: 95, xAxisLabel: "12/21"),
                           LineChartDataPoint(value: 97, xAxisLabel: "12/22"),
                           LineChartDataPoint(value: 98, xAxisLabel: "12/23"),
                           LineChartDataPoint(value: 98, xAxisLabel: "12/24"),
                           LineChartDataPoint(value: 100, xAxisLabel: "12/25")]
                    ]
    
    func weekOfData() -> LineChartData {
        let data = LineDataSet(dataPoints: gradePointDataList[pickerSelectedItem],
                               legendTitle: "Grade",
                               pointStyle: PointStyle(pointSize: 6, fillColour: Color(Util.getThemeColor()), pointType: .filled),
                               style: LineStyle(lineColour: ColourStyle(colour: Color(Util.getThemeColor())), lineType: .line))
        
        let metadata = ChartMetadata(title: "Grade History",subtitle: "Past \(pickerOptions[pickerSelectedItem])", titleFont: Font.system(size: 40, weight: .bold), titleColour: .white, subtitleFont: Font.system(size: 20), subtitleColour: .white)

        
        let gridStyle  = GridStyle(numberOfLines: 14,
                                   lineColour   : Color(.lightGray).opacity(0.4),
                                   lineWidth    : 1,
                                   dash         : [1],
                                   dashPhase    : 0)
        
        let chartStyle = LineChartStyle(infoBoxPlacement    :  .infoBox(isStatic: false),
                                        
                                        infoBoxValueColour: .white,
                                        infoBoxDescriptionColour: .white,
                                        infoBoxBackgroundColour: .black,
                                        
                                        infoBoxBorderColour : Color(Util.getThemeColor()),
                                        infoBoxBorderStyle  : StrokeStyle(lineWidth: 1),
                                        
        
                                        markerType          : .vertical(attachment: .line(dot: .style(DotStyle())), colour: Color(Util.getThemeColor())),
                                        
                                        xAxisGridStyle      : gridStyle,
                                        xAxisLabelPosition  : .bottom,
                                        xAxisLabelFont      : Font.system(size: 11, weight: .bold),
                                        xAxisLabelColour    : Color.white,
                                        
                                        xAxisLabelsFrom     : .dataPoint(rotation: .degrees(80)),
                                        
                                        yAxisGridStyle      : gridStyle,
                                        yAxisLabelPosition  : .leading,
                                        yAxisLabelFont      : Font.system(size: 15, weight: .bold),
                                        yAxisLabelColour    : Color.white,
                                        yAxisNumberOfLabels : 5,
                                        yAxisTitleColour    : Color.white,


                                        baseline            : .minimumWithMaximum(of: 50),
                                        topLine             : .maximum(of: 100),
                                        
                                        globalAnimation     : .easeOut(duration: 1))
        
        return LineChartData(dataSets       : data,
                             metadata       : metadata,
                             chartStyle     : chartStyle)
    }
}

struct GradeChartView_Previews: PreviewProvider {
    static var previews: some View {
        LineChartDemoView()
    }
}

class NameScreenData: ObservableObject {
    @Published var assignments: [[[String : String]]] = [[[:]]]
}
