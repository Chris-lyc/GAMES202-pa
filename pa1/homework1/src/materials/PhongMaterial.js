class PhongMaterial extends Material {
    //主要实现了 Phong 渲染模型的框架结构

    //在构造函数中传入了 light（场景光源Object），translate（当前模型的 Translation） 和 scale （当前模型的Scale） 三个参数，
    //这样的做法有些奇怪，理论上来说 Material 的计算应当独立于光照和模型，应当在实际的计算中通过参数去获取这些信息，
    //但是这里相当于是为每个模型实例化出了一个材质实例，在这个实例中内置了这些参数。
    constructor(color, specular, light, translate, scale, vertexShader, fragmentShader) {
        let lightMVP = light.CalcLightMVP(translate, scale);
        let lightIntensity = light.mat.GetIntensity();

        //传入给父类的 Uniform 参数，与 ShadowMaterial 传入父类的 Uniform 参数是有差别的
        super({
            // Phong
            'uSampler': { type: 'texture', value: color },
            'uKs': { type: '3fv', value: specular },
            'uLightIntensity': { type: '3fv', value: lightIntensity },
            // Shadow
            'uShadowMap': { type: 'texture', value: light.fbo },
            'uLightMVP': { type: 'matrix4fv', value: lightMVP },

        }, [], vertexShader, fragmentShader);
    }
}

async function buildPhongMaterial(color, specular, light, translate, scale, vertexPath, fragmentPath) {


    let vertexShader = await getShaderString(vertexPath);
    let fragmentShader = await getShaderString(fragmentPath);

    return new PhongMaterial(color, specular, light, translate, scale, vertexShader, fragmentShader);

}