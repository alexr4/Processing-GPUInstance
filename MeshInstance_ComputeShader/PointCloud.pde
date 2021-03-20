

public class PointCloud {
  public final static int MAX_PARTICLES = 1000000;
  private PGL pgl;
  private GL4 gl;
  private PApplet app;
  private PGraphics ctx;

  //particles component
  private int pclCount;
  private final static int VEC4_CMP = 4; //Number of component per vertex
  private final static int NBR_COMP =  VEC4_CMP * 3; //position, normal, origin

  //compute shader + FloatBuffer to handle the datas
  private ComputeProgram computeprogram;
  private float[] datas;
  private FloatBuffer pclbuffer;
  private int pclHandle;

  private VBOInterleaved vbo;
  
  int reset = 0;

  public PointCloud(PApplet app, PGL pgl, GL4 gl, PGraphics ctx) {
    this.app = app;
    this.pgl = pgl;
    this.gl = gl;
    this.ctx = ctx;
  }

  public void init(String path, int count) {
    pclCount = count;

    //init Float Buffer
    pclbuffer = Buffers.newDirectFloatBuffer(pclCount * (NBR_COMP * 2)); 

    computeprogram = new ComputeProgram(gl, loadAsText(path+"/pcl.comp"));
    IntBuffer intBuffer = IntBuffer.allocate(1);
    gl.glGenBuffers(1, intBuffer);
    pclHandle = intBuffer.get(0);

    println("init");
  }

  public void bindVBO(VBOInterleaved vbo) {

    // Select the VBO, GPU memory data, to use for vertices -> update the VBO Object
    // transfer data to VBO, this perform the copy of data from CPU -> GPU memory
    this.vbo = vbo;
    this.vbo.initInstanceVBO(this.pgl, this.pclHandle, this.pclbuffer);
    println("bind");
  }

  public void setRandomPoints() {
    float BOXWIDTH = 1000;
    for (int i=0; i<MAX_PARTICLES; i++) {
      this.pclbuffer.put(i * NBR_COMP + 0, random(BOXWIDTH * - 0.5, BOXWIDTH * 0.5));
      this.pclbuffer.put(i * NBR_COMP + 1, random(BOXWIDTH * - 0.5, BOXWIDTH * 0.5));
      this.pclbuffer.put(i * NBR_COMP + 2, random(BOXWIDTH * - 0.5, BOXWIDTH * 0.5));
      this.pclbuffer.put(i * NBR_COMP + 3, 1);

      this.pclbuffer.put(i * NBR_COMP + 4, random(1.0));
      this.pclbuffer.put(i * NBR_COMP + 5, random(1.0));
      this.pclbuffer.put(i * NBR_COMP + 6, random(1.0));
      this.pclbuffer.put(i * NBR_COMP + 7, 1);
    }
  }

  public void setPoints(float[] ivertList) {
    this.datas = ivertList;
    //for (int i=0; i<this.datas[i]; i++) {
    //  this.pclbuffer.put(i, this.datas[i]);
    //}
    pclbuffer.rewind();
    pclbuffer.put(ivertList);
    pclbuffer.rewind();
    println("set");
  }

  public void execute() {
    computeprogram.begin();

    int timeID = computeprogram.getUniformLocation("time");
    gl.glUniform1f(timeID, millis() * 0.0000001);
    
    
    int resetID = computeprogram.getUniformLocation("reset");
    gl.glUniform1i(resetID, reset);
    
    reset = 0;

    //bind buffer for storage
    gl.glBindBufferBase(GL4.GL_SHADER_STORAGE_BUFFER, 0, pclHandle);

    //execute compute shader
    computeprogram.compute(ceil(pclCount/1024.0), 1, 1); //check if the Working group is correct

    //unbind buffer
    gl.glBindBufferBase(GL4.GL_SHADER_STORAGE_BUFFER, 0, 0);
    computeprogram.end();
  }

  public void getGPUData() {
    //None. For now we only send data to VBO and not retreiving data into a CPU Buffer
    //see https://github.com/alexr4/jogl-compute-shaders-fireworks for implementation example
  }



  public void dispose() {
    computeprogram.dispose();
  }
}
