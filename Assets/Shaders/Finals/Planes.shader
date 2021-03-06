﻿Shader "Final/Planes" {
  Properties {

    _Color ("Color", Color) = (1,1,1,1)

    _MainTex ("Texture", 2D) = "white" {}

    _ColorMap ("ColorMap", 2D) = "white" {}
    _NormalMap ("NormalMap", 2D) = "white" {}
    _CubeMap( "Cube Map" , Cube )  = "defaulttexture" {}
    
    [Toggle(Enable12Struct)] _Struct12("12 Struct", Float) = 0
  }

  SubShader {
    // COLOR PASS

    Pass {
      Tags{ "LightMode" = "ForwardBase" }
      Cull Off

      CGPROGRAM
      #pragma target 4.5
      #pragma vertex vert
      #pragma fragment frag
      #pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight

      #include "UnityCG.cginc"
      #include "AutoLight.cginc"
    
    struct Vert{
      float3 pos;
      float3 nor;
      float3 tan;
      float2 uv;
      float debug;
    };

      #include "../Chunks/hsv.cginc"
      #include "../Chunks/noise.cginc"

      float3 _Color;
      float3 _Player;
      sampler2D _MainTex;
      sampler2D _ColorMap;
      sampler2D _NormalMap;
      samplerCUBE _CubeMap;


  StructuredBuffer<Vert> _TransferBuffer;



      sampler2D _HeightMap;
    float _MapSize;
    float _MapHeight;



  float4 sampleColor( float3 pos ){
        return tex2Dlod(_HeightMap , float4(pos.xz * _MapSize,0,0) );
    }

      struct varyings {
        float4 pos    : SV_POSITION;
        float3 nor    : TEXCOORD0;
        float2 uv     : TEXCOORD1;
        float3 eye      : TEXCOORD5;
        float3 worldPos : TEXCOORD6;
        float3 debug    : TEXCOORD7;
        float3 closest    : TEXCOORD8;
        UNITY_SHADOW_COORDS(2)
      };

      varyings vert(uint id : SV_VertexID) {

        float3 fPos   = _TransferBuffer[id].pos;
        float3 fNor   = _TransferBuffer[id].nor;
        float2 fUV    = _TransferBuffer[id].uv;
        float2 debug  = _TransferBuffer[id].debug;

        varyings o;

        UNITY_INITIALIZE_OUTPUT(varyings, o);

        fPos -= float3(0,1,0) * .3  * (1-saturate(.3*length( fPos - _Player)));

        o.worldPos = fPos;



        o.pos = mul(UNITY_MATRIX_VP, float4(fPos,1));
        o.eye = _WorldSpaceCameraPos - fPos;
        o.nor = fNor;
        o.uv =  float2(.9,1)-fUV;
        o.debug = float3(debug.x,debug.y,0);

        UNITY_TRANSFER_SHADOW(o,o.worldPos);

        return o;
      }

      float4 frag(varyings v) : COLOR {

        float4 color = tex2D(_MainTex,v.worldPos.xz * .1 );
        float4 hCol = sampleColor(v.worldPos );

        float3 fNor = normalize(float3(
            2*noise(v.worldPos* 2 )-1,
            2*noise(v.worldPos* 2 +50)-1,
            2*noise(v.worldPos* 2 +20 )-1
        ));

        fNor += 2*normalize(float3(
            2*noise(v.worldPos* .4 )-1,
            2*noise(v.worldPos* .4 +50)-1,
            2*noise(v.worldPos* .4 +20 )-1
        ));

        fNor += .4 * normalize(float3(
            2*noise(v.worldPos* 10 )-1,
            2*noise(v.worldPos* 10 +50)-1,
            2*noise(v.worldPos* 10 +20 )-1
        ));

        fNor = tex2D(_NormalMap , v.worldPos.xz * .1 );
       // fNor += 2*v.nor;
        

        fNor = normalize(v.nor * fNor.z + float3(1,0,0) * (fNor.x)  + float3(0,0,1) * (fNor.y-.5));//normalize( fNor );

        float3 glint = tex2D(_NormalMap , v.worldPos.xz * .04 ) + tex2D(_NormalMap , v.worldPos.xz * .14 );

        glint = normalize((glint)-1);

        float eyeM = abs(dot(fNor, normalize(v.eye)));
    
        fixed shadow = UNITY_SHADOW_ATTENUATION(v,v.worldPos) * .9 + .1 ;
float dif = length( v.worldPos - _Player );

float l = saturate( (20-dif)/20);
        color.xyz = .4*pow(length(color.xyz),4);

        float match = dot( fNor, _WorldSpaceLightPos0 );

        float3 refl = reflect( normalize(v.eye) , fNor );
        float reflM = dot( refl , _WorldSpaceLightPos0 );


        float grassHeight = (hCol.w * 5 + noise( v.worldPos + float3(0,_Time.y * .2,0) + fNor * _Time.y * .01 ) * .4) / 5;
        color.xyz = tex2D(_ColorMap, float2(  l*.1 + .27 -  floor(grassHeight * 3)*.1  , 0)) * l;



        float3 tCol = texCUBE(_CubeMap,refl) * color;


        tCol *=color;// pow(eyeM,100)  * 20;

        //tCol = grassHeight;
        return float4( tCol *shadow , 1.);
      }

      ENDCG
    }


   // SHADOW PASS

    Pass
    {
      Tags{ "LightMode" = "ShadowCaster" }


      Fog{ Mode Off }
      ZWrite On
      ZTest LEqual
      Cull Off
      Offset 1, 1
      CGPROGRAM

      #pragma target 4.5
      #pragma vertex vert
      #pragma fragment frag
      #pragma multi_compile_shadowcaster
      #pragma fragmentoption ARB_precision_hint_fastest
      #include "UnityCG.cginc"
      
#pragma multi_compile  Enable12Struct Enable16Struct Enable24Struct Enable36Struct

      #include "../Chunks/StructIfDefs.cginc"

      struct v2f {
        V2F_SHADOW_CASTER;
      };


      v2f vert(appdata_base v, uint id : SV_VertexID)
      {
        v2f o;
        o.pos = mul(UNITY_MATRIX_VP, float4(_TransferBuffer[id].pos, 1));
        return o;
      }

      float4 frag(v2f i) : COLOR
      {
        SHADOW_CASTER_FRAGMENT(i)
      }
      ENDCG
    }
  


  }

}
