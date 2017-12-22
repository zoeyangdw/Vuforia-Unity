Screen Space Fluids Pro (SSF Pro) v0.31
support: korzenio [at] gmail.com

Screen Space Fluids Pro (SSF Pro) is a set of high-quality shaders for rendering the surface of particle-based fluids with real-time performance and configurable speed/quality. 

SSF Pro contains all the shaders from free version of SSF (http://u3d.as/uRK) + their high quality (HQ) versions + Pro Components enabling fluid transparency with refratction.

The SSF method is not based on polygonization and as such circumvents the usual grid artifacts of marching cubes.
The shaders smooths the surface to prevent the fluid from looking "blobby" or jelly-like.
It only renders the surface where it is visible, and has inherent view-dependent level-of-detail. 
All the processing, rendering and shading steps are directly implemented on graphics hardware. 

SSF provides only fluid visualization that can be used, for example, with Unity's Particle System. 
However, SSF works best with some third-party fluid simulation library such as uFlex (http://u3d.as/r50). 

SSF Pro is under development and, at the current stage, is targeted at early adopters. 
Any bug reports and feature requests are more than welcome.

----Requirements---
This asset requires GPU with Compute Buffers support (e.g. DX11)


----QuickStart-----
1. Import ScreenSpaceFluids Pro package
2. If Standard Effects package already imported -> delete ScreenSpaceFluids/Standard Assets folder (only ImageEffectsBase.cs required)
3. Add TurnOnDepthBuffer component to the Camera. 
4. Add SSFPro_ComposeFluid image effect to the Camera. Select the SSF_ComposeFluidHQ shader. Set the Blurred Depth Texture Slot to SSF_BlurredDepthTexture and set the Cubemap (usually same as skybox)
5. Add SSFPro_FluidRenderer to a ParticleSystem. Set Depth Texture Slot to SSF_DepthTexture, urred Depth Texture Slot to SSF_BlurredDepthTexture and Blurred Depth Temp Texture to SSF_BlurredDepthTempTexture.
6. Enjoy!

For video tutorials subscribe to SSF channel (https://www.youtube.com/playlist?list=PLkKm77tYcGu9Fz9NlMN0S-SgLYKC8oMzb)

Forum http://forum.unity3d.com/threads/screen-space-fluids-shaders-released.411867/

----ChangeLog
v0.31
-Fix for Unity 5.5

v0.3
-Added integration with uFlex
-Fresnel reflections
-Foam rendering (require uFlex, experimental)

v0.2
-New SSFPro_ComposeFluid and SSFPro_FluidRenderer components
-Transparency with refractions (demo scene SSFPro_WaterTransHQ)

v0.1 - first public release
-High Quality Opaque Ambient + Diffuse + Specular + Reflections fluid shader


----Future work--
-Translucency with volumetric absorption (Beer's Law) 
-Improved lighting support
-Shadows 
-Surface noise 
-Caustics 