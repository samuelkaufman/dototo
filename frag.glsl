
// =================== PASS 1: PRESENCE MAP ===================
// Renders particles into a screen-sized texture.
// R = red particle present, G = blue particle present.

// const presenceVS
attribute float a_index;
uniform sampler2D u_state;
uniform float u_count;
varying float v_color;

float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void main() {
  float u = (a_index + 0.5) / u_count;
  vec4 data = texture2D(u_state, vec2(u, 0.5));
  float x = data.r * 2.0 - 1.0;
  float y = data.g * 2.0 - 1.0;
  v_color = data.b;
  float size = 1.0 + hash(vec2(u, 0.7)) * 3.0; // 1–8 per particle
  gl_Position = vec4(x, y, 0.0, 1.0);
  gl_PointSize = size + 4.0;
}

// const presenceFS = `
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
//`;


// =================== PASS 2: UPDATE ===================
// Reads state + presence. Looks ahead for collisions.

// const updateVS = `
attribute vec2 a_pos;
varying vec2 v_uv;
void main() {
  v_uv = a_pos * 0.5 + 0.5;
  gl_Position = vec4(a_pos, 0.0, 1.0);
}
//`;

// const updateFS = `
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
  float speedMul = data.a*.1;

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
    obstacle = max(p1.g + p1.r * 0.9, p2.g + p2.r * 1.5);
  } else {
    // Blue: dodge both red and blue
    obstacle = max(p1.r + p1.g * 0.9, p2.r + p2.g * 0.9);
  }

  // Always move horizontally (scaled by per-particle speed)

  // If obstacle ahead, also move vertically
  if (obstacle > 1.1) {
    float dirY = color > 0.5 ? 1.0 : -1.0;
    // Per-particle dodge chance (0–40%), fixed for the particle's lifetime
    float dodgeChance = hash(vec2(v_uv.x, 0.0)) * .9;
    // Roll each frame to decide whether to flip
    float r = hash(vec2(v_uv.x, u_time));
    if (r < dodgeChance) dirY = -dirY;
    y += dirY * u_vspeed * speedMul;
    y = fract(y + 1.0);
  } else {
    x += dirX * u_speed * speedMul;
    x = fract(x + 1.0);
}

gl_FragColor = vec4(x, y, color, 1);
// gl_FragColor = vec4(x, y, color, speedMul);
	}
    //`;

	// =================== PASS 3: RENDER ===================

//	const renderVS = `
attribute float a_index;
uniform sampler2D u_state;
uniform float u_count;
varying float v_color;
varying float v_alpha;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void main() {
    float u = (a_index + 0.5) / u_count;
    vec4 data = texture2D(u_state, vec2(u, 0.5));
    float x = data.r * 2.0 - 1.0;
    float y = data.g * 2.0 - 1.0;
    v_color = data.b;
    v_alpha = data.a;
    float size = 1.0 + hash(vec2(u, 0.7)) * 30.0; // 1–8 per particle
    gl_Position = vec4(x, y, 0.0, 1.0);
    gl_PointSize = size;
}
// `;

// const renderFS = `
precision mediump float;
varying float v_color;
varying float v_alpha;
void main() {
    vec2 c = gl_PointCoord - 0.5;
    if (dot(c, c) > 0.25) discard;
    if (v_color > 0.5) {
    gl_FragColor = vec4(1, 0.04, 0.00, 1);
    } else {
    gl_FragColor = vec4(0.6, 0.8, 1.0, 1);
    }
}
//`;