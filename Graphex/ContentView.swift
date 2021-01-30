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
        
        if result <= 0 {
            result += CGFloat(2.0 * Double.pi)
        }
        return (result)
    }
    
    func distanceBetween(_ a: Node, _ b: Node) -> CGPoint {
        return CGPoint(x: b.x - a.x, y: b.y - a.y)
    }
    
    func intersectPoint(_ nodeA: Node, _ nodeB: Node) -> CGPoint {
        return CGPoint(x: nodeB.x + (22.5 * cos(angleOf(nodeB, nodeA))), y: nodeB.y + (22.5 * sin(angleOf(nodeB, nodeA))))
    }
    
    
    
    var body: some View {
        
        ZStack(alignment: .trailing) {
            
            //MARK: Drawing Layer
            GeometryReader { g in
                
                //MARK: EDGES
                ForEach(vm.edges) { edge in
                    Path { path in
                        path.move(to: CGPoint(x: edge.nodeA.x, y: edge.nodeA.y))
                        path.addLine(to: intersectPoint(edge.nodeA, edge.nodeB))
                        
                        
                    }
                    .stroke(selectedEdge == edge ? Color.blue : Color.black, lineWidth: 5)
                    .onTapGesture {
                        selectedEdge = edge
                        selectedNode = nil
                    }
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 20)
                        .overlay(Image(systemName: "triangle.fill").foregroundColor(selectedEdge == edge ? .blue : .black).rotationEffect(Angle(radians: (Double.pi/2.0) + Double(angleOf(edge.nodeA, edge.nodeB)) )))
                        .position(x: intersectPoint(edge.nodeA, edge.nodeB).x, y: intersectPoint(edge.nodeA, edge.nodeB).y)
                }
                
                //MARK: NODES
                ForEach(vm.nodes) { node in
                    Circle()
                        .fill(Color.white)
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
                    
                    if (selectedNode != nil) {
                        // node view
                        HStack {
                        Text("Node: \(selectedNode!.name)")
                        Spacer()
                            Button(action: {
                                vm.deleteNode(selectedNode!)
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
                        // edge view
                        HStack {
                            Text("Edge \(selectedEdge!.nodeA.name) to \(selectedEdge!.nodeB.name)")
                            Spacer()
                            Button(action: {
                                vm.deleteEdge(selectedEdge!)
                                selectedEdge = nil
                            }) {
                                Text("Remove").bold()
                                    .padding()
                                    .foregroundColor(.red)
                                    .background(Color.red.opacity(0.2))
                                    .cornerRadius(10)
                            }
                        }
                    } else {
                        // empty
                        Text("No element selected...")
                    }
                    
                    
                    
                    Text("Nodes").font(.headline)
                    List(vm.nodes) { node in
                        Text("Node \(node.name)")
                            .foregroundColor(node == selectedNode ? .green : .primary)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedEdge = nil
                                selectedNode = node
                            }
                    }
                    Text("Edges").font(.headline)
                    List(vm.edges) { edge in
                        Text("\(edge.nodeA.name) → \(edge.nodeB.name)")
                            .foregroundColor(edge == selectedEdge ? .green : .primary)
                            .contentShape(Rectangle())
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
    
    func deleteEdge(_ edge: Edge) {
        edges.removeAll(where: {
            $0 == edge
        })
    }
    
    func deleteNode(_ node: Node) {
        edges.removeAll(where: {
            $0.nodeA == node || $0.nodeB == node
        })
        
        nodes.removeAll(where: {
            $0 == node
        })
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
