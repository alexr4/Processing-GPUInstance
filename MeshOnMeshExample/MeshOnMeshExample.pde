/*
Key : 
 'd' : display debug
 's' display based shape
 */
import peasy.*;

//Sketch parameters
int fwidth = 1920;
int fheight = 1080;
float skecthScale = 0.75;

PeasyCam cam;

//assets
String path;
PShape basedShape;
PShape highResShape;
float scale3d = 100.0; //define the scale of the shape as loaded obj are small

//VBO: custom vertex buffer object for gpu mesh instancing
PShape flowerBased;
VBOInterleaved vbo;

//debug
boolean init;
boolean debug;
boolean displayBased = true;
PShape normalShape; //debug shape for normal orientation

void settings() {
  int swidth = round(fwidth * skecthScale);
  int sheight = round(fheight * skecthScale); 
  size(swidth, sheight, P3D);
}

void setup() {
  cam = new PeasyCam(this, 0, -1500, 0, 3000);
  path = sketchPath("../data/");
}

void draw() {
  if (!init) {
    println("load OBJ");
    basedShape = loadShape(path+"AMPHITRITE-LP.obj");
    highResShape = loadShape(path+"AMPHITRITE.obj");
    normalShape = createShape(GROUP);

    println("obj Loaded\nParse OBJ data");
    int numberOfInstance = basedShape.getChildCount();
    println(numberOfInstance);

    //our array of data per instance will contains the position of the mesh (vec4) and the normal/direction of the instance (vec4).
    //The array will be a size of number of instances * (4 + 4)
    int nbrOfCompPerData = 4 + 4; //vec4(position) + vec4(normal)
    float[] perInstanceData = new float[numberOfInstance * (4 + 4)]; 

    for (int ci=0; ci<numberOfInstance; ci++) {
      PShape triangle = basedShape.getChild(ci);

      PVector v0 = triangle.getVertex(0);
      PVector v1 = triangle.getVertex(1);
      PVector v2 = triangle.getVertex(2);

      PVector n0 = triangle.getNormal(0);
      PVector n1 = triangle.getNormal(1);
      PVector n2 = triangle.getNormal(2);

      v0.mult(scale3d);
      v1.mult(scale3d);
      v2.mult(scale3d);

      PVector gravity = v0.copy().add(v1).add(v2);
      gravity.div(3.0);

      PVector normal = n0.copy().add(n1).add(n2);
      normal.div(3.0);

      //normal computation if shape does not has any normals
      // PVector v0v1 = PVector.sub(v0, v1);
      // PVector v0v2 = PVector.sub(v0, v2);
      // PVector normal = v0v1.cross(v0v2);
      // normal.normalize();

      perInstanceData[ci * nbrOfCompPerData + 0] = gravity.x;
      perInstanceData[ci * nbrOfCompPerData + 1] = gravity.y;
      perInstanceData[ci * nbrOfCompPerData + 2] = gravity.z;
      perInstanceData[ci * nbrOfCompPerData + 3] = 0.0;

      perInstanceData[ci * nbrOfCompPerData + 4] = normal.x;
      perInstanceData[ci * nbrOfCompPerData + 5] = normal.y;
      perInstanceData[ci * nbrOfCompPerData + 6] = normal.z;
      perInstanceData[ci * nbrOfCompPerData + 7] = 0.0;

      PShape line = createShape();
      line.beginShape(LINES);
      line.stroke(255);
      line.vertex(gravity.x, gravity.y, gravity.z);
      line.vertex(gravity.x + normal.x * 25.0, gravity.y + normal.y * 25.0, gravity.z + normal.z * 25.0);
      line.endShape();

      normalShape.addChild(line);
    }

    println("OBJ data parsed\nCreate VBO");

    //Load main flower shape to send to VBO as mesh data

    flowerBased = loadShape(path+"mainFlower.obj");
    vbo = new VBOInterleaved(this, path+"shader2/");
    vbo.initVBO(g, flowerBased.getChildCount() * 3, numberOfInstance); //create a VBO with a mesh of 'indices.length' vertices and 'numberOfInstance' of instances

    //get the based flower mesh data and send it to the VBO
    int i = 0;
    float scale = 25.0;
    for (int ci=0; ci<flowerBased.getChildCount(); ci++) {
      PShape triangle = flowerBased.getChild(ci);
      for (int vi=0; vi<triangle.getVertexCount(); vi++) {
        PVector vertex = triangle.getVertex(vi).copy();
        PVector normal = triangle.getNormal(vi);

        vertex.y = vertex.y / flowerBased.getHeight();
        float red   = lerp(0.0, 0.5216, vertex.y);
        float green = lerp(0.349, 1.0, vertex.y);
        float blue  = lerp(1.0, 0.6431, vertex.y);
        PVector vcolor = new PVector(red, green, blue);

        vertex.mult(scale);

        vbo.setVertex(i, vertex.x, vertex.y, vertex.z);
        vbo.setNormal(i, normal.x, normal.y, normal.z);
        vbo.setColor(i, vcolor.x, vcolor.y, vcolor.z, 1.0);
        i++;
      }
    }

    vbo.updateVBO(); //update the interleaved VBO for shared mesh data
    vbo.updateVBO(vbo.offsetBuffer, perInstanceData);

    init = true;
    println("VBO Created\nStart Draw");
  } else {
    background(0);

    // lights();
    ambientLight(10, 10, 10);
    directionalLight(255, 255, 255, -1, 0.75, -0.75);
    directionalLight(100, 100, 100, 1, -0.75, -0.75);

    //move the shape at t
    rotateX(PI);
    rotateY(PI*0.5);

    if (displayBased) {
      pushMatrix();
      scale(scale3d);
      if (!debug) shape(highResShape);
      else shape(basedShape);
      popMatrix();
    }

    vbo.draw(g);

    if (debug) {
      stroke(255);
      noFill();
      box(4000);
      gizmo(500);
      shape(normalShape); //display debug shape
    }

    surface.setTitle("GPUInstance — fps : "+round(frameRate));
  }
}


void gizmo(float len) {
  stroke(255, 0, 0);
  line(0, 0, 0, len, 0, 0);
  stroke(0, 255, 0);
  line(0, 0, 0, 0, len, 0);
  stroke(0, 0, 255);
  line(0, 0, 0, 0, 0, len);
}

void keyPressed() {
  switch(key) {
  case 'd':
  case 'D' :
    debug = !debug;
    break;
  case 's':
  case 'S' :
    displayBased = !displayBased;
    break;
  }
}
