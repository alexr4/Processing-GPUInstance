import peasy.*;

PeasyCam cam;

int w = 1280;
int h = 720;
float s = 1.0;
String path;

//ctx
PJOGL pjogl;
GL4 gl;

VBOInterleaved vbo;

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

PVector scale = new PVector(5, 50, 5);


void settings() {
  size(int(w * s), int (h*s), P3D);
}

void setup() {
  frameRate(300);
  path = sketchPath("../data/");

  vbo = new VBOInterleaved(this, path+"shader0/");
  vbo.initVBO(g, indices.length);
  updateGeometry(vbo);
  updateColor(vbo);
  vbo.updateVBO();

  cam = new PeasyCam(this, 5000);
}

void draw() {

  //time sequence
  float maxTimeX = 30000;
  float maxTimeY = 60000;
  float timeX = (millis() % maxTimeX) / maxTimeX;
  float timeY = (millis() % maxTimeY) / maxTimeY;
  float z = map(mouseX, 0, width, 0, -10000.0);

  background(0);
  rotateY(timeY * TWO_PI);

  stroke(255, 0, 0);
  line(0, 0, 0, 150, 0, 0);
  stroke(0, 255, 0);
  line(0, 0, 0, 0, 150, 0);
  stroke(0, 0, 255);
  line(0, 0, 0, 0, 0, 150);

  //here goes the VBO
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
