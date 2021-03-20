import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;

/*Compute Shader compiler from Perses-games https://github.com/alexr4/jogl-compute-shaders-fireworks*/
public class ComputeProgram extends Program {
  
  private GL4                 gl4;
  private int                 computeShader;

  public ComputeProgram(GL4 gl, String compute) {
    super(gl);
    this.gl4 = gl;

    computeShader = createAndCompileShader(GL4.GL_COMPUTE_SHADER, compute);

    program = gl.glCreateProgram();

    gl.glAttachShader(program, computeShader);

    gl.glLinkProgram(program);
  }

  public void compute(int x, int y, int z) {
    gl4.glDispatchCompute(x, y, z);
  }

  public void dispose() {
    gl.glDetachShader(program, computeShader);
    gl.glDeleteShader(computeShader);

    super.dispose();
  }
}


/*BASED shader program from Perses-games :  https://github.com/alexr4/jogl-compute-shaders-fireworks*/
public abstract class Program {

  protected GL2ES2              gl;

  protected int                 program;

  private Map<String, Integer>  uniformLocations = new HashMap<String, Integer>();
  private Map<String, Integer>  attribLocations = new HashMap<String, Integer>();

  public Program(GL2ES2 gl) {
    this.gl = gl;
  }

  public int getUniformLocation(String uniform) {
    Integer result = uniformLocations.get(uniform);

    if (result == null) {
      result = gl.glGetUniformLocation(program, uniform);

      uniformLocations.put(uniform, result);
    }

    return result;
  }

  public int getAttribLocation(String attrib) {
    Integer result = attribLocations.get(attrib);

    if (result == null) {
      result = gl.glGetAttribLocation(program, attrib);

      attribLocations.put(attrib, result);
    }

    return result;
  }

  public void bindAttributeLocation(int location, String name) {
    gl.glBindAttribLocation(program, location, name);
  }

  public void begin() {
    gl.glUseProgram(program);
  }

  public void end() {
    gl.glUseProgram(0);
  }

  protected void dispose() {
    gl.glDeleteProgram(program);
  }

  protected int createAndCompileShader(int type, String shaderString) {
    int shader = gl.glCreateShader(type);

    String[] vlines = new String[]{shaderString};
    int[] vlengths = new int[]{vlines[0].length()};

    gl.glShaderSource(shader, vlines.length, vlines, vlengths, 0);
    gl.glCompileShader(shader);

    int[] compiled = new int[1];
    gl.glGetShaderiv(shader, GL2ES2.GL_COMPILE_STATUS, compiled, 0);

    if (compiled[0] == 0) {
      int[] logLength = new int[1];
      gl.glGetShaderiv(shader, GL2ES2.GL_INFO_LOG_LENGTH, logLength, 0);

      byte[] log = new byte[logLength[0]];
      gl.glGetShaderInfoLog(shader, logLength[0], (int[]) null, 0, log, 0);

      throw new IllegalStateException("Error compiling the shader: " + new String(log));
    }

    return shader;
  }
}


/*
Static method to load file as a String
 */
public String loadAsText(String filename) {
  String[] array = loadStrings(filename);
  String value = "";
  for(int i=0; i<array.length; i++){
    value += array[i]+"\n";
  }
  //println(value);
  return value;
}
