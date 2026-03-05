attribute float a_index;
uniform sampler2D u_state;
uniform float u_count;
varying float v_color;
varying float v_size;
varying float v_speed;

void main() {
  float u = (a_index + 0.5) / u_count;
  vec4 data = texture2D(u_state, vec2(u, 0.5));
  float x = data.r * 2.0 - 1.0;
  float y = data.g * 2.0 - 1.0;

  // Unpack B channel: color*8 + direction
  float packed_b = floor(data.b + 0.5);
  v_color = floor(packed_b / 8.0);

  // Unpack A channel: size*8 + speed
  float packed_a = floor(data.a + 0.5);
  v_size = floor(packed_a / 8.0);
  v_speed = packed_a - v_size * 8.0;

  gl_Position = vec4(x, y, 0.0, 1.0);
  gl_PointSize = v_size + 1.0 + 4.0;
}