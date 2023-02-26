//实现了 EmissiveMaterial，然而我就感觉这个文件应该放到 materials 目录下面，毕竟这只是个材质实现。
class EmissiveMaterial extends Material {

    constructor(lightIntensity, lightColor) {
        super({
            'uLigIntensity': { type: '1f', value: lightIntensity },
            'uLightColor': { type: '3fv', value: lightColor }
        }, [], LightCubeVertexShader, LightCubeFragmentShader);

        this.intensity = lightIntensity;
        this.color = lightColor;
    }

    GetIntensity() {
        return [this.intensity * this.color[0], this.intensity * this.color[1], this.intensity * this.color[2]]
    }
}
