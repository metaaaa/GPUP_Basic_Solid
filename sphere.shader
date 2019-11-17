// Copyright (c) 2019 @Feyris77
// Released under the MIT license
// https://opensource.org/licenses/mit-license.php
Shader "Unlit/GPUP/Sphere"
{
    Properties
    {
        [IntRange]_Tessellation ("Particle Amount", Range(1, 32)) = 8
        _Size("Particle Size", float) = 0.1
        _Volume("Volume",float)=1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue" = "Transparent-1"}
        LOD 100
        Blend One One
        ZWrite off

        Pass
        {
            CGPROGRAM
            #pragma target 5.0
            #pragma vertex vert
            #pragma hull Hull
            #pragma domain Domain
            #pragma geometry geom
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct v2h {
                float4 pos : SV_POSITION;
                float2 uv  : TEXCOORD0;
            };

            struct h2d
            {
                float4 pos : SV_POSITION;
                float2 uv  : TEXCOORD0;
            };

            struct h2dc
            {
                float Edges[3] : SV_TessFactor;
                float Inside   : SV_InsideTessFactor;
            };

            struct d2g
            {
                float4 pos : SV_POSITION;
                float2 uv  : TEXCOORD0;
            };

            struct g2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 col : TEXCOORD1;
            };


            uniform float _Tessellation, _Size,_Volume;

            #define ADD_VERT(u, v) \
                o.uv = float2(u, v); \
                o.pos = vp + float4(u*ar, v, 0, 0)*_Size; \
                TriStream.Append(o);

            float2 rot(float2 p, float r)
            {
                float c = cos(r);
                float s = sin(r);
                return mul(p, float2x2(c, -s, s, c));
            }

            float3 rand3D(float3 p)
            {
                p = float3( dot(p,float3(127.1, 311.7, 74.7)),
                            dot(p,float3(269.5, 183.3,246.1)),
                            dot(p,float3(113.5,271.9,124.6)));
                return frac(sin(p)*43758.5453123);
            }

            v2h vert (appdata_base  v)
            {
                v2h o;
                o.pos = v.vertex;
                o.uv = v.texcoord;
                return o;
            }

            h2dc HullConst(InputPatch<v2h, 3> i)
            {
                h2dc o;
                float3 retf;
                float  ritf, uitf;
                ProcessTriTessFactorsAvg(_Tessellation.xxx, 1, retf, ritf, uitf );
                o.Edges[0] = retf.x;
                o.Edges[1] = retf.y;
                o.Edges[2] = retf.z;
                o.Inside = ritf;
                return o;
            }

            [domain("tri")]
            [partitioning("integer")]
            [outputtopology("triangle_cw")]
            [outputcontrolpoints(3)]
            [patchconstantfunc("HullConst")]
            h2d Hull(InputPatch<v2h, 3> IN, uint id : SV_OutputControlPointID)
            {
                h2d o;
                o.pos = IN[id].pos;
                o.uv  = IN[id].uv;
                return o;
            }

            [domain("tri")]
            d2g Domain(h2dc hs_const_data,  OutputPatch<h2d, 3> i, float3 bary: SV_DomainLocation)
            {
                d2g o;
                o.pos = i[0].pos * bary.x + i[1].pos * bary.y + i[2].pos * bary.z;
                o.uv  = i[0].uv  * bary.x + i[1].uv  * bary.y + i[2].uv  * bary.z;
                return o;
            }

            [maxvertexcount(3)]
            void geom(point d2g IN[1],inout TriangleStream<g2f> TriStream)
            {
                g2f o;
                float PI = acos(-1);
                float3 pos = rand3D(IN[0].pos.xyz)*2-1;
                float3 rand0 = rand3D(pos.yxz)*2-1;//-1~1
                float3 rand1 = rand3D(pos.zyx)*2-1;
                float3 rand2 = rand3D(pos.xyz)-0.5;//-0.5~0.5
                float3 rand3 = rand3D(pos.xyz);//0~1


                //以下3行"球"
                pos.y =_Volume *rand0;
                pos.x =_Volume * sqrt(1-rand0*rand0) * cos(rand1*PI);
                pos.z =_Volume * sqrt(1-rand0*rand0) * sin(rand1*PI);

                o.col =float4((sin(abs(pos)*10) * 0.57 + 0.6)*.001, 1);

                float ar = - UNITY_MATRIX_P[0][0] / UNITY_MATRIX_P[1][1]; //Aspect Ratio
                float4 vp = UnityObjectToClipPos(float4(pos, 1));
                ADD_VERT( 0.0,  1.0);
                ADD_VERT(-0.9, -0.5);
                ADD_VERT( 0.9, -0.5);
                TriStream.RestartStrip();
            }

            float4 frag (g2f i) : SV_Target
            {
                return saturate(.5-length(i.uv)) * clamp(i.col / pow(length(i.uv), 2), 0, 2);
            }
            ENDCG
        }
    }
}
//Distribution Source : https://voxelgummi.booth.pm/
//Copyright (c) 2019 @Feyris77
//Released under the MIT license
//https://opensource.org/licenses/mit-license.php

//Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

//The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

//以下に定める条件に従い、本ソフトウェアおよび関連文書のファイル（以下「ソフトウェア」）の複製を取得するすべての人に対し、ソフトウェアを無制限に扱うことを無償で許可します。これには、ソフトウェアの複製を使用、複写、変更、結合、掲載、頒布、サブライセンス、および/または販売する権利、およびソフトウェアを提供する相手に同じことを許可する権利も無制限に含まれます。

//上記の著作権表示および本許諾表示を、ソフトウェアのすべての複製または重要な部分に記載するものとします。

//ソフトウェアは「現状のまま」で、明示であるか暗黙であるかを問わず、何らの保証もなく提供されます。ここでいう保証とは、商品性、特定の目的への適合性、および権利非侵害についての保証も含みますが、それに限定されるものではありません。 作者または著作権者は、契約行為、不法行為、またはそれ以外であろうと、ソフトウェアに起因または関連し、あるいはソフトウェアの使用またはその他の扱いによって生じる一切の請求、損害、その他の義務について何らの責任も負わないものとします。