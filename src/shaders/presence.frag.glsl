precision mediump float;
varying float v_color;
varying float v_size;
varying float v_speed;

void main() {
  vec2 c = gl_PointCoord - 0.5;
  if (dot(c, c) > 0.25) discard;

  // Encode aggregate data for additive blending (UNSIGNED_BYTE texture)
  // Scale values small enough to avoid saturation with ~64 overlapping particles
  float count_inc = 1.0 / 64.0;
  float color_inc = (v_color + 0.5) / (16.0 * 64.0);
  float size_inc  = (v_size + 0.5) / (8.0 * 64.0);
  float speed_inc = (v_speed + 0.5) / (8.0 * 64.0);

  gl_FragColor = vec4(count_inc, color_inc, size_inc, speed_inc);
}