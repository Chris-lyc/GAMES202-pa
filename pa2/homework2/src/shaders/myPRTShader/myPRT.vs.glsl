attribute vec3 aVertexPosition;
attribute vec3 aNormalPosition;

uniform mat4 uModelMatrix;
uniform mat4 uViewMatrix;
uniform mat4 uProjectionMatrix;

attribute mat3 aPrecomputeLT;
uniform mat3 uPrecomputeLR;
uniform mat3 uPrecomputeLG;
uniform mat3 uPrecomputeLB;
varying vec3 vcolor;

void main() {

    gl_Position = uProjectionMatrix * uViewMatrix * uModelMatrix * vec4(aVertexPosition, 1.0);
    
    // 光照的 SH 系数为 3 * 9 个（RGB 编码--3  前三阶SH--9），漫反射系数为 （模型顶点数 * 9） 个，所以重构光照，我们需要在每个通道上对系数进行点乘
    vcolor=vec3(uPrecomputeLR[0][0],uPrecomputeLG[0][0] ,uPrecomputeLB[0][0] )*aPrecomputeLT[0][0]
          +vec3(uPrecomputeLR[0][1],uPrecomputeLG[0][1] ,uPrecomputeLB[0][1] )*aPrecomputeLT[0][1]
          +vec3(uPrecomputeLR[0][2],uPrecomputeLG[0][2] ,uPrecomputeLB[0][2] )*aPrecomputeLT[0][2]
          +vec3(uPrecomputeLR[1][0],uPrecomputeLG[1][0] ,uPrecomputeLB[1][0] )*aPrecomputeLT[1][0]
          +vec3(uPrecomputeLR[1][1],uPrecomputeLG[1][1] ,uPrecomputeLB[1][1] )*aPrecomputeLT[1][1]
          +vec3(uPrecomputeLR[1][2],uPrecomputeLG[1][2] ,uPrecomputeLB[1][2] )*aPrecomputeLT[1][2]
          +vec3(uPrecomputeLR[2][0],uPrecomputeLG[2][0] ,uPrecomputeLB[2][0] )*aPrecomputeLT[2][0]
          +vec3(uPrecomputeLR[2][1],uPrecomputeLG[2][1] ,uPrecomputeLB[2][1] )*aPrecomputeLT[2][1]
          +vec3(uPrecomputeLR[2][2],uPrecomputeLG[2][2] ,uPrecomputeLB[2][2] )*aPrecomputeLT[2][2];

}