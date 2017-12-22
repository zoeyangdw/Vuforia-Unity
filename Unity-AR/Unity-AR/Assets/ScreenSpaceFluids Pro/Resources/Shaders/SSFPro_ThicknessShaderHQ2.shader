// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "ScreenSpaceFluids/SSFPro_ThicknessShaderHQ2" 
{
	Properties {

		_Thickness ("Thickness", Float) = 0.2
		_Softness("Softness", Float) = 2.0
		_PointRadius("Point Radius", Float) = 1.0
		_PointScale("Point Scale", Float) = 1.0
	}

	SubShader {

		//Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
		Pass {

		//Blend SrcAlpha OneMinusSrcAlpha // Traditional transparency
		//Blend One OneMinusSrcAlpha // Premultiplied transparency
		//Blend One One // Additive
		Blend OneMinusDstColor One // Soft Additive
		//Blend DstColor Zero // Multiplicative
		//Blend DstColor SrcColor // 2x Multiplicative

		//	BlendOp Add
		//	ZTest Always 
			ZTest LEqual
			Cull Back 
			ZWrite Off
			Fog { Mode off }



			//glEnable(GL_BLEND);
			//glBlendFunc(GL_ONE, GL_ONE);
			//glBlendEquation(GL_FUNC_ADD);
			//glDepthMask(GL_FALSE);
			////glEnable(GL_DEPTH_TEST);

			CGPROGRAM
			#pragma target 5.0
			#pragma vertex vert
			#pragma geometry geom
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
			float _Thickness;
			float _Softness;

			struct v2g
			{
				float4 pos : POSITION;	
			//	float4 color : COLOR0;
				float2 tex : TEXCOORD0;
			//	float3 posEye: TEXCOORD1;
			//	float3 viewPos: TEXCOORD1;
			//	float4 projPos : TEXCOORD2; //Screen position of vertex
			//	float pointSize : PSIZE;
			};

			struct g2f
			{
				float4 pos : POSITION;
				float2 tex : TEXCOORD0;
				float3 viewPos: TEXCOORD1;
				float4 projPos : TEXCOORD2; //Screen position of vertex
			};

			v2g vert (uint id : SV_VertexID, uint inst : SV_InstanceID)
			{
				v2g o;

				//float4 viewPos = mul(UNITY_MATRIX_MV, float4(buf_Positions[inst].xyz, 1.0)) + float4(buf_Vertices[id].x * _PointScale, buf_Vertices[id].y * _PointScale, 0.0, 0.0);
				//o.position = mul(UNITY_MATRIX_P, viewPos);
				//o.tex = MultiplyUV(UNITY_MATRIX_TEXTURE0, buf_Vertices[id] + 0.5);
				//o.viewPos = viewPos.xyz;
				//o.projPos = ComputeScreenPos(o.position);

				//float4 viewPos = mul(UNITY_MATRIX_MV, float4(buf_Positions[inst].xyz, 1.0)) + float4(buf_Vertices[id].x * _PointScale, buf_Vertices[id].y * _PointScale, 0.0, 0.0);
				//o.pos = mul(UNITY_MATRIX_P, viewPos);
				//o.tex = MultiplyUV(UNITY_MATRIX_TEXTURE0, buf_Vertices[id] + 0.5);
				//o.viewPos = viewPos.xyz;
				//o.projPos = ComputeScreenPos(o.pos);
				o.pos = buf_Positions[id];

				o.tex = float2(0, 0);

				return o; 
			}


			 // Geometry Shader -----------------------------------------------------
			 [maxvertexcount(4)]
			 void geom(point v2g p[1], inout TriangleStream<g2f> triStream)
			 {
				 float3 up = float3(0, 1, 0);
				 float3 look = _WorldSpaceCameraPos - p[0].pos;
				 look.y = 0;
				 look = normalize(look);
				 float3 right = cross(up, look);

				 float halfS = 0.5f * _PointScale;

				 float4 v[4];
				 v[0] = float4(p[0].pos + halfS * right - halfS * up, 1.0f);
				 v[1] = float4(p[0].pos + halfS * right + halfS * up, 1.0f);
				 v[2] = float4(p[0].pos - halfS * right - halfS * up, 1.0f);
				 v[3] = float4(p[0].pos - halfS * right + halfS * up, 1.0f);

				 float4x4 vp = UnityObjectToClipPos(unity_WorldToObject);
				 g2f pIn;
				 pIn.pos = mul(vp, v[0]);
				 pIn.tex = float2(1.0f, 0.0f);
				 pIn.viewPos = v[0].xyz;
				 pIn.projPos = ComputeScreenPos(pIn.pos);
				 triStream.Append(pIn);

				 pIn.pos = mul(vp, v[1]);
				 pIn.tex = float2(1.0f, 1.0f);
				 pIn.viewPos = v[1].xyz;
				 pIn.projPos = ComputeScreenPos(pIn.pos);
				 triStream.Append(pIn);

				 pIn.pos = mul(vp, v[2]);
				 pIn.tex = float2(0.0f, 0.0f);
				 pIn.viewPos = v[2].xyz;
				 pIn.projPos = ComputeScreenPos(pIn.pos);
				 triStream.Append(pIn);

				 pIn.pos = mul(vp, v[3]);
				 pIn.tex = float2(0.0f, 1.0f);
				 pIn.viewPos = v[3].xyz;
				 pIn.projPos = ComputeScreenPos(pIn.pos);
				 triStream.Append(pIn);
			 }

			 //struct fragOut
			 //{
				// float4 color : COLOR;
				// float depth : DEPTH;
			 //};

			float frag (g2f i) : COLOR
			{
			//	fragOut OUT;

				float sceneDepth = tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos)).r;
				#if defined(UNITY_REVERSED_Z)
					sceneDepth = 1.0f - sceneDepth;
				#endif
				// calculate eye-space sphere normal from texture coordinates
				float3 N;
				N.xy = i.tex * 2.0 - 1.0;
				float r2 = dot(N.xy, N.xy);
				if (r2 > 1.0) 
					discard; // kill pixels outside circle
				N.z = sqrt(1.0 - r2);

				float thickness = N.z * _Thickness;
				float alpha = exp(-r2 * _Softness);
				
				//return thickness;

				float3 eyePos = i.viewPos + N * _PointRadius;//*2.0;
				float4 ndcPos = mul(UNITY_MATRIX_P, float4(eyePos, 1.0));
				ndcPos.z /= ndcPos.w;

				float depth = ndcPos.z;
			//	OUT.depth = depth;

				/* FROM FLEX
					// calculate normal from texture coordinates
					vec3 normal;
					normal.xy = gl_TexCoord[0].xy*vec2(2.0, -2.0) + vec2(-1.0, 1.0);
					float mag = dot(normal.xy, normal.xy);
					if (mag > 1.0) discard;   // kill pixels outside circle
					normal.z = sqrt(1.0 - mag);

					gl_FragColor = vec4(normal.z*0.005);
				*/

				//Gaussian Distribution
				//float dist = length(i.tex- float2(0.5f, 0.5f));
				//float sigma = 3.0f;
				//float mu = 0.0f;
				//float g_dist = 0.02f * exp(-(dist-mu)*(dist-mu)/(2*sigma));
				//thickness = g_dist;

				//NORMAL
				//OUT.color = float4(normal * 0.5 + 0.5, 1);

				//DEPTH
				//float linearDepth = Linear01Depth(depth);
				//float linearDepth = Linear01Depth(tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos)).r);
				//OUT.color = float4(linearDepth, linearDepth, linearDepth, 1);


			//	float color = thickness * alpha;
				float color = (sceneDepth < depth) ? 0 : thickness * alpha;
			
				return color = clamp(color, 0.0, 1.0);


			}
			ENDCG
		}
	}

	Fallback off

}