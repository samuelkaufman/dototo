attribute float a_index;
uniform sampler2D u_state;
uniform float u_count;
uniform float u_pointSize;
varying float v_color;
void main() {
  float u = (a_index + 0.5) / u_count;
  vec4 data = texture2D(u_state, vec2(u, 0.5));
  float x = data.r * 2.0 - 1.0;
  float y = data.g * 2.0 - 1.0;
  v_color = data.b;
  gl_Position = vec4(x, y, 0.0, 1.0);
  gl_PointSize = u_pointSize + 4.0;
}