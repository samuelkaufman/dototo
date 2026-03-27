precision mediump float;
varying float v_colorIndex;
varying float v_energy;
uniform float u_time;
varying float v_speed;

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
float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void main() {
  vec2 c = gl_PointCoord - .5;
//   float dist = length(c);

// float radius = 10.0;
// float edge = 2.0;   // softness amount

//   float alpha = 1.0 - smoothstep(radius - edge, radius, dist);
  if (dot(c, c) > 0.25) discard;
  vec3 col = spectrumColor(v_colorIndex);
  // float brightness = 0.15 + 0.85 * clamp(v_energy / 0.9, 0.0, 1.0);
  // float dodgeRoll = hash(vec2(gl_Position[0], u_time));
  // // float brightness = 1.0;
  // float brightness =dodgeRoll; // 0.5 to 1.0 based on hash
  // float brightness = 50.0;
  float brightness = 0.3 + 0.7 * clamp(v_speed / 7.0, 0.0, 1.0); // 0.3 to 1.0 based on speed (0-7)
  // float brightness = 0.3 + 0.7 * hash(vec2(v_colorIndex, floor(u_time * 2.0)));
  // float brightness = hash(vec2(gl_PointCoord.s * gl_PointCoord.t, u_time))/2.0; // 0.25 at edges, 1.0 at center
  gl_FragColor = vec4(col * brightness, 1.0);
  // gl_FragColor = vec4(col * (v_speed/2.0), 1.0);
  // gl_FragColor.a = .001;
  // gl_FragColor = vec4(col * brightness, 1.0);
}
