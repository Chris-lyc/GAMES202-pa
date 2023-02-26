//Phong 模型顶点着色器

//attribute: 顶点着色器传入参数。在 loadObj 中从模型文件加载，并保存到 Mesh 的成员变量中。
//在 MeshRender 构造函数中进行绑定，在 MeshRender::draw() -> bindGeometryInfo() 中启用并传给着色器。
//aVertexPosition， aNormalPosition， aTextureCoord 分别表示当前 Vertex 的模型空间坐标，法线，纹理坐标。
attribute vec3 aVertexPosition;
attribute vec3 aNormalPosition;
attribute vec2 aTextureCoord;

//uniform: 着色器全局变量。注意全局变量是 Vertex Shader 和 Fragment Shader 共用的，所以在绑定的时候会一起绑定。
//Material.#flat_uniforms 保存了所有相关的 uniform 名称，
//在 compile() 方法中构造 Shader 对象时，在 Shader 的构造函数中调用了 addShaderLocation() 获取了 gl 中对应变量的 uniform 地址。
//uModelMatrix，uViewMatrix，uProjectionMatrix 分别表示当前摄像机的 M、V、P 矩阵
//uLightMVP 表示从光源方向的 MVP 矩阵
uniform mat4 uModelMatrix;
uniform mat4 uViewMatrix;
uniform mat4 uProjectionMatrix;
uniform mat4 uLightMVP;

//varying: Vertex Shader 输出给 Fragment Shader 的参数。可以看到两个Shader 之间是对应的。
//vFragPos、vNormal 表示经过模型变换后的坐标和法线，注意 varying变量会被自动插值。
//vTextureCoord 表示纹理坐标
//vPositionFromLight 表示经过 uLightMVP 变换后的坐标。
varying highp vec2 vTextureCoord;
varying highp vec3 vFragPos;
varying highp vec3 vNormal;
varying highp vec4 vPositionFromLight;

void main(void) {

  //gl_Position 表示传入 Fragment Shader 的经过 MVP 变换的坐标。如果使用相机的MVP矩阵对 aVertexPosition 进行变换，则表示绘制以摄像机视角为基础的图像；
  //如果使用 uLightMVP aVertexPosition 进行变换，则表示绘制以光源视角为基础的图像。这也是开发中进行调试的一种方法。
  
  // gl_Position = vPositionFromLight

  vFragPos = (uModelMatrix * vec4(aVertexPosition, 1.0)).xyz;
  vNormal = (uModelMatrix * vec4(aNormalPosition, 0.0)).xyz;

  gl_Position = uProjectionMatrix * uViewMatrix * uModelMatrix *
                vec4(aVertexPosition, 1.0);

  vTextureCoord = aTextureCoord;
  vPositionFromLight = uLightMVP * vec4(aVertexPosition, 1.0);
}