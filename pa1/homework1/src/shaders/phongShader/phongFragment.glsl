//Phong 模型片段着色器。
#ifdef GL_ES
precision mediump float;
#endif

//uniform 的机制与 phongVertex 一致，只是具体使用到的参数有所不同。
// Phong related variables
uniform sampler2D uSampler;//sampler2D:2D纹理 a 2D texture;   samplerCube:盒纹理 cube mapped texture
uniform vec3 uKd;
uniform vec3 uKs;
uniform vec3 uLightPos;
uniform vec3 uCameraPos;
uniform vec3 uLightIntensity;

//因为不会直接从代码调用 Fragment Shader，所以这里没有 attribute 参数。

//varying 表示的含义为从 Vertex Shader 中计算并差值后传入到 Fragment Shader 的参数。
varying highp vec2 vTextureCoord;
varying highp vec3 vFragPos;
varying highp vec3 vNormal;

// Shadow map related variables
#define NUM_SAMPLES 20 //要调参 太糊了就增加采样率；要是阴影透光就说明filter的尺度太大
#define BLOCKER_SEARCH_NUM_SAMPLES NUM_SAMPLES
#define PCF_NUM_SAMPLES NUM_SAMPLES
#define NUM_RINGS 10

#define EPS 1e-3
#define PI 3.141592653589793
#define PI2 6.283185307179586

uniform sampler2D uShadowMap;

varying vec4 vPositionFromLight;

//从一维随机变量 x 产生一个 [-1,1] 范围内的随机变量
highp float rand_1to1(highp float x ) { 
  // -1 -1
  return fract(sin(x)*10000.0);
}

//从二维随机变量 uv 产生一个 [0,1] 范围的随机变量
highp float rand_2to1(vec2 uv ) { 
  // 0 - 1
	const highp float a = 12.9898, b = 78.233, c = 43758.5453;
	highp float dt = dot( uv.xy, vec2( a,b ) ), sn = mod( dt, PI );
	return fract(sin(sn) * c);
}

//shadowFragment 中 pack() 的反函数，用于解码纹理 rgba 到[0,1]浮点数即深度
float unpack(vec4 rgbaDepth) {
    const vec4 bitShift = vec4(1.0, 1.0/256.0, 1.0/(256.0*256.0), 1.0/(256.0*256.0*256.0));
    return dot(rgbaDepth, bitShift);
}

vec2 poissonDisk[NUM_SAMPLES];

//产生特定随机分布的函数
void poissonDiskSamples( const in vec2 randomSeed ) {

  float ANGLE_STEP = PI2 * float( NUM_RINGS ) / float( NUM_SAMPLES );
  float INV_NUM_SAMPLES = 1.0 / float( NUM_SAMPLES );

  float angle = rand_2to1( randomSeed ) * PI2;
  float radius = INV_NUM_SAMPLES;
  float radiusStep = radius;

  for( int i = 0; i < NUM_SAMPLES; i ++ ) {
    poissonDisk[i] = vec2( cos( angle ), sin( angle ) ) * pow( radius, 0.75 );
    radius += radiusStep;
    angle += ANGLE_STEP;
  }
}

//产生特定随机分布的函数
void uniformDiskSamples( const in vec2 randomSeed ) {

  float randNum = rand_2to1(randomSeed);
  float sampleX = rand_1to1( randNum ) ;
  float sampleY = rand_1to1( sampleX ) ;

  float angle = sampleX * PI2;
  float radius = sqrt(sampleY);

  for( int i = 0; i < NUM_SAMPLES; i ++ ) {
    poissonDisk[i] = vec2( radius * cos(angle) , radius * sin(angle)  );

    sampleX = rand_1to1( sampleY ) ;
    sampleY = rand_1to1( sampleX ) ;

    angle = sampleX * PI2;
    radius = sqrt(sampleY);
  }
}

float findBlocker( sampler2D shadowMap,  vec2 uv, float zReceiver ) {
  float texturesize=2048.0;
  float filtersize=20.0;
  float filterstride=1.0;
  float filterrange=filterstride/texturesize*filtersize;//???不知道怎么来的

  float res=0.0;
  float sum=0.0;
  int divider=0;

  poissonDiskSamples(uv);
  for(int i=0;i<NUM_SAMPLES;i++)
  {
    float light_depth=unpack(texture2D(shadowMap,uv+filterrange*poissonDisk[i]));
    if(light_depth+EPS<zReceiver)
    {
      sum+=light_depth;
      divider++;
    }  
  }
  //特判别忘了!
  if(divider==0)return 1.0;
  if(divider==NUM_SAMPLES)return 0.0;

  res=sum/float(divider);
  return res;
	return 1.0;
}

float PCF(sampler2D shadowMap, vec4 coords) {
  //？？？不懂
  float texturesize=2048.0;
  float filtersize=5.0;
  float filterstride=1.0;
  float filterrange=filterstride*filtersize/texturesize;//possionDisk是偏移量，乘以滤波窗口的范围再加上原坐标得到新坐标 2048是engine.js中纹理的分辨率，5是滤波的步长？？为什么
  //滤波的步长是按照像素点的个数来说的，如5*5和7*7。
  
  poissonDiskSamples(coords.xy);
  // uniformDiskSamples(coords.xy);
  
  float res=0.0;
  for(int i=0;i<NUM_SAMPLES;i++)
  {
    float light_depth=unpack(texture2D(shadowMap,coords.xy+filterrange*poissonDisk[i]));//此处如果用0.02代替filterrange,则整个图像很糊
    res+=1.0/float(NUM_SAMPLES) * (light_depth+EPS<coords.z?0.0:1.0);
  }
  return res;
  return 1.0;
}

#define sizeOfLight 10.0
float PCSS(sampler2D shadowMap, vec4 coords){

  // STEP 1: avgblocker depth
  float avg_depth=findBlocker(shadowMap,coords.xy,coords.z);
  // STEP 2: penumbra size
  float wp=sizeOfLight*(coords.z-avg_depth)/avg_depth;
  // STEP 3: filtering
  float texturesize=2048.0;
  float filtersize=2.0;
  float filterrange=wp*filtersize/texturesize;
  float res=0.0;

  poissonDiskSamples(coords.xy);
  for(int i=0;i<NUM_SAMPLES;i++)
  {
    float light_depth=unpack(texture2D(shadowMap,coords.xy+filterrange*poissonDisk[i]));
    res+=1.0/float(NUM_SAMPLES) * (light_depth+EPS<coords.z?0.0:1.0);
  }
  return res;
  return 1.0;

}

//hard shadow
float useShadowMap(sampler2D shadowMap, vec4 shadowCoord){
  
  float map_depth=unpack(texture2D(shadowMap,shadowCoord.xy));//texture2D()用于在纹理坐标中查询纹理，返回vec4
  //unpack是什么？？
  if(shadowCoord.z>map_depth)return 0.0;//shadowcoord来自vPositionFromLight，就是从light看去的坐标了
  return 1.0;
}

vec3 blinnPhong() {
  vec3 color = texture2D(uSampler, vTextureCoord).rgb;
  color = pow(color, vec3(2.2));

  vec3 ambient = 0.05 * color;

  vec3 lightDir = normalize(uLightPos);
  vec3 normal = normalize(vNormal);
  float diff = max(dot(lightDir, normal), 0.0);
  vec3 light_atten_coff =
      uLightIntensity / pow(length(uLightPos - vFragPos), 2.0);
  vec3 diffuse = diff * light_atten_coff * color;

  vec3 viewDir = normalize(uCameraPos - vFragPos);
  vec3 halfDir = normalize((lightDir + viewDir));
  float spec = pow(max(dot(halfDir, normal), 0.0), 32.0);
  vec3 specular = uKs * light_atten_coff * spec;

  vec3 radiance = (ambient + diffuse + specular);
  vec3 phongColor = pow(radiance, vec3(1.0 / 2.2));
  return phongColor;
}

void main(void) {

  float visibility;

  //硬阴影卡了很久，因为没有看懂框架的意义
  //shadowCoord怎么可能凭空有呢？glsl就是c，肯定要符合c的语法，自己不要随意臆想
  vec3 shadowCoord=vPositionFromLight.xyz/vPositionFromLight.w;//变成[-1,1]坐标，就是将第四维深度变成1
  shadowCoord = shadowCoord.xyz * 0.5 + vec3(0.5, 0.5, 0.5);//变成[0,1]坐标，就是将[-1,1]变成[0,1]，缩放再平移/平移再缩放

  // visibility = useShadowMap(uShadowMap, vec4(shadowCoord, 1.0));//注释都不敢解掉，完全没搞懂代码。
  //不要猜，要去看代码，用你知道的语法规则去分析，他不是玄学，是你学过的语法

  // if(visibility+EPS<1.0)
  // visibility = PCF(uShadowMap, vec4(shadowCoord, 1.0));
   
  visibility = PCSS(uShadowMap, vec4(shadowCoord, 1.0));

  vec3 phongColor = blinnPhong();

  gl_FragColor = vec4(phongColor * visibility, 1.0);
  // gl_FragColor = vec4(phongColor, 1.0);
}