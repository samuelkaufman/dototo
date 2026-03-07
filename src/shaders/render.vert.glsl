attribute float a_index;
uniform sampler2D u_state;
uniform float u_count;
varying float v_colorIndex;
varying float v_energy;

void main() {
  float u = (a_index + 0.5) / u_count;
  vec4 data = texture2D(u_state, vec2(u, 0.5));
  float x = data.r * 2.0 - 1.0;
  float y = data.g * 2.0 - 1.0;

  // Unpack B channel: color*8 + direction
  float packed_b = floor(data.b + 0.5);
  v_colorIndex = floor(packed_b / 8.0);  // 0-15

  // Unpack A channel: integer part = size*8 + speed, fractional part = energy
  float intPart = floor(data.a);
  float size = floor(intPart / 8.0);    // 0-7
  v_energy = data.a - intPart;          // 0.0-0.9

  gl_Position = vec4(x, y, 0.0, 1.0);
  gl_PointSize = size + 1.0;  // 1-8 pixels
}
