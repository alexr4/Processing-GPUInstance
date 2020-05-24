#version 430
#define PI 3.1415926535897932384626433832795

uniform mat4 transform;
uniform int maxInstance;
uniform float offseter;
uniform float time;

in vec4 vertex;
in vec4 color;
in vec4 offset;

out vec4 vertColor;

//from https://www.geeks3d.com/20141201/how-to-rotate-a-vertex-by-a-quaternion-in-glsl/
vec4 quatFromAxis(in vec3 axis, in float angle){
    float halfAngle = angle * 0.5;
    vec3 quatxyz = axis * sin(halfAngle);
    float quatw = cos(halfAngle);

    return vec4(quatxyz, quatw);
}

vec4 quatInv(vec4 quat){
    return vec4(-quat.xyz, quat.w);
}

vec4 quatMult(vec4 q1, vec4 q2){
    vec4 qr;
    qr.x = (q1.w * q2.x) + (q1.x * q2.w) + (q1.y * q2.z) - (q1.z * q2.y);
    qr.y = (q1.w * q2.y) - (q1.x * q2.z) + (q1.y * q2.w) + (q1.z * q2.x);
    qr.z = (q1.w * q2.z) + (q1.x * q2.y) - (q1.y * q2.x) + (q1.z * q2.w);
    qr.w = (q1.w * q2.w) - (q1.x * q2.x) - (q1.y * q2.y) - (q1.z * q2.z);
    return qr;
}

vec3 rotateVertexPosition(in vec3 vertex, vec3 axis, float angle){
    vec4 qr     = quatFromAxis(axis, angle);
    vec4 qi     = quatInv(qr);
    vec4 qp     = vec4(vertex, 0);

    vec4 qtmp   = quatMult(qr, qp);
    qr          = quatMult(qtmp, qi);

    return vec3(qr.xyz);
}

void main(){
    vec3 up = vec3(0, 1, 0);
    float dist = sin(time) * 1500;
    vec3 dir = normalize(vec3(0, dist, 0) - offset.xyz);
    float upDotDir = dot(up, dir);
    float angle = abs(acos(upDotDir));
    vec3 axis = normalize(cross(up, dir));

    vec3 rotatedVertex = rotateVertexPosition(vertex.xyz, axis, angle);
    
    gl_Position = transform * vec4(rotatedVertex.xyz + offset.xyz, 1.0);
    vertColor = color;
}