attribute float a_index;
uniform sampler2D u_state;
uniform float u_count;
varying float v_color;

float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void main() {
  float u = (a_index + 0.5) / u_count;
  vec4 data = texture2D(u_state, vec2(u, 0.5));
  float x = data.r * 2.0 - 1.0;
  float y = data.g * 2.0 - 1.0;
  v_color = data.b;
  float size = 1.0 + hash(vec2(u, 0.7)) * 7.0; // 1–8 per particle
  gl_Position = vec4(x, y, 0.0, 1.0);
  gl_PointSize = size + 4.0;
}