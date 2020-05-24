#version 430
#define PI 3.1415926535897932384626433832795

uniform mat4 modelviewMatrix;
uniform mat3 normalMatrix;
uniform mat4 transform;
uniform float time;
uniform vec2 mouse;

in vec4 vertex;
in vec4 normal;
in vec4 color;
in vec4 offset;
in vec4 direction;

out vec4 vertColor;
out vec4 backVertColor;
out vec3 ecNormal;
out vec4 ecVertex;

out vec4 vambient;
out vec4 vspecular;
out vec4 vemissive;
out float vshininess;

//Rotate vector with quaternion
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

//rnd function
float random(float x){
    return fract(sin(x) * 487954.254);
}

vec4 permute(vec4 x){return mod(((x*34.0)+1.0)*x, 289.0);}
vec4 taylorInvSqrt(vec4 r){return 1.79284291400159 - 0.85373472095314 * r;}

float snoise(vec3 v){ 
  const vec2  C = vec2(1.0/6.0, 1.0/3.0) ;
  const vec4  D = vec4(0.0, 0.5, 1.0, 2.0);

// First corner
  vec3 i  = floor(v + dot(v, C.yyy) );
  vec3 x0 =   v - i + dot(i, C.xxx) ;

// Other corners
  vec3 g = step(x0.yzx, x0.xyz);
  vec3 l = 1.0 - g;
  vec3 i1 = min( g.xyz, l.zxy );
  vec3 i2 = max( g.xyz, l.zxy );

  //  x0 = x0 - 0. + 0.0 * C 
  vec3 x1 = x0 - i1 + 1.0 * C.xxx;
  vec3 x2 = x0 - i2 + 2.0 * C.xxx;
  vec3 x3 = x0 - 1. + 3.0 * C.xxx;

// Permutations
  i = mod(i, 289.0 ); 
  vec4 p = permute( permute( permute( 
             i.z + vec4(0.0, i1.z, i2.z, 1.0 ))
           + i.y + vec4(0.0, i1.y, i2.y, 1.0 )) 
           + i.x + vec4(0.0, i1.x, i2.x, 1.0 ));

// Gradients
// ( N*N points uniformly over a square, mapped onto an octahedron.)
  float n_ = 1.0/7.0; // N=7
  vec3  ns = n_ * D.wyz - D.xzx;

  vec4 j = p - 49.0 * floor(p * ns.z *ns.z);  //  mod(p,N*N)

  vec4 x_ = floor(j * ns.z);
  vec4 y_ = floor(j - 7.0 * x_ );    // mod(j,N)

  vec4 x = x_ *ns.x + ns.yyyy;
  vec4 y = y_ *ns.x + ns.yyyy;
  vec4 h = 1.0 - abs(x) - abs(y);

  vec4 b0 = vec4( x.xy, y.xy );
  vec4 b1 = vec4( x.zw, y.zw );

  vec4 s0 = floor(b0)*2.0 + 1.0;
  vec4 s1 = floor(b1)*2.0 + 1.0;
  vec4 sh = -step(h, vec4(0.0));

  vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
  vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;

  vec3 p0 = vec3(a0.xy,h.x);
  vec3 p1 = vec3(a0.zw,h.y);
  vec3 p2 = vec3(a1.xy,h.z);
  vec3 p3 = vec3(a1.zw,h.w);

//Normalise gradients
  vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
  p0 *= norm.x;
  p1 *= norm.y;
  p2 *= norm.z;
  p3 *= norm.w;

// Mix final noise value
  vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
  m = m * m;
  return 42.0 * dot( m*m, vec4( dot(p0,x0), dot(p1,x1), 
                                dot(p2,x2), dot(p3,x3) ) );
}

void main(){
    float rnd  = random(gl_InstanceID * 20 + 1000);
    float maxSize = mix(0.5, 1.5, rnd);
    float dist = snoise(offset.xyz * 0.0005 + time * 0.1);
    dist = clamp(dist, 0.0, 1.0);
    float isHidden = smoothstep(0.0, 0.1, dist);
    vec3 growthVertex = vertex.xyz * vec3(dist * maxSize);

    vec3 up = vec3(0, 1, 0); //define the up vector
    vec3 dir = direction.xyz;//get the direction to rotate toward
    float upDotDir = dot(up, dir);
    float angle = abs(acos(upDotDir)); //get angle of rotation
    vec3 axis = normalize(cross(up, dir));//get axis of rotation
    vec3 rotatedVertex = rotateVertexPosition(growthVertex, axis, angle);
    vec3 rotatedNormal = rotateVertexPosition(normal.xyz, axis, angle);
    vec4 position = vec4(rotatedVertex.xyz + offset.xyz, 1.0);
    
    gl_Position = transform * position;
  
    //Define ecNormal & ecVertex
    ecNormal = normalize(normalMatrix * rotatedNormal.xyz);
    ecVertex = modelviewMatrix * position;

    vertColor = color;
    vertColor.a = isHidden;
    backVertColor = vec4(0.0);

    vambient = vec4(1.0);
    vspecular = vec4(vec3(0.5), 1.0);
    vemissive = vec4(vec3(0.0), 1.0);
    vshininess = 1.0;
}