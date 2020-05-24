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

PVector scale = new PVector(2, 50, 2);

public void updateGeometry(VBOInterleaved vbo) {
  for (int i = 0; i<indices.length; i++) {
    PVector vertex = square[indices[i]].copy();
    vertex.x *= scale.x;
    vertex.y += 1.0; //set the pivot at the bottom of the shape
    vertex.y *= scale.y;
    vertex.z *= scale.z;

    vbo.setVertex(i, vertex.x, vertex.y, vertex.z);
  }

  //compute normal here
  for(int i=0;  i<indices.length; i+=3) {
     PVector v0 = square[indices[i+0]].copy();
     PVector v1 = square[indices[i+1]].copy();
     PVector v2 = square[indices[i+2]].copy();

     PVector v0v1 = PVector.sub(v1, v0);
     PVector v0v2 = PVector.sub(v2, v0);
     v0v1.normalize();
     v0v2.normalize();
     PVector normal = v0v1.cross(v0v2);
    //  normal.mult(-1.0);
     normal.normalize();

     vbo.setNormal(i+0, normal.x, normal.y, normal.z);
     vbo.setNormal(i+1, normal.x, normal.y, normal.z);
     vbo.setNormal(i+2, normal.x, normal.y, normal.z);
  }
}

public void updateColor(VBOInterleaved vbo) {
  for (int i = 0; i<indices.length; i++) {
    PVector vertex = square[indices[i]].copy();
    vertex.y = vertex.y * 0.5 + 0.5;
    float red   = lerp(0.0, 0.5216, vertex.y);
    float green = lerp(0.349, 1.0, vertex.y);
    float blue  = lerp(1.0, 0.6431, vertex.y);
    vbo.setColor(i, red, green, blue, 1.0); //white cube
  }
}
