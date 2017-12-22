// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "ScreenSpaceFluids/SSFPro_ComposeFluidHQ2"
{
	Properties
	{
		_Color("Fluid Color", Color) = (1,1,1,0)
		_Specular("Specular Color", Color) = (1,1,1,0)
		_ColorFalloff("Falloff Color", Color) = (1,0,1,0)

		_Reflection("Reflection", Float) = 0.1
		_Fresnel("Fresnel", Float) = 1.0
		_FresnelFalloff("Fresnel Falloff", Float) = 10.0

		_Refraction("Refraction", Float) = 0.1
		_IndexOfRefraction("IndexOfRefraction", Float) = 0.1

		_MinDepth("Min Depth", Float) = 0.000
		_MaxDepth("Max Depth", Float) = 0.999

		_XFactor("X Factor", Float) = 0.001
		_YFactor("Y Factor", Float) = 0.001

		_Shininess("Shininess", Float) = 0.1

		_MinThickness("MinThickness", Float) = 0.5

		_MainTex("Texture", 2D) = "white" {}
		_ColorTex("Color Tex", 2D) = "white" {}
		_DepthTex("Depth Tex", 2D) = "white" {}
		_BlurredDepthTex("Blurred Depth Tex", 2D) = "white" {}
		_ThicknessTex("Thickness Tex", 2D) = "white" {}
		_FoamTex("Foam Tex", 2D) = "white" {}
		_Cube("Cubemap", CUBE) = "" {}
	}

		SubShader
	{
		// No culling or depth
			Cull Off
			//ZWrite Off
			ZWrite On
			ZTest Always

			Pass
		{
			CGPROGRAM
			#pragma target 5.0
			//#pragma enable_d3d11_debug_symbols
			#pragma vertex vert
			#pragma fragment frag
		

			#include "UnityCG.cginc"
			float4 _Color;
			float4 _Specular;

			float _MinDepth;
			float _MaxDepth;
			float _XFactor;
			float _YFactor;
			float _FresnelFalloff;
			float _Shininess;
			float _Fresnel;
			float _Reflection;
			float _MinThickness;
			float _Refraction;
			float _IndexOfRefraction;

			sampler2D _MainTex;
			sampler2D _ColorTex;
			sampler2D _DepthTex;
			sampler2D _BlurredDepthTex;
			sampler2D _ThicknessTex;
			sampler2D _FoamTex;

			float4 _MainTex_TexelSize;

			samplerCUBE _Cube;

			uniform sampler2D_float _CameraDepthTexture; //the depth texture

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			//	float2 coord : TEXCOORD1;
			//	float4 projPos : TEXCOORD2; //Screen position of vertex
			};

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
			//	o.projPos = ComputeScreenPos(o.vertex);
				//o.coord = MultiplyUV(UNITY_MATRIX_TEXTURE0, v.uv.xy);

				return o;
			}

			struct fragOut
			{
				float4 color : COLOR;
				float depth : DEPTH;
			};


			float3 uvToEye(float2 texCoord, float z)
			{
				// Convert texture coordinate to homogeneous space
				float zFar = _ProjectionParams.z;
				float zNear = _ProjectionParams.y;

				float2 xyPos = (texCoord * 2.0 - 1.0);
				float a = zFar / (zFar - zNear);
				float b = zFar*zNear / (zNear - zFar);
				float rd = b / (z - a);

				return float3(xyPos.x, xyPos.y, -1.0) * rd;

			}


			//FLEX - did not work
			float3 viewportToEyeSpace(float2 coord, float eyeZ)
			{
				// find position at z=1 plane

				float screenAspect = _ScreenParams.x / _ScreenParams.y;
				float fov = 1.0472; //60deg
				float2 clipPosToEye = float2( tan(fov*0.5f)*screenAspect, tan(fov*0.5f) );
				float2 uv = (coord*2.0 - float2(1.0, 1.0))*clipPosToEye;

				return float3(-uv*eyeZ, eyeZ);
			}

			fragOut frag(v2f i)
			//float4 frag(v2f i) : SV_Target 
			{
				fragOut OUT;

				float2 uv = i.uv;
				#if UNITY_UV_STARTS_AT_TOP
				if (_MainTex_TexelSize.y < 0)
					uv.y = 1 - uv.y;
				#endif

				float4 sceneCol = tex2D(_MainTex, i.uv);
				float4 foamCol = tex2D(_FoamTex, i.uv);

				float depth = tex2D(_BlurredDepthTex, uv);
				//float sceneDepth = tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos)).r;
				float sceneDepth = tex2D(_CameraDepthTexture, uv.xy);
				float thickness = max(tex2D(_ThicknessTex, uv.xy), _MinThickness);

				#if defined(UNITY_REVERSED_Z)
					sceneDepth = 1.0f - sceneDepth;
					//depth = 1.0f - depth;
				#endif

				if (depth <= _MinDepth)
				{
					OUT.color = _Color;
					OUT.depth = 0.0;
					return OUT;
				}
				else if (depth >= _MaxDepth)
				{
					OUT.color = sceneCol;
					OUT.depth = 1.0;
					return OUT;
				}


				// reconstruct eye space pos from depth
				float3 eyePos = uvToEye(uv, depth);

				//HQ NORMAL
			//	float2 texCoord1 = float2(i.coord.x + _XFactor, i.coord.y);
			//	float2 texCoord2 = float2(i.coord.x - _XFactor, i.coord.y);
				float2 texCoord1 = float2(uv.x + _XFactor, uv.y);
				float2 texCoord2 = float2(uv.x - _XFactor, uv.y);

				// finite difference approx for normals, can't take dFdx because
				// the one-sided difference is incorrect at shape boundaries
				float3 ddx1 = uvToEye(texCoord1, tex2D(_BlurredDepthTex, texCoord1.xy)) - eyePos;
				float3 ddx2 = eyePos - uvToEye(texCoord2, tex2D(_BlurredDepthTex, texCoord2.xy));

				if (abs(ddx1.z) > abs(ddx2.z))
				{
					ddx1 = ddx2;
				}

			//	texCoord1 = float2(i.coord.x, i.coord.y + _YFactor);
			//	texCoord2 = float2(i.coord.x, i.coord.y - _YFactor);
				texCoord1 = float2(uv.x, uv.y + _YFactor);
				texCoord2 = float2(uv.x, uv.y - _YFactor);

				float3 ddy1 = uvToEye(texCoord1, tex2D(_BlurredDepthTex, texCoord1.xy)) - eyePos;
				float3 ddy2 = eyePos - uvToEye(texCoord2, tex2D(_BlurredDepthTex, texCoord2.xy));
				
				if (abs(ddy1.z) > abs(ddy2.z))
				{
					ddy1 = ddy2;
				}

				float3 normal = cross(ddx1, ddy1);
				normal = normalize(normal);

				//NORMAL
				//float3 normal = -normalize(cross(ddx(eyePos.xyz), ddy(eyePos.xyz)));

				//AMBIENT
				float3 ambient = _Color.rgb * UNITY_LIGHTMODEL_AMBIENT.rgb;

				//DIFFUSE
				//float3 lightDir = normalize(float3(1, 1, 1));
				float3 lightDir = mul(UNITY_MATRIX_MV, float4(normalize(_WorldSpaceLightPos0.xyz), 0.0));
				float diffuseMul = max(0.0, dot(normal, lightDir)) * 0.5 + 0.5;
				//float diffuseMul = dot(normal, lightDir) * 0.5 + 0.5;
				//loat diffuseMul = max(0.0, dot(normal, lightDir));
				float3 diffuse = _Color.rgb * diffuseMul;

				//SPEC
				float3 v = -normalize(eyePos);
				float3 h = normalize(lightDir + v);
				float specularMul = pow(max(0.0, dot(normal, h)), _Shininess);
				float3 specular = _Specular.xyz * specularMul * _Specular.a;


				//float fresnel = 0.1 + (1.0 - 0.1)*cube(1.0-max(dot(n, v), 0.0));
				float fresnel =  (0.1 + (1.0 - 0.1) * pow(1.0 - max( dot(normal, v), 0.0), 3.0 ))  * _Fresnel;
				
				//REFLECTION

				float3 reflectVec = reflect(-v, normal);
				//float3 reflection = texCUBE(_Cube, reflectVec) * _Fresnel;
				float3 reflection = pow(texCUBE(_Cube, reflectVec), _FresnelFalloff) * _Reflection;
				//reflection = texCUBE(_Cube, reflectVec) * _Reflection;
			
				//vec2 sceneReflectCoord = gl_TexCoord[0].xy - rEye.xy*texScale*reflectScale/eyePos.z;	
				//vec3 sceneReflect = (texture2D(sceneTex, sceneReflectCoord).xyz)*shadow;
				//vec3 planarReflect = texture2D(reflectTex, gl_TexCoord[0].xy).xyz;

				// fade out planar reflections above the ground
				//vec3 reflect = mix(planarReflect, sceneReflect, smoothstep(0.05, 0.3, worldPos.y)) + mix(groundColor, skyColor, smoothstep(0.15, 0.25, rWorld.y)*shadow);
	

				//REFRACTION
				//float refractScale = ior*0.025;
				//float reflectScale = ior*0.1;

				//refractScale *= smoothstep(0.1, 0.4, worldPos.y);
				//	vec2 refractCoord = gl_TexCoord[0].xy + n.xy*refractScale*texScale;	
				//float2 refractCoord = i.uv + (normal.xy * thickness * _IndexOfRefraction);	
				float2 refractCoord = i.uv + (normal.xy * thickness * _IndexOfRefraction);	
				//float thickness2 = max(tex2D(_ThicknessTex, uv.xy + (normal.xy * _IndexOfRefraction) ), _MinThickness);
		

				//vec3 transmission = (1.0-(1.0-color.xyz)*thickness*0.8)*color.w; 
				//vec3 refract = texture2D(sceneTex, refractCoord).xyz*transmission;
			
				float3 refraction = tex2D(_MainTex, refractCoord ) * _Refraction;
				//float3 transmission = (1.0-(1.0- _Color.rgb)*thickness2*0.8); 
				//float3 refraction = tex2D(_MainTex, refractCoord) * transmission * _Refraction;


				//COMPOSE
				float alpha = clamp(thickness, 0.0, 1.0) * _Color.a;

				//gl_FragColor.xyz = diffuse + (mix(refract, reflect, fresnel) + specular)*color.w;
				//float4 fluidCol = float4(diffuse + ambient + specular + reflection + refraction, alpha);
				float4 fluidCol = float4(diffuse + ambient + specular + lerp(refraction, reflection, fresnel), alpha);
				//float4 fluidCol = float4(reflection + refraction, alpha);


				//float4 fluidCol = float4(normal*0.5f + 0.5f, 1.0f);
				fluidCol = clamp(fluidCol, 0.0, 1.0);
				bool culled = (sceneDepth < depth);
				OUT.color = (culled) ? sceneCol : lerp(sceneCol, fluidCol, alpha);

							//	float sceneLinDepth = Linear01Depth (sceneDepth);
				//OUT.color = float4(sceneLinDepth, sceneLinDepth, sceneLinDepth, 1.0);

			//	OUT.color += foamCol;
				OUT.depth = (culled) ? sceneDepth : depth;

				//UNITY_OUTPUT_DEPTH((culled) ? sceneDepth : depth);


				return OUT;

			}
			ENDCG
		}
	}
}

