attribute float a_index;
uniform sampler2D u_state;
uniform vec2 u_texSize;
varying float v_colorIndex;
varying float v_speed;

void main() {
  float row = floor(a_index / u_texSize.x);
  float col = a_index - row * u_texSize.x;
  vec2 uv = vec2((col + 0.5) / u_texSize.x, (row + 0.5) / u_texSize.y);
  vec4 data = texture2D(u_state, uv);
  float x = data.r * 2.0 - 1.0;
  float y = data.g * 2.0 - 1.0;

  // Unpack B channel: color*16 + direction
  float packed_b = floor(data.b + 0.5);
  v_colorIndex = floor(packed_b / 16.0);  // 0-15

  // Unpack A channel: integer part = size*8 + speed, fractional part = energy
  float intPart = floor(data.a);
  float sz = floor(intPart / 8.0);    // 0-7
  float size = 3.0;
  v_speed = intPart - sz * 8.0;

  gl_Position = vec4(x, y, 0.0, 1.0);
  gl_PointSize = size + 1.0;  // 1-8 pixels
}
