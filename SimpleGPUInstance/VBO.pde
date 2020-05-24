import java.nio.*;
import com.jogamp.opengl.GL4;

public class VBOInterleaved implements ShaderSource {
  final static short VEC4_CMP = 4; //Number of component per vector
  /*define layout for interleaved VBO
   xyzwrgbaxyzwrgbaxyzwrgba...
   
   |v1       |v2       |v3       |... vertex
   |0   |4   |8   |12  |16  |20  |... offset
   |xyzw|rgba|xyzw|rgba|xyzw|rgba|... components
   
   stride (values per vertex) is 8 floats
   vertex offset is 0 floats (starts at the beginning of each line)
   color offset is 4 floats (starts after vertex coords)
   
   |0   |4   |8
   v1 |xyzw|rgba|
   v2 |xyzw|rgba|
   v3 |xyzw|rgba|
   |...
   */

  final static short NBR_COMP    = VEC4_CMP * 2; 
  final static short STRIDE      = VEC4_CMP * Float.BYTES;
  final static short VRT_OFFSET  = 0 * Float.BYTES;
  final static short CLR_OFFSET  = 0 * Float.BYTES;

  private GL4 gl;
  private int maxInstance = round(pow(40, 3)); //define the number of instances

  private float[] VBOPos, VBOColor;
  private int vertexCount;
  private FloatBuffer posBuff, colorBuffer;
  private int posBufferId, colorBufferId;
  private PShader shader;
  private PApplet parent;

  //instanced VBO
  private float[] VBOOffset;
  private FloatBuffer offsetBuffer;
  private int offsetBufferId;

  public VBOInterleaved(PApplet parent) {
    this.parent = parent;
    this.init();
  }

  private void init() {
    this.shader = new PShader(this.parent, this.vertSource, this.fragSource);
  }

  private void initVBO(PGraphics context, int numberOfVertex) {
    this.vertexCount      = numberOfVertex;
    this.VBOPos           = new float[vertexCount * VEC4_CMP];
    this.VBOColor         = new float[vertexCount * VEC4_CMP];
    this.VBOOffset        = new float[maxInstance * VEC4_CMP];
    this.posBuff          = allocateDirectFloatBuffer(VBOPos.length);
    this.colorBuffer      = allocateDirectFloatBuffer(VBOColor.length);
    this.offsetBuffer     = allocateDirectFloatBuffer(VBOOffset.length);


    PJOGL pjoglgl = (PJOGL) context.beginPGL(); 
    gl = pjoglgl.gl.getGL4();
    IntBuffer intBuffer = IntBuffer.allocate(3);
    gl.glGenBuffers(3, intBuffer);

    this.posBufferId     = intBuffer.get(0);
    this.colorBufferId   = intBuffer.get(1);
    this.offsetBufferId  = intBuffer.get(2);
    context.endPGL();

    this.feedOffsetBuffer();
    this.updateVBO(this.posBuff, this.VBOPos);
    this.updateVBO(this.colorBuffer, this.VBOColor);
    this.updateVBO(this.offsetBuffer, this.VBOOffset);
  }


  private void feedOffsetBuffer() {

    /**1D to 3D index
     divider = int(pow(maxInstance, 1.0 / 3.0));
     x = i / (divider * divider);
     y = (i/divider) % divider 
     z = i % divider 
     
     */
    int divider = int(pow(maxInstance, 1.0/3.0));
    float offset = 100.0;
    float centerOffset = (divider / 2) * offset;

    for (int i=0; i<VBOOffset.length / VEC4_CMP; i++) {
      VBOOffset[i * VEC4_CMP + 0] = float( i / (divider * divider)) * offset - centerOffset;
      VBOOffset[i * VEC4_CMP + 1] = float((i/divider) % divider) * offset - centerOffset;
      VBOOffset[i * VEC4_CMP + 2] = float( i % divider ) * offset - centerOffset;
      VBOOffset[i * VEC4_CMP + 3] = 0.0;
    }
  }

  public void updateVBO() {
    this.updateVBO(this.posBuff, this.VBOPos);
    this.updateVBO(this.colorBuffer, this.VBOColor);
    this.updateVBO(this.offsetBuffer, this.VBOOffset);
  }

  public void updateVBO(FloatBuffer buffer, float[] array) {
    try {
      buffer.rewind(); 
      buffer.put(array); 
      buffer.rewind();
    }
    catch(Exception e) {
      e.printStackTrace();
    }
  }

  public void setVertex(int i, float x, float y, float z) {
    this.VBOPos[i * VEC4_CMP + 0] = x;
    this.VBOPos[i * VEC4_CMP + 1] = y;
    this.VBOPos[i * VEC4_CMP + 2] = z;
    this.VBOPos[i * VEC4_CMP + 3] = 1.0;
  }

  public void setColor(int i, float r, float g, float b, float a) {
    this.VBOColor[i * VEC4_CMP + 0] = r;
    this.VBOColor[i * VEC4_CMP + 1] = g;
    this.VBOColor[i * VEC4_CMP + 2] = b;
    this.VBOColor[i * VEC4_CMP + 3] = a;
  }

  public void draw(PGraphics context) {
    //this is hardcoded → It needs to be clean up
    PJOGL pjoglgl = (PJOGL) context.beginPGL(); 
    gl = pjoglgl.gl.getGL4();

    this.shader.bind();
    //send uniform to shader if necessary

    //set position
    int vrtLoc = gl.glGetAttribLocation(this.shader.glProgram, "vertex");
    gl.glEnableVertexAttribArray(vrtLoc);
    //bind VBO
    gl.glBindBuffer(PGL.ARRAY_BUFFER, posBufferId);
    //fill data
    gl.glBufferData(PGL.ARRAY_BUFFER, Float.BYTES * VBOPos.length, posBuff, PGL.STATIC_DRAW);//USE PGL.STATIC_DRAW if attributes are not set to be update by the CPU
    gl.glVertexAttribPointer(vrtLoc, VEC4_CMP, PGL.FLOAT, false, STRIDE, VRT_OFFSET);

    //set color
    int clrLoc = gl.glGetAttribLocation(this.shader.glProgram, "color");
    gl.glEnableVertexAttribArray(clrLoc);
    //bind VBO
    gl.glBindBuffer(PGL.ARRAY_BUFFER, colorBufferId);
    //fill data
    gl.glBufferData(PGL.ARRAY_BUFFER, Float.BYTES * VBOColor.length, colorBuffer, PGL.STATIC_DRAW);//USE PGL.STATIC_DRAW if attributes are not set to be update by the CPU
    gl.glVertexAttribPointer(clrLoc, VEC4_CMP, PGL.FLOAT, false, STRIDE, CLR_OFFSET);


    int offsetLoc = gl.glGetAttribLocation(this.shader.glProgram, "offset");
    gl.glEnableVertexAttribArray(offsetLoc);
    //bind VBO
    gl.glBindBuffer(PGL.ARRAY_BUFFER, offsetBufferId);
    //fill data
    gl.glBufferData(PGL.ARRAY_BUFFER, Float.BYTES * VBOOffset.length, offsetBuffer, PGL.STATIC_DRAW);
    //Associate current bound vbo with attribute
    gl.glVertexAttribPointer(offsetLoc, VEC4_CMP, PGL.FLOAT, false, STRIDE, VRT_OFFSET);
    gl.glVertexAttribDivisor(offsetLoc, 1);

    //draw buffer
    gl.glDrawArraysInstanced(PGL.TRIANGLES, 0, this.vertexCount, maxInstance);
    

    //undind VBO
    gl.glBindBuffer(PGL.ARRAY_BUFFER, 0);

    //disable arrays
    gl.glVertexAttribDivisor(offsetLoc, 0);
    gl.glDisableVertexAttribArray(vrtLoc);
    gl.glDisableVertexAttribArray(clrLoc);
    gl.glDisableVertexAttribArray(offsetLoc);

    //unbind shader
    this.shader.unbind();

    gl = null;
    pjogl = null;
    context.endPGL();
  }

  //utils
  private FloatBuffer allocateDirectFloatBuffer(int n) {
    return ByteBuffer.allocateDirect(n * Float.BYTES).order(ByteOrder.nativeOrder()).asFloatBuffer();
  }
}

static interface ShaderSource {
  public final static String[] vertSource = {
    "#version 430", 
    "uniform mat4 transform;", 
    "uniform int maxInstance;", 
    "uniform float offseter;", 
    "in vec4 vertex;", 
    "in vec4 color;", 
    "in vec4 offset;", 
    "out vec4 vertColor;", 
    "void main(){", 
    "gl_Position = transform * (vertex + offset);", 
    "vertColor = color;", 
    "}"
  };

  public final static String[] fragSource = {
    "#ifdef GL_ES", 
    "precision mediump float;", 
    "precision mediump int;", 
    "#endif", 
    "in vec4 vertColor;", 
    "void main() {", 
    "gl_FragColor = vertColor;", 
    "}"
  };
}
