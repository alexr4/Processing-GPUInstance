/**
 * This sketch demonstrate how to create and use a simple Low-Level interleaved VBO
 * with only few data such as (X, Y, Z, W, R, G, B, A)
 */

import peasy.*;

PeasyCam cam;

//ctx
PJOGL pjogl;
GL4 gl;

PShape model;
VBOInterleaved vbo;

int w = 1920;
int h = 1080;
float s = 0.75;



void settings() {
  size(int(w * s), int (h*s), P3D);
}

void setup() {
  frameRate(300);

  String path = sketchPath("../data/");
  model = loadShape(path+"einstein_Simplify.obj");
  
  //get width, height depth of shape for colors
  float w = model.getWidth();
  float h = model.getHeight();
  float d = model.getDepth();
  
  float scale = 25.0; //define scale for the shape (obj is small)
  
  //rerteives the data from the mesh
  ArrayList<Float> einsteindata = new ArrayList<Float>();
  for (int i=0; i<model.getChildCount(); i++) {
    PShape child = model.getChild(i);
    for (int j=0; j<child.getVertexCount(); j++) {
      PVector vertex = child.getVertex(j);
      einsteindata.add(vertex.x * scale);
      einsteindata.add(vertex.y * scale);
      einsteindata.add(vertex.z * scale);
      einsteindata.add(1.0);

      einsteindata.add(vertex.x / w);
      einsteindata.add(vertex.y / h);
      einsteindata.add(vertex.z / d);
      einsteindata.add(1.0);
    }
  }

  //create and init the VBO
  int nbrVertex = einsteindata.size() / 4; //each vertex has 4 components
  vbo = new VBOInterleaved(this);
  vbo.initVBO(g, nbrVertex);
  for (int i=0; i<einsteindata.size(); i++) {
    vbo.VBOi[i] = einsteindata.get(i);
  }
  vbo.updateVBO();

  cam = new PeasyCam(this, 500);
}

void draw() {
  //time sequence

  background(0);

  stroke(255, 0, 0);
  line(0, 0, 0, 150, 0, 0);
  stroke(0, 255, 0);
  line(0, 0, 0, 0, 150, 0);
  stroke(0, 0, 255);
  line(0, 0, 0, 0, 0, 150);

  //here goes the VBO
  vbo.draw(g);

  cam.beginHUD();
  fill(0);
  noStroke();
  rect(0, 0, width, 60);
  fill(255);
  text("Number of Instanced Mesh: "+vbo.maxInstance+"\n"+
    "Number of Vertex per mesh: "+model.getChildCount() * 3+"\n"+
    "Number of Vertex drawn on stage: "+(model.getChildCount() * 3) * vbo.maxInstance, 20, 20);
  cam.endHUD();

  surface.setTitle("GPUInstance — fps : "+round(frameRate));
}
