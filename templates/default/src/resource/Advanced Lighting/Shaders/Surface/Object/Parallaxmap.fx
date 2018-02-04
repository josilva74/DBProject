//====================================================
// Parallax Mapping
//====================================================
// By EVOLVED
// www.evolved-software.com
//====================================================

//--------------
// un-tweaks
//--------------
   matrix World:World;
   matrix WorldVP:WorldViewProjection; 
   matrix WorldIT:WorldInverseTranspose;
   matrix WorldV:WorldView; 
   matrix ViewInv:ViewInverse;
   matrix PreviousVP;
   matrix OrthoProj;
 
//--------------
// tweaks
//--------------
   float Heightvec=0.025f;
   float BiasHeight=0.25f;
   float DetailScale=5;
   float DetailBump=0.3f;
   float3 AmbientColor;
   float3 LightColor;
   float3 LightDirection;
   float3 LightPosition;
   float LightRange;
   float3 ShadowPosition;
   float2 ShadowBias;
   float4 FogRange;
   float3 FogColor1;
   float3 FogColor2;
   float3 HeightFog;
   float4 HeightFogColor;
   float ClipHeight;

//--------------
// Textures
//--------------
   texture BaseTexture <string Name="";>;	
   sampler BaseSampler=sampler_state 
      {
 	texture=<BaseTexture>;
  	MagFilter=anisotropic;
	MinFilter=anisotropic;
	MipFilter=anisotropic;
        MaxAnisotropy=3;
      };
   texture NormalTexture <string Name="";>;	
   sampler NormalSampler=sampler_state 
      {
 	texture=<NormalTexture>;
      };
   texture SpecularTexture <string Name="";>;
   sampler SpecularSampler=sampler_state 
      {
	texture=<SpecularTexture>;
      };
   texture DetailTexture <string Name="";>;
   sampler DetailSampler=sampler_state 
      {
 	texture=<DetailTexture>;
      };
   texture SubSurfaceTexture <string Name="";>;
   sampler SubSurfaceSampler=sampler_state 
      {
	texture=<SubSurfaceTexture>;
      };

//--------------
// structs 
//--------------
   struct InPut
     {
 	float4 Pos:POSITION;
 	float2 Tex:TEXCOORD;
	float3 Normal:NORMAL;
     };
   struct OutPut
     {
	float4 Pos:POSITION; 
   	float2 Tex:TEXCOORD0; 
   	float3 Normals:TEXCOORD1;
	float ClipY:TEXCOORD2;
	float4 Fog:COLOR0;
     };
   struct In_Geometry
     {
 	float4 Pos:POSITION;
 	float2 Tex:TEXCOORD;
	float3 Normal:NORMAL;
   	float3 Tangent:TANGENT;
   	float3 Binormal:BINORMAL;
     };
   struct Out_Geometry
     {
	float4 Pos:POSITION; 
   	float2 Tex:TEXCOORD0; 
     	float3 TBNx1:TEXCOORD1;
     	float3 TBNx2:TEXCOORD2;
     	float3 TBNx3:TEXCOORD3;
   	float3 ViewVec:TEXCOORD4;
     };
   struct In_WPosition
     {
 	float4 Pos:POSITION; 
     };
   struct Out_WPosition
     {
 	float4 Pos:POSITION;
 	float4 ViewPos:TEXCOORD0;
    	float4 CurrentPos:TEXCOORD1;
    	float4 PreviousPos:TEXCOORD2;
     };
   struct In_Depth
     {
 	float4 Pos:POSITION; 
     };
   struct Out_Depth
     {
 	float4 Pos:POSITION; 
 	float4 Depth:TEXCOORD0; 
     };

//--------------
// vertex shader
//--------------
   OutPut VS(InPut IN) 
     {
 	OutPut OUT;
	OUT.Pos=mul(IN.Pos,WorldVP);
 	OUT.Tex=IN.Tex;
	OUT.Normals=normalize(mul(IN.Normal,World));
	float3 WPos=mul(IN.Pos,World);
	OUT.ClipY=WPos.y-ClipHeight;
	float3 LightVec=WPos-LightPosition;
	float ViewVecL=length(WPos-ViewInv[3].xyz);
	float4 FogDist=saturate(float4(pow(ViewVecL.xx/FogRange.xy,FogRange.zw),length(LightVec)/(FogRange.x*2),exp(-((WPos.y-HeightFog.x)/HeightFog.y)*HeightFog.z)*HeightFogColor.w));
	OUT.Fog=float4(lerp(HeightFogColor.xyz,lerp(FogColor2,FogColor1,FogDist.z),FogDist.x),saturate((FogDist.w*FogDist.y)+FogDist.x));
	return OUT;
     }
   Out_Geometry VS_Geometry(In_Geometry IN) 
     {
 	Out_Geometry OUT;
	OUT.Pos=mul(IN.Pos,WorldVP);
 	OUT.Tex=IN.Tex;
	float3x3 TBN={IN.Tangent,IN.Binormal,IN.Normal};
	float3x3 wTBN=mul(TBN,WorldIT);
	OUT.TBNx1=normalize(wTBN[0]);
	OUT.TBNx2=normalize(wTBN[1]);
	OUT.TBNx3=normalize(wTBN[2]);
  	OUT.ViewVec=mul(ViewInv[3].xyz-mul(IN.Pos,World),transpose(mul(TBN,World)));
	return OUT;
     }
   Out_WPosition VS_WPosition(In_WPosition IN) 
     {
 	Out_WPosition OUT;
	OUT.Pos=mul(IN.Pos,WorldVP);
	OUT.ViewPos=float4(mul(IN.Pos,WorldV).xyz,OUT.Pos.z);
 	OUT.CurrentPos=OUT.Pos;
	OUT.PreviousPos=mul(mul(IN.Pos,World),PreviousVP);
	return OUT;
     }
   Out_Depth VS_DepthMap(In_Depth IN)
     {
        Out_Depth OUT;
	OUT.Pos=mul(IN.Pos,WorldVP);
	OUT.Depth=float4(ShadowPosition-mul(IN.Pos,World),0);
        return OUT;
     }
   Out_Depth VS_DepthMapDirectional(In_Depth IN)
     {
        Out_Depth OUT;
	OUT.Pos=mul(mul(IN.Pos,World),OrthoProj);
	OUT.Depth=float4(mul(IN.Pos,World)-ShadowPosition,0);
        return OUT;
     }

//--------------
// pixel shader
//--------------
   float4 PS(OutPut IN) : COLOR
     {
	clip(IN.ClipY);
   	float3 Diffuse=tex2D(BaseSampler,IN.Tex);
	return float4(lerp(Diffuse*(saturate(dot(-LightDirection,IN.Normals)*LightColor)+AmbientColor),IN.Fog,IN.Fog.w),1);
     }
   float4 PackColor(in float4 iColor1,in float4 iColor2,in float4 iColor3)
     {
	iColor1=floor(iColor1*254);
	iColor2=floor(iColor2*254);
	iColor3=floor(iColor3*254);
	return float4((iColor1.x*65025)+(iColor2.x*255)+iColor3.x,
	 	      (iColor1.y*65025)+(iColor2.y*255)+iColor3.y,
		      (iColor1.z*65025)+(iColor2.z*255)+iColor3.z,
		      (iColor1.w*65025)+(iColor2.w*255)+iColor3.w);
     }
   float4 PS_Geometry(Out_Geometry IN) : COLOR
     {
	float3 ViewV=normalize(IN.ViewVec);
 	float HeightTex=tex2D(NormalSampler,IN.Tex).w+BiasHeight;
   	float2 NewTex=(Heightvec*HeightTex-Heightvec)*ViewV+IN.Tex;
   	float3 Diffuse=tex2D(BaseSampler,NewTex);
	float3 Normalmap=tex2D(NormalSampler,NewTex)*2-1;
	float3 Normals=saturate(0.5f+mul(Normalmap,float3x3(IN.TBNx1,IN.TBNx2,IN.TBNx3))*0.5f);
 	float3 Specular=tex2D(SpecularSampler,NewTex);
	return PackColor(float4(Diffuse,Specular.y),float4(Normals,Specular.x),tex2D(SubSurfaceSampler,IN.Tex));
     }
   float4 PS_GeometryDetail(Out_Geometry IN) : COLOR
     {
	float3 ViewV=normalize(IN.ViewVec);
 	float HeightTex=tex2D(NormalSampler,IN.Tex).w+BiasHeight;
   	float2 NewTex=(Heightvec*HeightTex-Heightvec)*ViewV+IN.Tex;
	float4 Detail=tex2D(DetailSampler,NewTex*DetailScale);
   	float3 Diffuse=saturate((tex2D(BaseSampler,NewTex)+Detail.www)-0.5f);
	float3 Normalmap=(tex2D(NormalSampler,NewTex)*2-1)+((Detail.xyz*2-1)*DetailBump);
	float3 Normals=saturate(0.5f+mul(Normalmap,float3x3(IN.TBNx1,IN.TBNx2,IN.TBNx3))*0.5f);
 	float3 Specular=tex2D(SpecularSampler,NewTex);
	return PackColor(float4(Diffuse,Specular.y),float4(Normals,Specular.x),tex2D(SubSurfaceSampler,IN.Tex));
     }
   float4 PS_WPosition(Out_WPosition IN) : COLOR
     {
	float2 Velocity=(IN.CurrentPos/IN.CurrentPos.w)-(IN.PreviousPos/IN.PreviousPos.w);
	return float4(length(IN.ViewPos.xyz),IN.ViewPos.w,Velocity);
     }
   float4 PS_DepthMapVsm(Out_Depth IN) : COLOR
     {
	float Depth=saturate(length(IN.Depth.xyz/LightRange));
        return float4(Depth,Depth*Depth,0,0);
     }
   float4 PS_DepthMapEvsm(Out_Depth IN) : COLOR
     {
	float Depth=saturate(length(IN.Depth.xyz/LightRange));
	float2 DepthPN=float2(Depth+ShadowBias.x,1-Depth+ShadowBias.y);
	float2 DepthExp=exp(DepthPN*7-3.5f);
        return float4(DepthExp.x,DepthExp.y,DepthExp.x*DepthExp.x,DepthExp.y*DepthExp.y);
     }
   float4 PS_DepthMapDirectionalVsm(Out_Depth IN) : COLOR
     {
	float Depth=saturate(dot(IN.Depth.xyz,LightDirection)/LightRange)+ShadowBias.x;
        return float4(Depth,Depth*Depth,0,0);
     }
   float4 PS_DepthMapDirectionalVsmBa(Out_Depth IN) : COLOR
     {
	float Depth=saturate(dot(IN.Depth.xyz,LightDirection)/LightRange)+ShadowBias.x;
        return float4(0,0,Depth,Depth*Depth);
     }
   float4 PS_DepthMapDirectionalEvsm(Out_Depth IN) : COLOR
     {
	float Depth=saturate(dot(IN.Depth.xyz,LightDirection)/LightRange);
	float2 DepthPN=float2(Depth+ShadowBias.x,1-Depth+ShadowBias.y);
	float2 DepthExp=exp(DepthPN*7-3.5f);
        return float4(DepthExp.x,DepthExp.y,DepthExp.x*DepthExp.x,DepthExp.y*DepthExp.y);
     }

//--------------
// techniques   
//--------------
   technique Diffuse
      {
 	pass p1
      {		
 	vertexShader = compile vs_3_0 VS(); 
 	pixelShader  = compile ps_3_0 PS(); 
      }
      }
   technique Geometry
      {
 	pass p1
      {		
 	vertexShader = compile vs_3_0 VS_Geometry(); 
 	pixelShader  = compile ps_3_0 PS_Geometry(); 
      }
      }
   technique GeometryDetail
      {
 	pass p1
      {		
 	vertexShader = compile vs_3_0 VS_Geometry(); 
 	pixelShader  = compile ps_3_0 PS_GeometryDetail(); 
      }
      }
   technique WPosition
      {
 	pass p1
      {		
 	vertexShader = compile vs_3_0 VS_WPosition(); 
 	pixelShader  = compile ps_3_0 PS_WPosition(); 
      }
      }
    technique DepthMapVsm
      {
 	pass p1
      {		
 	VertexShader = compile vs_3_0 VS_DepthMap(); 
 	PixelShader  = compile ps_3_0 PS_DepthMapVsm(); 
      }
      }
    technique DepthMapEvsm
      {
 	pass p1
      {		
 	VertexShader = compile vs_3_0 VS_DepthMap(); 
 	PixelShader  = compile ps_3_0 PS_DepthMapEvsm(); 
      }
      }
    technique DepthMapDirectionalVsm
      {
 	pass p1
      {		
 	VertexShader = compile vs_3_0 VS_DepthMapDirectional(); 
 	PixelShader  = compile ps_3_0 PS_DepthMapDirectionalVsm();
        ColorWriteEnable=3;
      }
      }
    technique DepthMapDirectionalVsmBa
      {
 	pass p1
      {		
 	VertexShader = compile vs_3_0 VS_DepthMapDirectional(); 
 	PixelShader  = compile ps_3_0 PS_DepthMapDirectionalVsmBa();
        ColorWriteEnable=12;
      }
      }
    technique DepthMapDirectionalEvsm
      {
 	pass p1
      {		
 	VertexShader = compile vs_3_0 VS_DepthMapDirectional(); 
 	PixelShader  = compile ps_3_0 PS_DepthMapDirectionalEvsm(); 
      }
      }