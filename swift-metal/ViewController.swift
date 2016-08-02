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
    
    var device: MTLDevice! = nil
    var metalLayer: CAMetalLayer! = nil
    
    var vertexBuffer: MTLBuffer! = nil
    var colorBuffer: MTLBuffer! = nil
    var pipelineState: MTLRenderPipelineState! = nil
    var commandQueue: MTLCommandQueue! = nil
    
    
    var timer: CADisplayLink! = nil
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        device = MTLCreateSystemDefaultDevice()
        
        metalLayer = CAMetalLayer()
        metalLayer.device = device
        metalLayer.pixelFormat = .BGRA8Unorm
        metalLayer.framebufferOnly = true
        metalLayer.frame = view.layer.frame
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
        // Dispose of any resources that can be recreated.
    }

    func render()
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
        renderEncoder.drawPrimitives(.Triangle, vertexStart: 0, vertexCount: 3)
        renderEncoder.endEncoding()
        
        commandBuffer.presentDrawable(drawable!)
        commandBuffer.commit()
    }
    
    func tick()
    {
        autoreleasepool
        {
            render()
        }
    }
}

