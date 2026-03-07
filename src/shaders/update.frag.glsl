precision highp float;
varying vec2 v_uv;
uniform sampler2D u_state;
uniform sampler2D u_presence;
uniform float u_baseSpeed;
uniform vec2 u_resolution;
uniform float u_lookahead;
uniform float u_time;
uniform float u_mutationChance;

const float PI = 3.14159265359;

// Energy constants
const float BASE_DRAIN = 0.0003;
const float SPEED_COST = 0.00005;
const float SIZE_COST = 0.00003;
const float FOOD_GAIN = 0.002;
const float FOOD_THRESHOLD = 0.3;
const float COLLISION_COST = 0.01;
const float FLOCK_BONUS = 0.0002;
const float REBIRTH_ENERGY = 0.45;

float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Procedural food zones: slowly drifting patches
float foodNoise(vec2 pos, float time) {
  float n = 0.0;
  n += sin(pos.x * 3.0 + time * 0.1) * sin(pos.y * 4.0 + time * 0.15);
  n += sin(pos.x * 7.0 - time * 0.08) * sin(pos.y * 5.0 - time * 0.12) * 0.5;
  n += sin(pos.x * 13.0 + time * 0.05) * sin(pos.y * 11.0 + time * 0.07) * 0.25;
  return n;
}

// Direction index 0-7 -> movement vector
// 0=N, 1=NE, 2=E, 3=SE, 4=S, 5=SW, 6=W, 7=NW
vec2 dirVec(float dir) {
  float angle = dir * PI / 4.0;
  return vec2(sin(angle), cos(angle));
}

void main() {
  vec4 data = texture2D(u_state, v_uv);
  float x = data.r;
  float y = data.g;

  // Unpack B channel: color*8 + direction
  float packed_b = floor(data.b + 0.5);
  float color = floor(packed_b / 8.0);
  float direction = packed_b - color * 8.0;

  // Unpack A channel: integer part = size*8 + speed, fractional part = energy
  float intPart = floor(data.a);
  float energy = data.a - intPart;
  float size = floor(intPart / 8.0);
  float speed = intPart - size * 8.0;

  // === ENERGY DRAIN ===
  energy -= BASE_DRAIN;
  energy -= speed * SPEED_COST;
  energy -= size * SIZE_COST;

  // === FOOD ZONES ===
  float food = foodNoise(vec2(x, y) * 6.2832, u_time);
  if (food > FOOD_THRESHOLD) {
    energy += FOOD_GAIN;
  }

  // === MOVEMENT ===
  vec2 moveDir = dirVec(direction);
  float speedMul = 0.5 + speed / 7.0 * 1.5; // 0.5 to 2.0

  // Convert lookahead from pixels to UV space
  vec2 laUV = vec2(u_lookahead / u_resolution.x, u_lookahead / u_resolution.y);

  // Sample presence map ahead
  vec2 ahead = fract(vec2(x, y) + moveDir * laUV + 1.0);
  vec4 presAhead = texture2D(u_presence, ahead);

  bool collided = false;

  // Obstacle threshold: more than ~1 particle ahead
  if (presAhead.r > 1.5 / 64.0) {
    float dodgeChance = hash(vec2(v_uv.x, 0.123)) * 0.6;
    float dodgeRoll = hash(vec2(v_uv.x, u_time));

    if (dodgeRoll < dodgeChance) {
      float sideRoll = hash(vec2(v_uv.x, u_time * 2.0));
      float dodgeDir = sideRoll < 0.5
        ? mod(direction + 2.0, 8.0)
        : mod(direction + 6.0, 8.0);

      vec2 dodgeMoveDir = dirVec(dodgeDir);
      vec2 dodgeAhead = fract(vec2(x, y) + dodgeMoveDir * laUV + 1.0);
      vec4 presDodge = texture2D(u_presence, dodgeAhead);

      if (presDodge.r < 1.5 / 64.0) {
        x += dodgeMoveDir.x * u_baseSpeed * speedMul;
        y += dodgeMoveDir.y * u_baseSpeed * speedMul;
      } else {
        collided = true;
        x += moveDir.x * u_baseSpeed * speedMul;
        y += moveDir.y * u_baseSpeed * speedMul;
      }
    } else {
      collided = true;
      x += moveDir.x * u_baseSpeed * speedMul;
      y += moveDir.y * u_baseSpeed * speedMul;
    }
  } else {
    x += moveDir.x * u_baseSpeed * speedMul;
    y += moveDir.y * u_baseSpeed * speedMul;
  }

  // Toroidal wrapping
  x = fract(x + 1.0);
  y = fract(y + 1.0);

  // === COLLISION EFFECTS ===
  if (collided) {
    // Energy cost from collision
    energy -= COLLISION_COST;

    // Mutation on collision (existing mechanic)
    float mutRoll = hash(vec2(v_uv.x, u_time * 3.0 + 0.5));
    if (mutRoll < u_mutationChance) {
      if (presAhead.r > 0.5 / 64.0) {
        float avgColor = clamp(presAhead.g * 16.0 / presAhead.r - 0.5, 0.0, 15.0);
        float avgSize  = clamp(presAhead.b * 8.0 / presAhead.r - 0.5, 0.0, 7.0);
        float avgSpeed = clamp(presAhead.a * 8.0 / presAhead.r - 0.5, 0.0, 7.0);

        float mixF1 = hash(vec2(v_uv.x, u_time * 4.0));
        float mixF2 = hash(vec2(v_uv.x, u_time * 5.0));
        float mixF3 = hash(vec2(v_uv.x, u_time * 6.0));

        color = floor(clamp(mix(color, avgColor, mixF1) + 0.5, 0.0, 15.0));
        size  = floor(clamp(mix(size, avgSize, mixF2) + 0.5, 0.0, 7.0));
        speed = floor(clamp(mix(speed, avgSpeed, mixF3) + 0.5, 0.0, 7.0));

        direction = floor(hash(vec2(v_uv.x, u_time * 7.0)) * 8.0);
        direction = clamp(direction, 0.0, 7.0);
      }
    }
  }

  // === FLOCKING BONUS ===
  // Sample presence at current position for neighbor info
  vec4 presHere = texture2D(u_presence, vec2(x, y));
  if (presHere.r > 0.5 / 64.0) {
    float avgColorHere = presHere.g * 16.0 / presHere.r - 0.5;
    // Bonus if surrounded by similar color
    float colorDist = abs(color - avgColorHere);
    if (colorDist < 3.0) {
      energy += FLOCK_BONUS * (3.0 - colorDist) / 3.0;
    }
  }

  // === DEATH & REBIRTH ===
  if (energy <= 0.0) {
    // Sample 4 random particles, find highest-energy parent
    float r0 = hash(vec2(v_uv.x, u_time * 10.0 + 0.1));
    float r1 = hash(vec2(v_uv.x, u_time * 10.0 + 0.2));
    float r2 = hash(vec2(v_uv.x, u_time * 10.0 + 0.3));
    float r3 = hash(vec2(v_uv.x, u_time * 10.0 + 0.4));

    vec4 c0 = texture2D(u_state, vec2(r0, 0.5));
    vec4 c1 = texture2D(u_state, vec2(r1, 0.5));
    vec4 c2 = texture2D(u_state, vec2(r2, 0.5));
    vec4 c3 = texture2D(u_state, vec2(r3, 0.5));

    // Extract energy (fractional part of A channel)
    float e0 = c0.a - floor(c0.a);
    float e1 = c1.a - floor(c1.a);
    float e2 = c2.a - floor(c2.a);
    float e3 = c3.a - floor(c3.a);

    // Pick the parent with highest energy
    vec4 parent = c0;
    float bestE = e0;
    if (e1 > bestE) { parent = c1; bestE = e1; }
    if (e2 > bestE) { parent = c2; bestE = e2; }
    if (e3 > bestE) { parent = c3; bestE = e3; }

    // Unpack parent genes
    float pB = floor(parent.b + 0.5);
    float pColor = floor(pB / 8.0);
    float pDir = pB - pColor * 8.0;
    float pIntA = floor(parent.a);
    float pSize = floor(pIntA / 8.0);
    float pSpeed = pIntA - pSize * 8.0;

    // Clone with small mutations (±1)
    float m1 = hash(vec2(v_uv.x, u_time * 11.0));
    float m2 = hash(vec2(v_uv.x, u_time * 12.0));
    float m3 = hash(vec2(v_uv.x, u_time * 13.0));
    float m4 = hash(vec2(v_uv.x, u_time * 14.0));
    float m5 = hash(vec2(v_uv.x, u_time * 15.0));

    color = clamp(pColor + (m1 < 0.33 ? -1.0 : (m1 > 0.66 ? 1.0 : 0.0)), 0.0, 15.0);
    direction = mod(pDir + (m2 < 0.33 ? -1.0 : (m2 > 0.66 ? 1.0 : 0.0)) + 8.0, 8.0);
    size = clamp(pSize + (m3 < 0.33 ? -1.0 : (m3 > 0.66 ? 1.0 : 0.0)), 0.0, 7.0);
    speed = clamp(pSpeed + (m4 < 0.33 ? -1.0 : (m4 > 0.66 ? 1.0 : 0.0)), 0.0, 7.0);

    // Respawn at random position
    x = hash(vec2(v_uv.x, u_time * 16.0));
    y = hash(vec2(v_uv.x, u_time * 17.0));

    energy = REBIRTH_ENERGY;
  }

  // Clamp energy
  energy = clamp(energy, 0.0, 0.9);

  // Re-pack
  float new_b = color * 8.0 + direction;
  float new_a = floor(size * 8.0 + speed) + energy;

  gl_FragColor = vec4(x, y, new_b, new_a);
}
