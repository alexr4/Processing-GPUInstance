import peasy.*;

PeasyCam cam;

//sketch parameters
int w = 1280;
int h = 720;
float s = 1.0;

//ctx
PJOGL pjogl;
GL4 gl;

//Low-level VBO with GPU Instance support
VBOInterleaved vbo;

//mesh description (simple cube)
PVector[] square = {
  new PVector(-1.0, -1.0, 1.0), 
  new PVector(-1.0, 1.0, 1.0), 
  new PVector( 1.0, 1.0, 1.0), 
  new PVector( 1.0, -1.0, 1.0), 

  new PVector(-1.0, -1.0, -1.0), 
  new PVector(-1.0, 1.0, -1.0), 
  new PVector( 1.0, 1.0, -1.0), 
  new PVector( 1.0, -1.0, -1.0)
};

int[] indices = {
  0, 1, 3, 
  3, 1, 2, 

  3, 2, 7, 
  7, 2, 6, 

  7, 6, 4, 
  4, 6, 5, 

  4, 5, 0, 
  0, 5, 1, 

  4, 0, 7, 
  7, 0, 3, 

  6, 2, 5, 
  5, 2, 1
};

PVector scale = new PVector(25, 25, 25);


void settings() {
  size(int(w * s), int (h*s), P3D);
}

void setup() {
  frameRate(300);

  vbo = new VBOInterleaved(this);
  vbo.initVBO(g, indices.length);
  updateGeometry(vbo);//update the geometry of the vbo by feeding the buffer with the mesh position data
  updateColor(vbo);//update the geometry of the vbo by feeding the buffer with the mesh color data
  vbo.updateVBO();//update the buffers

  cam = new PeasyCam(this, 5000);
}

void draw() {

  //time sequence
  float maxTimeX = 10000;
  float maxTimeY = 20000;
  float timeX = (millis() % maxTimeX) / maxTimeX;
  float timeY = (millis() % maxTimeY) / maxTimeY;


  //here goes the VBO
  background(0);
  rotateX(timeX * TWO_PI);
  rotateY(timeY * TWO_PI);
  vbo.draw(g);


  surface.setTitle("GPUInstance — fps : "+round(frameRate));
}


public void updateGeometry(VBOInterleaved vbo) {
  for (int i = 0; i<indices.length; i++) {
    PVector vertex = square[indices[i]].copy();
    vertex.x *= scale.x;
    vertex.y *= scale.y;
    vertex.z *= scale.z;
    vbo.setVertex(i, vertex.x, vertex.y, vertex.z);
  }
}

public void updateColor(VBOInterleaved vbo) {
  for (int i = 0; i<indices.length; i++) {
    PVector vertex = square[indices[i]].copy();

    vertex.x  = vertex.x * 0.5 + 0.5; 
    vertex.y  = vertex.y * 0.5 + 0.5; 
    vertex.z  = vertex.z * 0.5 + 0.5; 
    vbo.setColor(i, vertex.x, vertex.y, vertex.z, 1.0);
  }
}
