//
//  ContentView.swift
//  Graphex
//
//  Created by Terran Kroft on 1/28/21.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var vm = ViewModel()
    @State var selectedNode: Point? = nil
    @State var selectedEdge: Edge? = nil
    var body: some View {
        VStack {
            
            GeometryReader { geo in
                ForEach(vm.edges, id: \.self) { edge in
                    Path { path in
                        path.move(to: CGPoint(x: edge.a.x, y: edge.a.y))
                        path.addLine(to: CGPoint(x: edge.b.x, y: edge.b.y))
                    }
                    .stroke(selectedEdge == edge ? Color.blue : Color.black, lineWidth: 5)
                    .onTapGesture {
                        selectedEdge = edge
                        selectedNode = nil
                    }
                }
                
                ForEach(vm.nodes, id: \.self) {node in
                    Circle()
                        .fill(Color.white)
                        
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .stroke(selectedNode == node ? Color.blue : Color.black, lineWidth: 5)

                        )
                        .overlay(
                            Text("\(node.id)")
)
                        .position(x: node.x, y: node.y)
                        .onTapGesture {
                            
                            if let selected = selectedNode {
                                if (selected != node) {
                                    print("Line")
                                    vm.addEdge(node, selected)
                                }
                            }
                            selectedNode = node
                            selectedEdge = nil
                        }
                }
                
                
            }
            .background(Color.yellow)
            .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .global).onEnded { dragGesture in
                print("Position: \(dragGesture.location.x), \(dragGesture.location.y)")
                if (selectedNode == nil && selectedEdge == nil) {
                    vm.addPoint(dragGesture.location)
                } else {
                selectedNode = nil
                    selectedEdge = nil
                }
            })
            
            ScrollView {
                VStack {
                        if (selectedNode != nil) {
                            HStack {
                            Text("Node \(selectedNode!.id)").font(.title).bold()
                                Spacer()
                                Button(action: {
                                    vm.removePoint(selectedNode!)
                                    selectedNode = nil
                                }) {
                                    Text("Remove").bold()
                                        .padding()
                                        .foregroundColor(.red)
                                        .background(Color.red.opacity(0.2))
                                        .cornerRadius(10)
                            }
                            }
                        } else if (selectedEdge != nil) {
                            HStack {
                            Text("Edge \(selectedEdge!.a.id) → \(selectedEdge!.b.id )").font(.title).bold()
                                Spacer()
                                Button(action: {
                                    vm.removeEdge(selectedEdge!)
                                    selectedEdge = nil
                                }) {
                                    Text("Remove").bold()
                                        .padding()
                                        .foregroundColor(.red)
                                        .background(Color.red.opacity(0.2))
                                        .cornerRadius(10)
                            }
                        }
                        
                        }
                    
                }
                .padding()
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct Point: Hashable {
    static var idIncrementer = 0
    var x: CGFloat
    var y: CGFloat
    var id: Int
    
    init(x: CGFloat, y: CGFloat) {
        self.x = x
        self.y = y
        self.id = Point.idIncrementer
        Point.idIncrementer += 1
    }
}

struct Edge: Hashable {
    var a: Point
    var b: Point
}

class ViewModel: ObservableObject {
    @Published var nodes: [Point] = []
    @Published var edges: [Edge] = []
    func addPoint(_ point: CGPoint) {
        nodes.append(Point(x: point.x, y: point.y))
    }
    
    func addEdge(_ pointA: Point, _ pointB: Point) {
        edges.append(Edge(a: pointA, b: pointB))
    }
    
    func removeEdge(_ edge: Edge) {
        edges.removeAll(where: {$0 == edge})
    }
    
    func removePoint(_ point: Point) {
        // first clear all the edges where the point is used
        edges.removeAll(where: {
            $0.a == point || $0.b == point
        })
        
        nodes.removeAll(where: {
            $0 == point
        })
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
