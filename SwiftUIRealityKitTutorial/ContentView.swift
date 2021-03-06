//
//  ContentView.swift
//  SwiftUIRealityKitTutorial
//
//  Created by Gove Allen on 11/27/21.
//

import SwiftUI
import RealityKit
import ARKit
import FocusEntity


struct ContentView : View {
    @State private var isPlacementEnabled = false
    @State private var selectedModel: Model?
    @State private var modelConfirmedForPlacement: Model?
    
    private let models: [Model] = {
        // dynamiccly get filesn names
        
        let filemanager = FileManager.default
        
        guard let path = Bundle.main.resourcePath, let files = try? filemanager.contentsOfDirectory(atPath: path) else {return []}
        
        var avaliableModels: [Model] = []
        for f in files where f.hasSuffix(".usdz"){
            let modelName = f.replacingOccurrences(of: ".usdz", with: "")
            let model  = Model(modelName: modelName)
            avaliableModels.append(model)
        }
        
        return avaliableModels
    }()
    
    
    var body: some View {
        ZStack(alignment: .bottom){
            ARViewContainer(modelConfirmedForPlacement: $modelConfirmedForPlacement)
            if isPlacementEnabled {
                PlacementButtonsView(isPlacementEnabled: $isPlacementEnabled, selectedModel: $selectedModel, modelConfirmedForPlacement: $modelConfirmedForPlacement)
            } else {
                ModelPickerView(isPlacementEnabled: $isPlacementEnabled, selectedModel: $selectedModel, models: models)
            }
        }
        
    }
}

struct ARViewContainer: UIViewRepresentable {
    @Binding var modelConfirmedForPlacement: Model?
    
    func makeUIView(context: Context) -> ARView {
        
        let arView = ARView(frame: .zero)
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic
        
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh){
            config.sceneReconstruction = .mesh
        }
        
        arView.session.run(config)
        
        // add the focus entity to the ARView
        let _ = FocusEntity(on: arView, focus: .classic)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        if let model = modelConfirmedForPlacement{
            // add model to scene
            if let modelEntity = model.modelEntity {
                let anchorEntity = AnchorEntity(plane: .any)
                anchorEntity.addChild(modelEntity.clone(recursive: true))
                uiView.scene.addAnchor(anchorEntity)
            }else{
                // model not avaliable
            }
          
            
            DispatchQueue.main.async {
                modelConfirmedForPlacement = nil
            }
        }
    }
    
}

struct ModelPickerView: View {
    @Binding var isPlacementEnabled: Bool
    @Binding var selectedModel: Model?
    var models: [Model]
    
    var body: some View{
        ScrollView(.horizontal, showsIndicators: false){
            HStack(spacing:30){
                ForEach(0 ..< models.count){ index in
                    Button(action: {
                        print("DEBUG: selected \(models[index])")
                        self.isPlacementEnabled = true
                        selectedModel = models[index]
                    }){
                        Image(uiImage: self.models[index].image)
                            .resizable()
                            .frame(height: 80)
                            .aspectRatio(1, contentMode: .fit)
                    }.buttonStyle(.plain)
                }
            }
        }
        .padding(20)
        .background(Color.black.opacity(0.5))
    }
}

struct PlacementButtonsView:View{
    @Binding var isPlacementEnabled: Bool
    @Binding var selectedModel: Model?
    @Binding var modelConfirmedForPlacement: Model?
    var body: some View{
        HStack{
            // cancle button
            Button(action: {
                print("DUBUG: Cancle clicked")
                self.resetPlacementParameters()
            }){
                Image(systemName: "xmark")
                    .frame(width: 60, height: 60)
                    .font(.title)
                    .background(Color.white.opacity(0.75))
                    .cornerRadius(30)
                    .padding(20)
            }
            
            // confirm
            Button(action: {
                print("DUBUG: Confirm clicked")
                self.modelConfirmedForPlacement = self.selectedModel
                self.resetPlacementParameters()
            }){
                Image(systemName: "checkmark")
                    .frame(width: 60, height: 60)
                    .font(.title)
                    .background(Color.white.opacity(0.75))
                    .cornerRadius(30)
                    .padding(20)
            }
        }

    }
    
    func resetPlacementParameters(){
        isPlacementEnabled = false
        selectedModel = nil
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
