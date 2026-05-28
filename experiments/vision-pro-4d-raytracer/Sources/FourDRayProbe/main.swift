import Foundation
import Metal

private let width = 64
private let height = 64
private let depth = 32

@main
struct FourDRayProbe {
    static func main() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw ProbeError.noMetalDevice
        }
        guard let queue = device.makeCommandQueue() else {
            throw ProbeError.couldNotCreateCommandQueue
        }

        let library = try device.makeLibrary(source: metalSource, options: nil)
        guard let function = library.makeFunction(name: "raytrace4d_volume") else {
            throw ProbeError.missingKernel
        }
        let pipeline = try device.makeComputePipelineState(function: function)

        let descriptor = MTLTextureDescriptor()
        descriptor.textureType = .type3D
        descriptor.pixelFormat = .rgba8Unorm
        descriptor.width = width
        descriptor.height = height
        descriptor.depth = depth
        descriptor.mipmapLevelCount = 1
        descriptor.usage = [.shaderWrite]
        descriptor.storageMode = .shared

        guard let texture = device.makeTexture(descriptor: descriptor) else {
            throw ProbeError.couldNotCreateTexture
        }
        guard let commandBuffer = queue.makeCommandBuffer(),
              let encoder = commandBuffer.makeComputeCommandEncoder() else {
            throw ProbeError.couldNotCreateCommandBuffer
        }

        encoder.setComputePipelineState(pipeline)
        encoder.setTexture(texture, index: 0)

        let threadsPerThreadgroup = MTLSize(
            width: min(8, pipeline.maxTotalThreadsPerThreadgroup),
            height: 8,
            depth: 4
        )
        let threadgroups = MTLSize(
            width: (width + threadsPerThreadgroup.width - 1) / threadsPerThreadgroup.width,
            height: (height + threadsPerThreadgroup.height - 1) / threadsPerThreadgroup.height,
            depth: (depth + threadsPerThreadgroup.depth - 1) / threadsPerThreadgroup.depth
        )

        encoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadsPerThreadgroup)
        encoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        if let error = commandBuffer.error {
            throw error
        }

        let bytes = readTexture(texture)
        let outputURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appending(path: "tmp", directoryHint: .isDirectory)
            .appending(path: "four-d-ray-probe-ana-mid-slice.ppm")
        try writePPM(bytes: bytes, slice: depth / 2, outputURL: outputURL)

        print("Rendered \(width)x\(height)x\(depth) 4D-projected volume on \(device.name)")
        print("Wrote middle ana slice: \(outputURL.path)")
    }
}

private enum ProbeError: Error {
    case noMetalDevice
    case couldNotCreateCommandQueue
    case missingKernel
    case couldNotCreateTexture
    case couldNotCreateCommandBuffer
}

private func readTexture(_ texture: MTLTexture) -> [UInt8] {
    let bytesPerPixel = 4
    let bytesPerRow = width * bytesPerPixel
    let bytesPerImage = bytesPerRow * height
    var bytes = [UInt8](repeating: 0, count: bytesPerImage * depth)
    let region = MTLRegionMake3D(0, 0, 0, width, height, depth)
    texture.getBytes(
        &bytes,
        bytesPerRow: bytesPerRow,
        bytesPerImage: bytesPerImage,
        from: region,
        mipmapLevel: 0,
        slice: 0
    )
    return bytes
}

private func writePPM(bytes: [UInt8], slice: Int, outputURL: URL) throws {
    try FileManager.default.createDirectory(
        at: outputURL.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )

    let bytesPerPixel = 4
    let bytesPerRow = width * bytesPerPixel
    let bytesPerImage = bytesPerRow * height
    let sliceBase = bytesPerImage * slice

    var output = Data("P6\n\(width) \(height)\n255\n".utf8)
    for y in 0..<height {
        for x in 0..<width {
            let index = sliceBase + y * bytesPerRow + x * bytesPerPixel
            output.append(bytes[index])
            output.append(bytes[index + 1])
            output.append(bytes[index + 2])
        }
    }

    try output.write(to: outputURL)
}

private let metalSource = #"""
#include <metal_stdlib>
using namespace metal;

struct Hit4 {
    bool hit;
    float distance;
    float4 point;
    float4 normal;
};

static float4 reflect4d(float4 direction, float4 normal) {
    float4 d = normalize(direction);
    float4 n = normalize(normal);
    return normalize(d - 2.0f * dot(d, n) * n);
}

static Hit4 intersect_hypersphere(float4 origin, float4 direction, float4 center, float radius) {
    float4 oc = origin - center;
    float a = dot(direction, direction);
    float half_b = dot(oc, direction);
    float c = dot(oc, oc) - radius * radius;
    float discriminant = half_b * half_b - a * c;

    if (discriminant < 0.0f) {
        return { false, 0.0f, float4(0.0f), float4(0.0f) };
    }

    float root = sqrt(discriminant);
    float t = (-half_b - root) / a;
    if (t < 0.0001f) {
        t = (-half_b + root) / a;
    }
    if (t < 0.0001f) {
        return { false, 0.0f, float4(0.0f), float4(0.0f) };
    }

    float4 point = origin + t * direction;
    float4 normal = normalize(point - center);
    return { true, t, point, normal };
}

static Hit4 intersect_hyperplane(float4 origin, float4 direction, float4 normal, float offset) {
    float4 n = normalize(normal);
    float denominator = dot(n, direction);
    if (abs(denominator) <= 0.000001f) {
        return { false, 0.0f, float4(0.0f), float4(0.0f) };
    }

    float t = -(dot(n, origin) + offset) / denominator;
    if (t < 0.0001f) {
        return { false, 0.0f, float4(0.0f), float4(0.0f) };
    }

    return { true, t, origin + t * direction, n };
}

kernel void raytrace4d_volume(texture3d<float, access::write> output [[texture(0)]],
                              uint3 gid [[thread_position_in_grid]]) {
    uint width = output.get_width();
    uint height = output.get_height();
    uint depth = output.get_depth();

    if (gid.x >= width || gid.y >= height || gid.z >= depth) {
        return;
    }

    float u = ((float(gid.x) + 0.5f) / float(width)) * 2.0f - 1.0f;
    float v = ((float(gid.y) + 0.5f) / float(height)) * 2.0f - 1.0f;
    float ana = ((float(gid.z) + 0.5f) / float(depth)) * 2.0f - 1.0f;

    // Default v0 camera basis:
    // right=(1,0,0,0), up=(0,1,0,0), forward=(0,0,1,0), ana=(0,0,0,1).
    float4 origin = float4(0.0f, 0.0f, -3.0f, 0.0f);
    float4 direction = normalize(float4(u, v, 1.0f, ana));

    Hit4 primary = intersect_hypersphere(origin, direction, float4(0.0f), 1.0f);
    if (!primary.hit) {
        float glow = 0.08f + 0.18f * abs(ana);
        output.write(float4(0.01f, glow, 0.10f + 0.10f * abs(u), 1.0f), gid);
        return;
    }

    float4 reflected = reflect4d(direction, primary.normal);
    Hit4 bounce = intersect_hyperplane(
        primary.point + 0.001f * reflected,
        reflected,
        normalize(float4(0.0f, 1.0f, 0.0f, 1.0f)),
        1.35f
    );

    float3 normal_color = 0.5f + 0.5f * primary.normal.xyz;
    float w_tint = 0.5f + 0.5f * primary.normal.w;

    if (bounce.hit) {
        float checker = fmod(floor(bounce.point.x * 3.0f) + floor(bounce.point.z * 3.0f) + floor(bounce.point.w * 3.0f), 2.0f);
        float3 plane_color = mix(float3(1.0f, 0.35f, 0.10f), float3(0.10f, 0.35f, 1.0f), checker);
        output.write(float4(mix(normal_color, plane_color, 0.65f), 1.0f), gid);
    } else {
        output.write(float4(normal_color.x, normal_color.y * w_tint, normal_color.z + 0.25f * w_tint, 1.0f), gid);
    }
}
"""#
