Shader "ScreenSpaceFluids/SSFPro_DepthShaderHQ" {
Properties {
	_MainTex ("Base (RGB)", 2D) = "white" {}
	_PointRadius("Point Radius", Float) = 1.0
	_PointScale("Point Scale", Float) = 1.0
}

SubShader {
	Tags {"RenderType"="Opaque"}
	Pass {
		ZTest LEqual 
	//	ZTest Always 
		Cull Off 
		ZWrite On
		Fog { Mode off }

		CGPROGRAM
		#pragma target 5.0
		#pragma vertex vert
		#pragma fragment frag
	//	#pragma enable_d3d11_debug_symbols

		#include "UnityCG.cginc"
		
		StructuredBuffer<float4> buf_Positions;
		StructuredBuffer<float4> buf_Vertices;
		StructuredBuffer<float2> buf_TexCoords;
		
		uniform sampler2D _MainTex;
		uniform sampler2D _CameraDepthTexture; //the depth texture

		float _PointRadius;
		float _PointScale;

		struct v2f 
		{
			float4 position : POSITION;	
		//	float4 color : COLOR0;
			float2 tex : TEXCOORD0;
			float3 viewPos: TEXCOORD1;
		//	float4 projPos : TEXCOORD2; //Screen position of vertex
		//	float pointSize : PSIZE;
		};


		 v2f vert (uint id : SV_VertexID, uint inst : SV_InstanceID)
		{
			v2f o;

			float4 viewPos = mul(UNITY_MATRIX_MV, float4(buf_Positions[inst].xyz, 1.0)) + float4(buf_Vertices[id].x * _PointScale, buf_Vertices[id].y * _PointScale, 0.0, 0.0);

			o.position = mul(UNITY_MATRIX_P, viewPos);
			o.tex = MultiplyUV(UNITY_MATRIX_TEXTURE0, buf_Vertices[id] + 0.5);
			o.viewPos = viewPos.xyz;
		//	o.projPos = ComputeScreenPos(o.position);
			//	o.pointSize = -_PointScale * _PointRadius / viewPos.z;


			/*FLEX
			    // calculate window-space point size
				gl_Position = gl_ModelViewProjectionMatrix * vec4(gl_Vertex.xyz, 1.0);
				gl_PointSize = pointScale * (pointRadius / gl_Position.w);

				gl_TexCoord[0] = gl_MultiTexCoord0;    
				gl_TexCoord[1] = gl_ModelViewMatrix * vec4(gl_Vertex.xyz, 1.0);
			*/
			return o; 
		}

		struct fragOut
        {
			float color : COLOR;
			float depth : DEPTH;

			//	float4 color : SV_Target;
           //     float depth : SV_Depth;
        };
		
		fragOut frag (v2f i)
		{
			/*	// FLEX
				// calculate normal from texture coordinates
				vec3 normal;
				normal.xy = gl_TexCoord[0].xy*vec2(2.0, -2.0) + vec2(-1.0, 1.0);
				float mag = dot(normal.xy, normal.xy);
				if (mag > 1.0) discard;   // kill pixels outside circle
				normal.z = sqrt(1.0-mag);

				vec3 eyePos = gl_TexCoord[1].xyz + normal*pointRadius*2.0;
				vec4 ndcPos = gl_ProjectionMatrix * vec4(eyePos, 1.0);
				ndcPos.z /= ndcPos.w;

				gl_FragColor = vec4(eyePos.z, 1.0, 1.0, 1.0);
				gl_FragDepth = ndcPos.z*0.5 + 0.5;
			*/

			fragOut OUT;

			// calculate eye-space sphere normal from texture coordinates
			float3 normal;
			normal.xy = i.tex * 2.0 - 1.0;
			//normal.xy = i.tex * float2(2.0, -2.0) + float2(-1.0, 1.0);
			float r2 = dot(normal.xy, normal.xy);
			if (r2 > 1.0)
				discard; // kill pixels outside circle

			normal.z = sqrt(1.0 - r2);

			float3 eyePos = i.viewPos + normal * _PointRadius;//*2.0;
			//float3 eyePos = i.viewPos + normal * _PointRadius * 2.0;
			float4 ndcPos = mul(UNITY_MATRIX_P, float4(eyePos, 1.0));
			ndcPos.z /= ndcPos.w;
			float depth = ndcPos.z;

			//OUT.color = float4(eyePos.z, 1.0, 1.0, 1.0);
			OUT.depth = depth;
			#if defined(UNITY_REVERSED_Z)
				OUT.color = 1.0 - depth;
			#else
				OUT.color = depth;
			#endif
			

			return OUT;

		}
		ENDCG
	}
}

Fallback off

}