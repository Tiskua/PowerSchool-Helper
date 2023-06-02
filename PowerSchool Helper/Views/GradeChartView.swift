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
            }
        }
        .padding()
        .background(Color.black)
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



struct GradeChartView_Previews: PreviewProvider {
    static var previews: some View {
        GradeChartView()
    }
}

class NameScreenData: ObservableObject {
    @Published var assignments: [[[String : String]]] = [[[:]]]
}
