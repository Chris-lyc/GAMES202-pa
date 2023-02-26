class Shader {

    //构造函数调用了本类的其他所有方法，完成了整个 Shader 从 compile 到 link 的全过程。
    constructor(gl, vsSrc, fsSrc, shaderLocations) {
        this.gl = gl;
        const vs = this.compileShader(vsSrc, gl.VERTEX_SHADER);
        const fs = this.compileShader(fsSrc, gl.FRAGMENT_SHADER);

        this.program = this.addShaderLocations({
            glShaderProgram: this.linkShader(vs, fs),
        }, shaderLocations);
    }

    //WebGL 中 Shader Compile操作的封装
    compileShader(shaderSource, shaderType) {
        const gl = this.gl;
        var shader = gl.createShader(shaderType);
        gl.shaderSource(shader, shaderSource);
        gl.compileShader(shader);

        if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
            console.error(shaderSource);
            console.error('shader compiler error:\n' + gl.getShaderInfoLog(shader));
        }

        return shader;
    };

    //WebGL 中 Shader link操作的封装
    linkShader(vs, fs) {
        const gl = this.gl;
        var prog = gl.createProgram();
        gl.attachShader(prog, vs);
        gl.attachShader(prog, fs);
        gl.linkProgram(prog);

        if (!gl.getProgramParameter(prog, gl.LINK_STATUS)) {
            abort('shader linker error:\n' + gl.getProgramInfoLog(prog));
        }
        return prog;
    };

    //完成了 uniform 和 attribute 变量和 Shader 中对应变量地址的关联
    //result（Shader.program）的结构：
    //glShaderProgram: Link 之后的 Program，是 linkShader() 方法返回的结果
    //uniforms: Map结构，Key 是 uniform 变量名称，Value 是 gl.getUniformLocation() 的结果。
    //attribs: Map结构，Key 是 attribute 变量名称，Value 是 gl.getAttribLocation() 的结果。
    addShaderLocations(result, shaderLocations) {
        const gl = this.gl;
        result.uniforms = {};
        result.attribs = {};

        if (shaderLocations && shaderLocations.uniforms && shaderLocations.uniforms.length) {
            for (let i = 0; i < shaderLocations.uniforms.length; ++i) {
                result.uniforms = Object.assign(result.uniforms, {
                    [shaderLocations.uniforms[i]]: gl.getUniformLocation(result.glShaderProgram, shaderLocations.uniforms[i]),
                });
            }
        }
        if (shaderLocations && shaderLocations.attribs && shaderLocations.attribs.length) {
            for (let i = 0; i < shaderLocations.attribs.length; ++i) {
                result.attribs = Object.assign(result.attribs, {
                    [shaderLocations.attribs[i]]: gl.getAttribLocation(result.glShaderProgram, shaderLocations.attribs[i]),
                });
            }
        }

        return result;
    }
}
