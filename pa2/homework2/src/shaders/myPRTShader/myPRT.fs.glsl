#ifdef GL_ES
precision mediump float;
#endif

varying highp vec2 vTextureCoord;
varying highp vec3 vFragPos;
varying highp vec3 vNormal;

varying vec3 vcolor;

void main() {
     gl_FragColor = vec4(vcolor,1.0);
}