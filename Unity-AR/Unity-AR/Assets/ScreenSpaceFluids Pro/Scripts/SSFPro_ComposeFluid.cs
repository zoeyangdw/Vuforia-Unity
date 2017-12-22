using UnityEngine;
using System.Collections;


namespace SSF
{
  //  [ExecuteInEditMode]
    public class SSFPro_ComposeFluid : UnityStandardAssets.ImageEffects.ImageEffectBase
    {
        public bool debug = false;

        public Color m_color = Color.blue;
        public Color m_specular = Color.white;

        public float m_shininess = 64f;
        public float m_reflection = 0f;
        public float m_reflectionFalloff = 10.0f;
        public float m_refraction = 0.0f;
        public float m_indexOfRefraction = 0.01f;
        public float m_fresnel = 1.0f;


        public float m_maxDepth = 0.9999f;
        public float m_minThickness = 0.0f;

        public float m_xFactor = 0.001f;
        public float m_YFactor = 0.001f;

        public RenderTexture m_colorTexture;
        public RenderTexture m_depthTexture;
        public RenderTexture m_thicknessTexture;
        public RenderTexture m_blurredDepthTexture;
        public RenderTexture m_foamTexture;

        public Cubemap m_cubemap;

        private float m_minDepth = 0.0f;

        protected override void Start()
        {
            base.Start();

            material.SetTexture("_ColorTex", m_colorTexture);
            material.SetTexture("_DepthTex", m_depthTexture);
            material.SetTexture("_BlurredDepthTex", m_blurredDepthTexture);
            material.SetTexture("_ThicknessTex", m_thicknessTexture);
            material.SetTexture("_FoamTex", m_foamTexture);
            material.SetTexture("_Cube", m_cubemap);
        }

        // Called by the camera to apply the image effect
        void OnRenderImage(RenderTexture source, RenderTexture destination)
        {
            material.SetFloat("_XFactor", m_xFactor);
            material.SetFloat("_YFactor", m_YFactor);
            material.SetFloat("_MinDepth", m_minDepth);
            material.SetFloat("_MaxDepth", m_maxDepth);

            material.SetColor("_Color", m_color);
            material.SetColor("_Specular", m_specular);

            material.SetFloat("_Shininess", m_shininess);
            material.SetFloat("_FresnelFalloff", m_reflectionFalloff);
            material.SetFloat("_Reflection", m_reflection);
            
            material.SetFloat("_Refraction", m_refraction);
            material.SetFloat("_IndexOfRefraction", m_indexOfRefraction);
            material.SetFloat("_MinThickness", m_minThickness);
            material.SetFloat("_Fresnel", m_fresnel);

            if (!debug)
            {
                Graphics.Blit(source, destination, material);
            }
            else
            {
                Graphics.Blit(m_thicknessTexture, destination);
                //Graphics.Blit(m_blurredDepthTexture, destination);
                //Graphics.Blit(m_thicknessTexture, destination);
            }

        }


    }

}