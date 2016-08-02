//
//  ViewController.swift
//  swift-metal
//
//  Created by Ryan on 8/1/16.
//  Copyright © 2016 DWishR. All rights reserved.
//

import UIKit
import Metal
import QuartzCore
import GLKit

let PI:Float = 3.141592654

class ViewController: UIViewController
{
    let vertexData:[Float] = [
        0, 0.5, 0,
        -0.66667, -0.66667, 0,
        0.66667, -0.66667, 0
    ]
    
    let colorData:[Float] = [
        1,0,0,
        0,1,0,
        0,0,1
    ]
    
    var scales:[Float] = [ 1,1,1 ]
    var direction:Double = -1
    
    var device: MTLDevice! = nil
    var metalLayer: CAMetalLayer! = nil
    
    var vertexBuffer: MTLBuffer! = nil
    var colorBuffer: MTLBuffer! = nil
    var pipelineState: MTLRenderPipelineState! = nil
    var commandQueue: MTLCommandQueue! = nil
    
    var timer: CADisplayLink! = nil
    var last: CFTimeInterval! = nil
    
    var rot = GLKQuaternionMakeWithAngleAndAxis(PI, 0.707106781186548, 0.707106781186548, 0)
    
    override func viewDidLoad()
    {
        view.contentScaleFactor = UIScreen.mainScreen().nativeScale
        super.viewDidLoad()
        device = MTLCreateSystemDefaultDevice()
        
        metalLayer = CAMetalLayer()
        metalLayer.device = device
        metalLayer.pixelFormat = .BGRA8Unorm
        metalLayer.framebufferOnly = true
        metalLayer.frame = view.layer.frame
        var size = view.bounds.size
        size.width *= view.contentScaleFactor
        size.height *= view.contentScaleFactor
        metalLayer.drawableSize = size
        view.layer.addSublayer(metalLayer)
        
        let vSize = vertexData.count * sizeof(Float)
        vertexBuffer = device.newBufferWithBytes(vertexData, length: vSize, options:MTLResourceOptions())
        
        let cSize = colorData.count * sizeof(Float)
        colorBuffer = device.newBufferWithBytes(colorData, length: cSize, options: MTLResourceOptions())
        
        let defaultLibrary = device.newDefaultLibrary()
        let vertexProgram = defaultLibrary!.newFunctionWithName("basic_vertex")
        let fragmentProgram = defaultLibrary!.newFunctionWithName("basic_fragment")
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .BGRA8Unorm
        pipelineState = try! device.newRenderPipelineStateWithDescriptor(pipelineStateDescriptor)
        
        commandQueue = device.newCommandQueue()
        
        timer = CADisplayLink(target: self, selector: #selector(tick))
        timer.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }

    func render(delta:CFTimeInterval)
    {
        let drawable = metalLayer.nextDrawable()
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable!.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .Clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.25, 0.25, 0.25, 1)
        
        let commandBuffer = commandQueue.commandBuffer()
        
        let renderEncoder = commandBuffer.renderCommandEncoderWithDescriptor(renderPassDescriptor)
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, atIndex: 0)
        renderEncoder.setVertexBuffer(colorBuffer, offset: 0, atIndex: 1)
        renderEncoder.setVertexBytes(scales, length: scales.count*sizeof(Float), atIndex: 2)
        renderEncoder.drawPrimitives(.Triangle, vertexStart: 0, vertexCount: 3)
        renderEncoder.endEncoding()
        
        commandBuffer.presentDrawable(drawable!)
        commandBuffer.commit()
        
        let vec = GLKVector3Make(scales[0], scales[1], scales[2])
        let rotated = GLKQuaternionRotateVector3(GLKQuaternionSlerp(GLKQuaternionIdentity, rot, Float(delta)), vec)
        print("Rotated Vector: \(rotated); x:\(rotated.x), y:\(rotated.y), z:\(rotated.z)")
        scales[0] = rotated.x
        scales[1] = rotated.y
        scales[2] = rotated.z
    }
    
    func tick()
    {
        autoreleasepool
        {
            if((last == nil))
            {
                last = timer.timestamp
            }
            
            render(timer.timestamp - last)
            last = timer.timestamp
        }
    }
}

