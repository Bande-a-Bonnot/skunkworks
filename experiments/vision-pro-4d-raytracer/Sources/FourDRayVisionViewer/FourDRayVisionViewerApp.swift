#if os(visionOS)
import SwiftUI
import RealityKit
import UIKit

@main
struct FourDRayVisionViewerApp: SwiftUI.App {
    var body: some SwiftUI.Scene {
        WindowGroup {
            VolumeViewerView()
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 1.1, height: 1.1, depth: 1.1, in: .meters)
    }
}

struct VolumeViewerView: View {
    private let points = PointCloudSample.generate(width: 16, height: 16, depth: 8)

    var body: some View {
        ZStack(alignment: .bottom) {
            RealityView { content in
                let root = Entity()
                root.name = "4D-to-3D projection volume"
                root.scale = SIMD3<Float>(repeating: 0.42)

                let markerMesh = MeshResource.generateSphere(radius: 0.009)
                for point in points {
                    var material = UnlitMaterial()
                    material.color = .init(tint: UIColor(
                        red: CGFloat(clamped(point.color.x)),
                        green: CGFloat(clamped(point.color.y)),
                        blue: CGFloat(clamped(point.color.z)),
                        alpha: 0.92
                    ))

                    let marker = ModelEntity(mesh: markerMesh, materials: [material])
                    marker.position = point.position
                    root.addChild(marker)
                }

                content.add(root)
            }

            Text("4D ray volume · x=u · y=v · z=ana · \(points.count) points")
                .font(.caption)
                .padding(10)
                .glassBackgroundEffect()
                .padding(.bottom, 24)
        }
    }

    private func clamped(_ value: Float) -> Float {
        min(max(value, 0), 1)
    }
}
#else
@main
struct FourDRayVisionViewerHostFallback {
    static func main() {
        print("FourDRayVisionViewer is a visionOS RealityKit prototype.")
        print("Build/run it for visionOS in Xcode or with xcodebuild; use FourDRayProbe on macOS to export PLY/contact-sheet artifacts.")
    }
}
#endif
