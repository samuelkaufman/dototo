precision mediump float;
varying float v_colorIndex;

vec3 fireColor(float index) {
  float t = index / 15.0;
  vec3 c;
  if (t < 0.25) {
    // dark red -> red
    c = mix(vec3(0.1, 0.0, 0.0), vec3(0.7, 0.0, 0.0), t / 0.25);
  } else if (t < 0.5) {
    // red -> orange
    c = mix(vec3(0.7, 0.0, 0.0), vec3(1.0, 0.5, 0.0), (t - 0.25) / 0.25);
  } else if (t < 0.75) {
    // orange -> yellow
    c = mix(vec3(1.0, 0.5, 0.0), vec3(1.0, 1.0, 0.0), (t - 0.5) / 0.25);
  } else {
    // yellow -> white
    c = mix(vec3(1.0, 1.0, 0.0), vec3(1.0, 1.0, 1.0), (t - 0.75) / 0.25);
  }
  return c;
}

void main() {
  vec2 c = gl_PointCoord - 0.5;
  if (dot(c, c) > 0.25) discard;
  vec3 col = fireColor(v_colorIndex);
  gl_FragColor = vec4(col, 1.0);
}