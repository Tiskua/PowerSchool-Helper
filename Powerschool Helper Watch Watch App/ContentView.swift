//
//  ContentView.swift
//  Powerschool Helper Watch Watch App
//
//  Created by Branson Campbell on 5/15/23.
//

import SwiftUI
import WatchConnectivity

struct ContentView: View {
    @State var classData: [[String : String]] = [["className": "Band", "weightedGrade": "100" , "needPointPercent" : "0", "points" : "300/300"], ["className" : "Advanced Western Civilization", "weightedGrade" : "104" , "needPointPercent" : "18", "points" : "259/260"], ["className" : "English", "weightedGrade" : "100", "needPointPercent" : "0", "points" : "100/100"]]
//    @State var classData: [[String : String]] = []
    @State var term: String = "Q1"
    @State var themecolor: Color = Color(red: 100/255, green: 100/255, blue: 100/255)
    
    @ObservedObject var watchConnection = WatchConnector()
    

    
    var body: some View {
        ScrollView {
            PullToRefresh(coordinateSpaceName: "pullToRefresh") {
                getClassData()
            }
            HStack {
                Text("Grades")
                    .font(.system(size: 30, weight: .heavy))
                Spacer()
            }.padding(3)
            
            ZStack {
                Divider()
                Text(term)
                    .padding([.leading, .trailing], 10)
                    .background(.black)
            }
        
            VStack {
                if classData.count > 0 {
                    ForEach(classData, id: \.self) { data in
                        Section {
                            HStack() {
                                VStack() {
                                    Text("\(data["className"]!)")
                                        .font(.system(size: 18, weight: .semibold))
                                        .padding(.leading, 5)
                                }
                                Spacer()
                                Divider()
                                VStack() {
                                    Text("\(data["weightedGrade"]!)%")
                                        .font(.system(size: 13, weight: .bold))
                                    Text("\(data["points"]!)")
                                        .font(.system(size: 10, weight: .semibold))
                                    Text(pointsNeeded(points: Int(data["needPointPercent"]!) ?? 0, grade: Int(data["weightedGrade"]!) ?? 0))
                                        .font(.system(size: 10, weight: .semibold))
                                }.padding(5)
                        
                            }.padding([.top, .bottom], 3)
                                .background(themecolor.opacity(0.3))
                                .cornerRadius(5)
                        }
                    }
                
                } else {
                    ZStack {
                        Text("No Classes Found")
                            .offset(y: 30)
                            .font(.system(size: 17, weight: .heavy))
                            .foregroundColor(.red)
                    }
                }
            }
        }.coordinateSpace(name: "pullToRefresh")
            .onAppear() {
               getClassData()
            }
    }
    
    func pointsNeeded(points: Int, grade: Int) -> String {
        let newGrade = points > 0 ? grade + 1 : grade
        return "\(points) -> \(newGrade)%"
    }
    
    func getClassData() {
        if let classData = UserDefaults.standard.array(forKey: "classdata") as? [[String: String]] {
            self.classData = classData
        }
        if let classData = UserDefaults.standard.string(forKey: "themeColor") {
            self.themecolor = classData.stringToColor()
        }
        if let classData = UserDefaults.standard.string(forKey: "term") {
            self.term = classData
        }
    }
}

struct PullToRefresh: View {
    
    var coordinateSpaceName: String
    var onRefresh: ()->Void
    
    @State var needRefresh: Bool = false
    
    var body: some View {
        GeometryReader { geo in
            if (geo.frame(in: .named(coordinateSpaceName)).midY > 0) {
                Spacer()
                    .onAppear {
                        needRefresh = true
                    }
            } else if (geo.frame(in: .named(coordinateSpaceName)).maxY < -10) {
                Spacer()
                    .onAppear {
                        if needRefresh {
                            needRefresh = false
                            onRefresh()
                        }
                    }
            }
            HStack {
                Spacer()
                if needRefresh {
                    ProgressView()
                }
                Spacer()
            }
        }.padding(.top, -50)
    }
}




struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
