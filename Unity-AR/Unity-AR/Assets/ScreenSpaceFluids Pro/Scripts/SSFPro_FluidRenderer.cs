using UnityEngine;
using System.Collections;

namespace SSF
{
 //   [ExecuteInEditMode]
    public class SSFPro_FluidRenderer : MonoBehaviour
    {

        public ParticleSystem m_ps;
        public int m_particlesCount = 0;

        public RenderTexture m_colorTexture;
        public RenderTexture m_depthTexture;
        public RenderTexture m_blurredDepthTexture;
        public RenderTexture m_blurredDepthTempTexture;
        public RenderTexture m_thicknessTexture;

        private Color m_color = Color.gray;
        public float m_pointScale = 1.0f;
        public float m_pointRadius = 1.0f;

        public bool m_blur = true;
        public float m_blurScale = 1f;
        public int m_blurRadius = 10;
        public float m_blurDepthFalloff = 100.0f;
        public float m_minDepth = 0.0f;

        public float m_thickness = 1.0f;
        public float m_softness = 1.0f;

        private Material m_colorMaterial;
        private Material m_depthMaterial;
        private Material m_blurDepthMaterial;
        private Material m_thicknessMaterial;

        private ComputeBuffer m_posBuffer;
        private ComputeBuffer m_colorBuffer;
        private ComputeBuffer m_quadVerticesBuffer;

        private Vector4[] m_positions;

        private Vector3[] m_velocities;

        private Color[] m_colors;

 

        private ParticleSystem.Particle[] m_particles;

        

        // Use this for initialization
        void Start()
        {

            m_colorMaterial = new Material(Shader.Find("ScreenSpaceFluids/SSF_SpherePointsShader"));
            m_depthMaterial = new Material(Shader.Find("ScreenSpaceFluids/SSF_DepthShader"));
            m_thicknessMaterial = new Material(Shader.Find("ScreenSpaceFluids/SSF_ThicknessShader"));
            m_blurDepthMaterial = new Material(Shader.Find("ScreenSpaceFluids/SSF_BlurDepth"));

            m_colorMaterial.hideFlags = HideFlags.HideAndDontSave;
            m_depthMaterial.hideFlags = HideFlags.HideAndDontSave;
            m_thicknessMaterial.hideFlags = HideFlags.HideAndDontSave;
            m_blurDepthMaterial.hideFlags = HideFlags.HideAndDontSave;

            m_particles = new ParticleSystem.Particle[m_ps.maxParticles];
            m_positions = new Vector4[m_ps.maxParticles];

            m_velocities = new Vector3[m_ps.maxParticles]; ;

            m_colors = new Color[m_ps.maxParticles]; ;

            m_posBuffer = new ComputeBuffer(m_ps.maxParticles, 16);
            m_colorBuffer = new ComputeBuffer(m_ps.maxParticles, 16);

            m_particlesCount = m_ps.GetParticles(m_particles);

            for (int i = 0; i < m_ps.particleCount; i++)
            {
                m_positions[i] = m_particles[i].position;
                m_positions[i].w = m_particles[i].GetCurrentSize(m_ps);

                m_velocities[i] = m_particles[i].velocity;
                m_colors[i] = m_particles[i].GetCurrentColor(m_ps);
            }

            m_posBuffer.SetData(m_positions);
            m_colorBuffer.SetData(m_colors);

            m_quadVerticesBuffer = new ComputeBuffer(6, 16);
            m_quadVerticesBuffer.SetData(new[]
            {
            new Vector4(-0.5f, 0.5f),
            new Vector4(0.5f, 0.5f),
            new Vector4(0.5f, -0.5f),
            new Vector4(0.5f, -0.5f),
            new Vector4(-0.5f, -0.5f),
            new Vector4(-0.5f, 0.5f),
        });

            //m_depthTexture = new RenderTexture(4096, 4096, 24, RenderTextureFormat.ARGBFloat);
            //m_blurredDepthTexture.format = RenderTextureFormat.ARGBFloat;
            //m_blurredDepthTempTexture.format = RenderTextureFormat.ARGBFloat;
            //m_thicknessTexture.format = RenderTextureFormat.ARGBFloat;


            m_depthMaterial.SetBuffer("buf_Positions", m_posBuffer);
            m_depthMaterial.SetBuffer("buf_Velocities", m_colorBuffer);
            m_depthMaterial.SetBuffer("buf_Vertices", m_quadVerticesBuffer);

            m_thicknessMaterial.SetBuffer("buf_Positions", m_posBuffer);
            m_thicknessMaterial.SetBuffer("buf_Velocities", m_colorBuffer);
            m_thicknessMaterial.SetBuffer("buf_Vertices", m_quadVerticesBuffer);


        }

        // Update is called once per frame
        void Update()
        {

        }

        void OnRenderObject()
        {
            m_particlesCount = m_ps.GetParticles(m_particles);
    
            for (int i = 0; i < m_particlesCount; i++)
            {
                m_positions[i] = m_particles[i].position;
                m_positions[i].w = m_particles[i].GetCurrentSize(m_ps);

                m_velocities[i] = m_particles[i].velocity;
                m_colors[i] = m_particles[i].GetCurrentColor(m_ps);
            }

            //   Debug.Log("OnRENDER: " + Application.isPlaying);
            m_posBuffer.SetData(m_positions);
            m_colorBuffer.SetData(m_colors);

            // m_material.SetPass(0);

            DrawColors();

            DrawDepth();

            if (m_blur)
            {
                BlurDepth();
            }
            else
            {
                Graphics.Blit(m_depthTexture, m_blurredDepthTexture);
            }

            DrawThickness();


            //Graphics.DrawProcedural(MeshTopology.Triangles, sphereVertexCount, body.pointsCount);
            Graphics.SetRenderTarget(Camera.main.targetTexture);
        }

        void DrawColors()
        {
            m_colorMaterial.SetColor("_Color", m_color);
            m_colorMaterial.SetFloat("_PointRadius", m_pointRadius);
            m_colorMaterial.SetFloat("_PointScale", m_pointScale);

            m_colorMaterial.SetBuffer("buf_Positions", m_posBuffer);
            m_colorMaterial.SetBuffer("buf_Colors", m_colorBuffer);
            m_colorMaterial.SetBuffer("buf_Vertices", m_quadVerticesBuffer);

            Graphics.SetRenderTarget(m_colorTexture);
            GL.Clear(true, true, Color.white);

            m_colorMaterial.SetPass(0);

            Graphics.DrawProcedural(MeshTopology.Triangles, 6, m_ps.particleCount);
        }

        void DrawDepth()
        {
            m_depthMaterial.SetFloat("_PointRadius", m_pointRadius);
            m_depthMaterial.SetFloat("_PointScale", m_pointScale);

            m_depthMaterial.SetBuffer("buf_Positions", m_posBuffer);
            m_depthMaterial.SetBuffer("buf_Colors", m_colorBuffer);
            m_depthMaterial.SetBuffer("buf_Vertices", m_quadVerticesBuffer);

            Graphics.SetRenderTarget(m_depthTexture);
            GL.Clear(true, true, Color.white);

            m_depthMaterial.SetPass(0);

            
            Graphics.DrawProcedural(MeshTopology.Triangles, 6, m_ps.particleCount);
        }

        void BlurDepth()
        {
            //  Graphics.SetRenderTarget(m_blurredDepthTexture);
            //  GL.Clear(true, true, Color.white);

            //  Graphics.SetRenderTarget(m_blurredDepthTempTexture);
            //   GL.Clear(true, true, Color.white);


            m_blurDepthMaterial.SetTexture("_DepthTex", m_depthTexture);

            m_blurDepthMaterial.SetInt("radius", m_blurRadius);
            m_blurDepthMaterial.SetFloat("minDepth", m_minDepth);
            m_blurDepthMaterial.SetFloat("blurDepthFalloff", m_blurDepthFalloff);

            m_blurDepthMaterial.SetTexture("_DepthTex", m_depthTexture);
            //   m_blurDepthMaterial.SetFloat("scaleX", 1.0f / Screen.width);
            m_blurDepthMaterial.SetFloat("scaleX", 1.0f / 1024 * m_blurScale);
            m_blurDepthMaterial.SetFloat("scaleY", 0.0f);
            Graphics.Blit(m_depthTexture, m_blurredDepthTempTexture, m_blurDepthMaterial);

            m_blurDepthMaterial.SetTexture("_DepthTex", m_blurredDepthTempTexture);
            m_blurDepthMaterial.SetFloat("scaleX", 0.0f);
            //   m_blurDepthMaterial.SetFloat("scaleY", 1.0f / Screen.height);
            m_blurDepthMaterial.SetFloat("scaleY", 1.0f / 1024 * m_blurScale);
            Graphics.Blit(m_blurredDepthTempTexture, m_blurredDepthTexture, m_blurDepthMaterial);


        }

        void DrawThickness()
        {
            m_thicknessMaterial.SetFloat("_PointRadius", m_pointRadius);
            m_thicknessMaterial.SetFloat("_PointScale", m_pointScale);
            m_thicknessMaterial.SetFloat("_Thickness", m_thickness);
            m_thicknessMaterial.SetFloat("_Softness", m_softness);

            m_thicknessMaterial.SetBuffer("buf_Positions", m_posBuffer);
            m_thicknessMaterial.SetBuffer("buf_Velocities", m_colorBuffer);
            m_thicknessMaterial.SetBuffer("buf_Vertices", m_quadVerticesBuffer);

            Graphics.SetRenderTarget(m_thicknessTexture);
            GL.Clear(true, true, Color.black);

            m_thicknessMaterial.SetPass(0);

            Graphics.DrawProcedural(MeshTopology.Triangles, 6, m_ps.particleCount);
        }

        void OnDisable()
        {
            //   Debug.Log("DISABLED: "+ Application.isPlaying);
            ReleaseBuffers();
        }

        void ReleaseBuffers()
        {
            if (m_posBuffer != null)
                m_posBuffer.Release();

            if (m_colorBuffer != null)
                m_colorBuffer.Release();

            if (m_quadVerticesBuffer != null)
                m_quadVerticesBuffer.Release();
        }

        void OnApplicationQuit()
        {

            //    Debug.Log("QUIT: " + Application.isPlaying);
            ReleaseBuffers();
        }
    }
}