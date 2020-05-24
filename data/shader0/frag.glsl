#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif
in vec4 vertColor;

void main() {
    gl_FragColor = vertColor;
}