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

                            .onTapGesture(count: 2) {
                                scene.handleDoubleTap()
                            }
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
