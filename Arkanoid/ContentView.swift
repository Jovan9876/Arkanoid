//
//  ContentView.swift
//  Arkanoid
//
//  Created by Jovan on 2025-02-19.
//

import SwiftUI
import SceneKit
import SpriteKit


struct ContentView: View {
    var body: some View {

        NavigationStack {
            List {
                NavigationLink {
                    let scene = Box2DDemo()
                    VStack {
                        SceneView(scene: scene, pointOfView: scene.cameraNode)
                            .ignoresSafeArea()
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        let deltaX = Float(value.translation.width * 0.005)
                                        scene.movePaddle(to: deltaX)
                                    }
                            )
                            .onTapGesture(count: 2) {
                                scene.handleDoubleTap()
                            }
//                        Button(action: {
//                            scene.resetPhysics()
//                        }, label: {
//                            Text("Reset")
//                                .font(.system(size: 24))
//                                .padding(.bottom, 50)
//                        })
                    }
                    .background(.black)
                } label: { Text("Arkanoid: Box2D") }
                    .onSubmit {
                        print("Submit")
                    }
            }.navigationTitle("Arkanoid")
                
                
            }
        }
        
    }


#Preview {
    ContentView()
}
