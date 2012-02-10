/*
  Part of the Processing project - http://processing.org

  Copyright (c) 2011 Andres Colubri

  This library is free software; you can redistribute it and/or
  modify it under the terms of the GNU Lesser General Public
  License as published by the Free Software Foundation; either
  version 2.1 of the License, or (at your option) any later version.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General
  Public License along with this library; if not, write to the
  Free Software Foundation, Inc., 59 Temple Place, Suite 330,
  Boston, MA  02111-1307  USA
*/

uniform mat4 modelviewMatrix;
uniform mat4 projmodelviewMatrix;
uniform mat3 normalMatrix;

uniform int lightCount;
uniform vec4 lightPosition[8];
uniform vec3 lightNormal[8];
uniform vec4 lightAmbient[8];
uniform vec4 lightDiffuse[8];
uniform vec4 lightSpecular[8];      
uniform float lightFalloffConstant[8];
uniform float lightFalloffLinear[8];
uniform float lightFalloffQuadratic[8];      
uniform float lightSpotAngleCos[8];
uniform float lightSpotConcentration[8]; 

attribute vec4 inVertex;
attribute vec4 inColor;
attribute vec3 inNormal;

attribute vec4 inAmbient;
attribute vec4 inSpecular;
attribute vec4 inEmissive;
attribute float inShine;

varying vec4 vertColor;

float attenuationFactor(vec3 lightPos, vec3 vertPos, float c0, float c1, float c2) {
  float d = distance(lightPos, vertPos);
  return 1.0 / (c0 + c1 * d + c2 * d * d);
}

float spotFactor(vec3 lightPos, vec3 vertPos, vec3 lightNorm, float minCos, float spotExp) {
  float spotCos = dot(-lightNorm, lightPos - vertPos);
  return spotCos <= minCos ? 0.0 : pow(spotCos, spotExp); 
}

float lambertFactor(vec3 lightDir, vec3 vecNormal) {
  return max(0.0, dot(lightDir, vecNormal));
}

float blinnPhongFactor(vec3 lightDir, vec3 lightPos, vec3 vecNormal, float shine) {
  return pow(max(0.0, dot(lightDir - lightPos, vecNormal)), shine);
}

void main() {
  gl_Position = projmodelviewMatrix * inVertex;
    
  // Vertex in eye coordinates
  vec3 ecVertex = vec3(modelviewMatrix * inVertex);
  
  // Normal vector in eye coordinates
  //vec3 ecNormal = normalize(normalMatrix * inNormal);
  
  mat3 mat = mat3(1, 0, 0, 0, 1, 0, 0, 0, 1);
  vec3 ecNormal = normalize(mat * inNormal);
  
  // Light calculations
  vec3 totalAmbient = vec3(0, 0, 0);
  vec3 totalDiffuse = vec3(0, 0, 0);
  vec3 totalSpecular = vec3(0, 0, 0);
  for (int i = 0; i < lightCount; i++) {
    vec3 lightPos3 = lightPosition[i].xyz;
    bool isDir = 0.0 < lightPosition[i].w;
    float exp = lightSpotConcentration[i];
    float mcos = lightSpotAngleCos[i];
    
    vec3 lightDir;
    float falloff;    
    float spot;
      
    if (isDir) {
      falloff = attenuationFactor(lightPos3, ecVertex, lightFalloffConstant[i], 
                                                       lightFalloffLinear[i],
                                                       lightFalloffQuadratic[i]);
      lightDir = -lightNormal[i];      
    } else {
      falloff = 1.0;
      lightDir = lightPos3 - ecVertex;
    }
  
    //falloff = 1.0;
    //spot = exp > 0.0 ? spotFactor(lightPos3, ecVertex, lightNormal[i], mcos, exp) : 1.0;
    spot = 1.0;
    
    //totalAmbient  += lightAmbient[i].rgb  * falloff;
    totalDiffuse  += lightDiffuse[i].rgb  * falloff * spot * lambertFactor(-lightDir, ecNormal);
    //totalSpecular += lightSpecular[i].rgb * falloff * spot * blinnPhongFactor(lightDir, lightPos3, ecNormal, inShine);
    
    //totalDiffuse = ecNormal;
    
    //totalDiffuse = vec3(1, 1, 1) * lambertFactor(-lightDir, ecNormal);
           
  }    
  //vertColor = vec4(totalAmbient, 1) * inAmbient + totalDiffuse * inColor + totalSpecular * inSpecular + inEmissive;
  vertColor = vec4(totalDiffuse, 1) * inColor;
  //vertColor = inColor; 
}