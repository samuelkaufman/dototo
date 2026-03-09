precision mediump float;
varying float v_colorIndex;
varying float v_energy;

// HSV to RGB conversion
vec3 hsv2rgb(vec3 c) {
  vec3 p = abs(fract(c.xxx + vec3(0.0, 2.0/3.0, 1.0/3.0)) * 6.0 - 3.0);
  return c.z * mix(vec3(1.0), clamp(p - 1.0, 0.0, 1.0), c.y);
}

vec3 spectrumColor(float index) {
  // 16 distinct hues spread across the full spectrum
  // Slight saturation and value variation to keep things vivid
  float hue = index / 16.0;
  float sat = 0.75 + 0.25 * fract(index * 0.618); // 0.75-1.0
  return hsv2rgb(vec3(hue, sat, 1.0));
}

void main() {
  vec2 c = gl_PointCoord - 0.5;
  if (dot(c, c) > 0.25) discard;
  vec3 col = spectrumColor(v_colorIndex);
  // Energy scales brightness: dim when starving, bright when thriving
  float brightness = 0.15 + 0.85 * clamp(v_energy / 0.9, 0.0, 1.0);
  gl_FragColor = vec4(col * brightness, 1.0);
}
