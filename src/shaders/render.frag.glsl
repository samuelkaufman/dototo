precision mediump float;
varying float v_colorIndex;
varying float v_speed;
uniform float u_grayscale;
uniform float u_hueShift;

vec3 hsv2rgb(vec3 c) {
  vec3 p = abs(fract(c.xxx + vec3(0.0, 2.0/3.0, 1.0/3.0)) * 6.0 - 3.0);
  return c.z * mix(vec3(1.0), clamp(p - 1.0, 0.0, 1.0), c.y);
}

vec3 paletteColor(float index, float val) {
  // Golden ratio hue steps — maximally perceptually distinct colors
  float hue = fract(index * 0.618033988 + u_hueShift);
  // Full saturation always; brightness lives in HSV value so hue stays pure
  return hsv2rgb(vec3(hue, 1.0, val));
}

void main() {
  vec2 c = gl_PointCoord - 0.5;
  if (dot(c, c) > 0.25) discard;

  // 0.5–1.0 range: even the slowest particles are half-bright, not muddy
  float val = 0.5 + 0.5 * clamp(v_speed / 7.0, 0.0, 1.0);

  vec3 col;
  if (u_grayscale > 0.5) {
    col = vec3(val);
  } else {
    col = paletteColor(v_colorIndex, val);
  }

  gl_FragColor = vec4(col, 1.0);
}
