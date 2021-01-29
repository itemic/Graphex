//
//  ContentView.swift
//  Graphex
//
//  Created by Terran Kroft on 1/28/21.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var vm = ViewModel()
    @State var selectedNode: Node? = nil
    @State var selectedEdge: Edge? = nil
    
    func angleOf(_ a: Node, _ b: Node) -> CGFloat {
        let dY = b.y - a.y
        let dX = b.x - a.x
        var result = atan2(dY, dX)
        print(result)
        
//        if result <= 0 {
//            result += CGFloat(2.0 * Double.pi)
//        }
        return (result)
    }
    
    func distanceBetween(_ a: Node, _ b: Node) -> CGPoint {
        return CGPoint(x: b.x - a.x, y: b.y - a.y)
    }
    
    func intersectPoint(_ nodeA: Node, _ nodeB: Node) -> CGPoint {
        return CGPoint(x: nodeB.x + (20 * cos(angleOf(nodeB, nodeA))), y: nodeB.y + (20 * sin(angleOf(nodeB, nodeA))))
    }
    
    func drawArrow(_ point: CGPoint, _ angle: CGFloat) -> CGPoint {
        var x = point.x
        var y = point.y
        
        if (angle <= 0) {
            x -= 50
            y -= 50
        } else {
            x += 50
            y += 50
        }
        
//        x += 50 * cos(angle)
//        y += 520 * sin(angle)
//        y += 50 * sin(20 * CGFloat.pi)
        print("x = \(x)")
        return CGPoint(x: x, y: y)
    }
    
    
    var body: some View {
        
        ZStack(alignment: .trailing) {
            
            //MARK: Drawing Layer
            GeometryReader { g in
                
                //MARK: EDGES
                ForEach(vm.edges) { edge in
                    Path { path in
                        path.move(to: CGPoint(x: edge.nodeA.x, y: edge.nodeA.y))
//                        path.addLine(to: CGPoint(x: edge.nodeB.x, y: edge.nodeB.y))
                        path.addLine(to: intersectPoint(edge.nodeA, edge.nodeB))
                        
//                        path.addLine(to: drawArrow(intersectPoint(edge.nodeA, edge.nodeB), angleOf(edge.nodeB, edge.nodeA)))
                        
                        
                    }
                    .stroke(selectedEdge == edge ? Color.blue : Color.black, lineWidth: 5)
                    .onTapGesture {
                        selectedEdge = edge
                        selectedNode = nil
                    }
                }
                
                //MARK: NODES
                ForEach(vm.nodes) { node in
                    Circle()
                        .fill(Color.white.opacity(0.5))
                        .frame(width: CGFloat(vm.nodeSize), height: CGFloat(vm.nodeSize))
                        .overlay(Circle().stroke(selectedNode == node ? Color.blue : Color.black, lineWidth: 5))
                        .position(x: node.x, y: CGFloat(node.y))
                        .onTapGesture {
                            
                            if let selectedNode = selectedNode {
                                if (selectedNode != node) {
                                    vm.createEdge(selectedNode, node)
                                }
                            }
                            
                            selectedNode = node
                            selectedEdge = nil
                        }
                    
                }
                
                
            }
            .background(Color.yellow)
            .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .global)
                        .onEnded { gesture in
                            
                            if selectedNode != nil || selectedEdge != nil {
                                selectedNode = nil
                                selectedEdge = nil
                            }
                            else if (gesture.translation.width < 10 && gesture.translation.height < 10) {
                                print("TAP")
                                vm.createNode(gesture.location)
                            }
                        })
            
            //MARK: Top Card View
            HStack {
                
                Spacer()
                    .frame(width: UIScreen.main.bounds.width * 0.7)
                VStack(alignment: .leading) {
                    HStack {
                        Text("Graphex Explorer").font(.title).bold()
                        Spacer()
                    }
                    
                    Text("No element selected...")
                    
                    Text("Nodes").font(.headline)
                    List(vm.nodes) { node in
                        Text("Node \(node.name)")
                            .foregroundColor(node == selectedNode ? .green : .primary)
                            .onTapGesture {
                                selectedEdge = nil
                                selectedNode = node
                            }
                    }
                    Text("Edges").font(.headline)
                    List(vm.edges) { edge in
                        Text("\(edge.nodeA.name) → \(edge.nodeB.name)")
                            .foregroundColor(edge == selectedEdge ? .green : .primary)
                            .onTapGesture {
                                selectedEdge = edge
                                selectedNode = nil
                            }
                    }
                    Spacer()
                }
                .padding()
                .background(BlurView(style: .systemChromeMaterial))
                .cornerRadius(10)
            }
            .padding()
        }
        
    }
}


struct Node: Hashable, Identifiable {
    static var autoName = 0
    var id = UUID()
    var name: String
    var x: CGFloat
    var y: CGFloat
    
    init(_ coords: CGPoint, name: String = "\(Node.autoName)") {
        x = coords.x
        y = coords.y
        self.name = name
        Node.autoName += 1
    }
}

struct Edge: Hashable, Identifiable, Equatable {
    static func == (lhs: Edge, rhs: Edge) -> Bool {
        return lhs.nodeA == rhs.nodeA && lhs.nodeB == rhs.nodeB
    }
    var id = UUID()
    var nodeA: Node
    var nodeB: Node
}

enum EdgeType: String, CaseIterable {
    case directed //a to b
    case undirected
}

class ViewModel: ObservableObject {
    @Published var nodes: [Node] = []
    @Published var edges: [Edge] = [] //
    let nodeSize = 40
    
    func createNode(_ coords: CGPoint) {
        nodes.append(Node(coords))
    }
    
    func createEdge(_ a: Node, _ b: Node) {
        let edge = Edge(nodeA: a, nodeB: b)
        if !edges.contains(edge) {edges.append(edge)}
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

// source: https://medium.com/dev-genius/blur-effect-with-vibrancy-in-swiftui-bada837fdf50
struct BlurView: UIViewRepresentable {
    typealias UIViewType = UIVisualEffectView
    
    let style: UIBlurEffect.Style
    
    init(style: UIBlurEffect.Style = .systemUltraThinMaterial) {
        self.style = style
    }
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: self.style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: self.style)
    }
    
    
}
