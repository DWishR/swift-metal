//
//  Shaders.metal
//  swift-metal
//
//  Created by Ryan on 8/1/16.
//  Copyright © 2016 DWishR. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct VertexOutput
{
    float4 position [[ position ]];
    float4 color;
};

vertex VertexOutput basic_vertex(
        const device packed_float3* vertex_array [[ buffer(0) ]],
        const device packed_float3* color_array [[ buffer(1) ]],
        uint vid [[ vertex_id ]])
{
    VertexOutput vo;
    vo.position = float4(vertex_array[vid], 1);
    vo.color = float4(color_array[vid][0], color_array[vid][1], color_array[vid][2],1);
    return vo;
}

fragment float4 basic_fragment( VertexOutput vert [[stage_in]] )
{
    return vert.color;
}
