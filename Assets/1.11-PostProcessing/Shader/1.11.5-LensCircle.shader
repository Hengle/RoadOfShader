﻿Shader "RoadOfShader/1.11-PostProcessing/Lens Circle"
{
    Properties
    {
        _MainTex ("Main Tex", 2D) = "white" { }
        _InnerRadius ("Inner Radius", Range(0, 1)) = 0.4
        _OuterRadius ("Outer Radius", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags { "Queue" = "Geometry" "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" }
        
        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            Cull Off
            ZWrite Off
            ZTest Always
            
            HLSLPROGRAM
            
            // Required to compile gles 2.0 with standard SRP library
            // All shaders must be compiled with HLSLcc and currently only gles is not using HLSLcc by default
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Assets/_Libs/Tools.hlsl"
            
            #pragma vertex vert
            #pragma fragment frag
            
            struct Attributes
            {
                float4 positionOS: POSITION;
                float2 uv: TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            struct Varyings
            {
                float4 vertex: SV_POSITION;
                float2 uv: TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_TexelSize;
            half _InnerRadius;
            half _OuterRadius;
            CBUFFER_END
            
            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);
            
            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                
                output.vertex = TransformObjectToHClip(input.positionOS.xyz);
                float2 uv = input.uv;
                
                //当有多个RenderTarget时，需要自己处理UV翻转问题
                #if UNITY_UV_STARTS_AT_TOP //DirectX之类的
                    if (_MainTex_TexelSize.y < 0) //开启了抗锯齿
                    uv.y = 1 - uv.y; //满足上面两个条件时uv会翻转，因此需要转回来
                #endif
                
                output.uv = uv;
                
                return output;
            }
            
            half4 frag(Varyings input): SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                
                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
                float2 center = float2(0.5, 0.5);
                float dist = distance(center, input.uv);
                col *= smoothstep(_OuterRadius, _InnerRadius, dist);
                return col;
            }
            ENDHLSL
            
        }
    }
}
