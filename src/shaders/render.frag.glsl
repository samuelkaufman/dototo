precision mediump float;
varying float v_colorIndex;

vec3 palette(float index) {
  float t = index / 15.0;
  vec3 c;
  if (t < 0.25) {
    // deep blue -> electric blue
    c = mix(vec3(0.15, 0.08, 0.4), vec3(0.1, 0.3, 0.9), t / 0.25);
  } else if (t < 0.5) {
    // electric blue -> purple
    c = mix(vec3(0.1, 0.3, 0.9), vec3(0.5, 0.1, 0.8), (t - 0.25) / 0.25);
  } else if (t < 0.75) {
    // purple -> hot pink
    c = mix(vec3(0.5, 0.1, 0.8), vec3(1.0, 0.2, 0.6), (t - 0.5) / 0.25);
  } else {
    // hot pink -> soft pink/white
    c = mix(vec3(1.0, 0.2, 0.6), vec3(1.0, 0.7, 0.9), (t - 0.75) / 0.25);
  }
  return c;
}

void main() {
  vec2 c = gl_PointCoord - 0.5;
  if (dot(c, c) > 0.25) discard;
  vec3 col = palette(v_colorIndex);
  gl_FragColor = vec4(col, 1.0);
}