async function loadShaderFile(filename) {
    //加载 glsl shader 文件，并将文件内容以字符串的形式返回

    return new Promise((resolve, reject) => {
        const loader = new THREE.FileLoader();

        loader.load(filename, (data) => {
            resolve(data);
            //console.log(data);
        });
    });
}

async function getShaderString(filename) {

    let val = ''
    await this.loadShaderFile(filename).then(result => {
        val = result;
    });
    //console.log(val);
    return val;
}
