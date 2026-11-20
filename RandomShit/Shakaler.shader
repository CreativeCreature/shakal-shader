Shader "Custom/Shakaler"
{
    Properties
    {
        // Исходная картинка. RawImage подставляет сюда свою Texture автоматически.
        [PerRendererData] _MainTex ("Texture", 2D) = "white" {}

        // Количество уровней яркости. Меньше значение, грубее постеризация.
        // Для цветности уровней вдвое меньше (но не меньше 2).
        _Levels ("Color levels", Float) = 10
    }

    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" "IgnoreProjector"="True" }

        Cull Off      // рисовать обе стороны полигона
        ZWrite Off    // не писать в буфер глубины (это UI)
        ZTest Always  // рисовать поверх всего
        Blend SrcAlpha OneMinusSrcAlpha // обычная прозрачность

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float _Levels;

            struct v2f { float4 pos : SV_POSITION; float2 uv : TEXCOORD0; };

            // Вершинный шейдер: переводит вершину в координаты экрана и передаёт UV.
            v2f vert (appdata_base v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                return o;
            }

            // RGB -> YCbCr: Y — яркость, Cb и Cr — цветность.
            float3 ToYCC(float3 c)
            {
                float y = dot(c, float3(0.299, 0.587, 0.114));
                return float3(y, (c.b - y) * 0.564, (c.r - y) * 0.713);
            }

            // YCbCr -> RGB.
            float3 FromYCC(float3 t)
            {
                float r = t.x + 1.403 * t.z;
                float b = t.x + 1.773 * t.y;
                float g = (t.x - 0.299 * r - 0.114 * b) / 0.587;
                return float3(r, g, b);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // Берём цвет пикселя напрямую. Пикселизация уже есть из-за малого
                // размера RenderTexture, поэтому свои координаты считать не нужно.
                float4 pix = tex2D(_MainTex, i.uv);

                // Переводим в YCbCr: отдельно яркость и цветность.
                float3 ycc = ToYCC(pix.rgb);

                // Квантизация: округляем значения до ограниченного числа уровней.
                // Яркость получает _Levels уровней, цветность вдвое меньше,
                // поэтому цвет портится сильнее, как в настоящем JPEG.
                float ql = _Levels;
                float qc = max(2, _Levels * 0.5);
                ycc.x = floor(ycc.x * ql + 0.5) / ql;
                ycc.yz = floor(ycc.yz * qc + 0.5) / qc;

                // Возвращаем RGB. Альфа берётся от исходного пикселя,
                // чтобы прозрачный фон второй камеры остался прозрачным.
                float3 rgb = saturate(FromYCC(ycc));
                return fixed4(rgb, pix.a);
            }
            ENDCG
        }
    }
}
