precision highp float;
varying vec2 v_uv;
uniform sampler2D u_state;
uniform sampler2D u_presence;
uniform float u_speed;
uniform float u_vspeed;
uniform vec2 u_resolution;
uniform float u_lookahead;
uniform float u_time;

float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void main() {
  vec4 data = texture2D(u_state, v_uv);
  float x = data.r;
  float y = data.g;
  float color = data.b;
  float speedMul = data.a;

  float dirX = color > 0.5 ? 1.0 : -1.0;

  // Convert lookahead from pixels to UV space
  float laU = u_lookahead / u_resolution.x;

  // Sample presence texture ahead of this particle
  // Check a couple points ahead for robustness
  vec2 ahead1 = vec2(fract(x + dirX * laU * 0.5 + 1.0), y);
  vec2 ahead2 = vec2(fract(x + dirX * laU + 1.0), y);
  vec4 p1 = texture2D(u_presence, ahead1);
  vec4 p2 = texture2D(u_presence, ahead2);

  // Detect obstacle: any particle presence ahead
  float obstacle = 0.0;
  if (color > 0.5) {
    // Red: dodge both blue and red
    obstacle = max(p1.g + p1.r * 0.9, p2.g + p2.r * 0.9);
  } else {
    // Blue: dodge both red and blue
    obstacle = max(p1.r + p1.g * 0.9, p2.r + p2.g * 0.9);
  }

  // Always move horizontally (scaled by per-particle speed)

  // If obstacle ahead, also move vertically
  if (obstacle > 1.1) {
    float dirY = color > 0.5 ? 1.0 : -1.0;
    // Per-particle dodge chance (0–40%), fixed for the particle's lifetime
    float dodgeChance = hash(vec2(v_uv.x, 0.0)) * 0.4;
    // Roll each frame to decide whether to flip
    float r = hash(vec2(v_uv.x, u_time));
    if (r < dodgeChance) dirY = -dirY;
    y += dirY * u_vspeed * speedMul;
    y = fract(y + 1.0);
  } else {
    x += dirX * u_speed * speedMul;
	  x = fract(x + 1.0);
}

  gl_FragColor = vec4(x, y, color, speedMul);
}