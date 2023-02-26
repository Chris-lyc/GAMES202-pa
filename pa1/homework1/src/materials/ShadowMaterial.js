class ShadowMaterial extends Material {
    //与 PhongMaterial 大同小异，只是传入的参数有些不同。

    constructor(light, translate, scale, vertexShader, fragmentShader) {
        let lightMVP = light.CalcLightMVP(translate, scale);

        //另外的区别就是在调用基类 Material 的构造函数时，传入了 light.fbo，
        //在基类中会把 light.fbo 赋值到成员frameBuffer 上，这样在绘制的时候，通过判断 frameBuffer 是否为空来决定是绘制到屏幕还是绘制到 framebuffer。
        super({
            'uLightMVP': { type: 'matrix4fv', value: lightMVP }
        }, [], vertexShader, fragmentShader, light.fbo);
    }
}

async function buildShadowMaterial(light, translate, scale, vertexPath, fragmentPath) {


    let vertexShader = await getShaderString(vertexPath);
    let fragmentShader = await getShaderString(fragmentPath);

    return new ShadowMaterial(light, translate, scale, vertexShader, fragmentShader);

}