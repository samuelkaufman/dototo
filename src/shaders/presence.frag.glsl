precision mediump float;
varying float v_color;
void main() {
  vec2 c = gl_PointCoord - 0.5;
  if (dot(c, c) > 0.25) discard;
  if (v_color > 0.5) {
    gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
  } else {
    gl_FragColor = vec4(0.0, 1.0, 0.0, 1.0);
  }
}