precision highp float;
varying vec2 v_uv;
uniform sampler2D u_state;
uniform sampler2D u_presence;
uniform float u_baseSpeed;
uniform vec2 u_resolution;
uniform float u_lookahead;
uniform float u_time;
uniform float u_mutationChance;
uniform float u_wildMutationChance;

const float PI = 3.14159265359;

float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
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

  // Unpack A channel: size*8 + speed
  float packed_a = floor(data.a + 0.5);
  float size = floor(packed_a / 8.0);
  float speed = packed_a - size * 8.0;

  // Movement
  vec2 moveDir = dirVec(direction);
  float speedMul = 0.5 + speed / 7.0 * 1.5; // 0.5 to 2.0

  // Convert lookahead from pixels to UV space
  vec2 laUV = vec2(u_lookahead / u_resolution.x, u_lookahead / u_resolution.y);

  // Sample presence map ahead (for dodging) and at current position (for collision)
  vec2 ahead = fract(vec2(x, y) + moveDir * laUV + 1.0);
  vec4 presAhead = texture2D(u_presence, ahead);
  vec4 presHere = texture2D(u_presence, vec2(x, y));

  // Obstacle threshold: more than ~1 particle ahead
  bool obstacleAhead = presAhead.r > 1.5 / 64.0;

  if (obstacleAhead) {
    // Per-particle dodge chance (fixed for lifetime, 50-95%)
    float dodgeChance = 0.5 + hash(vec2(v_uv.x, 0.123)) * 0.45;
    float dodgeRoll = hash(vec2(v_uv.x, u_time));

    if (dodgeRoll < dodgeChance) {
      // Dodge: move perpendicular (+90 or -90 degrees)
      float sideRoll = hash(vec2(v_uv.x, u_time * 2.0));
      float dodgeDir = sideRoll < 0.5
        ? mod(direction + 2.0, 8.0)
        : mod(direction + 6.0, 8.0);

      vec2 dodgeMoveDir = dirVec(dodgeDir);
      x += dodgeMoveDir.x * u_baseSpeed * speedMul;
      y += dodgeMoveDir.y * u_baseSpeed * speedMul;
    } else {
      // Failed to dodge: move forward into obstacle
      x += moveDir.x * u_baseSpeed * speedMul;
      y += moveDir.y * u_baseSpeed * speedMul;
    }
  } else {
    // No obstacle: move forward
    x += moveDir.x * u_baseSpeed * speedMul;
    y += moveDir.y * u_baseSpeed * speedMul;
  }

  // Toroidal wrapping
  x = fract(x + 1.0);
  y = fract(y + 1.0);

  // Collision = particles actually overlapping at current position (>3 particles here)
  // This is separate from dodging — only mutate when truly on top of each other
  bool collided = presHere.r > 3.5 / 64.0;

  if (collided) {
    float mutRoll = hash(vec2(v_uv.x, u_time * 3.0 + 0.5));
    if (mutRoll < u_mutationChance) {
      // Recover average attributes from presence at current position
      float avgColor = clamp(presHere.g * 16.0 / presHere.r - 0.5, 0.0, 15.0);
      float avgSize  = clamp(presHere.b * 8.0 / presHere.r - 0.5, 0.0, 7.0);
      float avgSpeed = clamp(presHere.a * 8.0 / presHere.r - 0.5, 0.0, 7.0);

      // Random interpolation between own and average
      float mixF1 = hash(vec2(v_uv.x, u_time * 4.0));
      float mixF2 = hash(vec2(v_uv.x, u_time * 5.0));
      float mixF3 = hash(vec2(v_uv.x, u_time * 6.0));

      color = floor(clamp(mix(color, avgColor, mixF1) + 0.5, 0.0, 15.0));
      size  = floor(clamp(mix(size, avgSize, mixF2) + 0.5, 0.0, 7.0));
      speed = floor(clamp(mix(speed, avgSpeed, mixF3) + 0.5, 0.0, 7.0));

      // Direction: random new value (not stored in presence map)
      direction = floor(hash(vec2(v_uv.x, u_time * 7.0)) * 8.0);
      direction = clamp(direction, 0.0, 7.0);
    } else {
      // Wild mutation: completely random attributes (introduces new diversity)
      float wildRoll = hash(vec2(v_uv.x, u_time * 8.0 + 0.7));
      if (wildRoll < u_wildMutationChance) {
        color = floor(hash(vec2(v_uv.x, u_time * 9.0)) * 16.0);
        color = clamp(color, 0.0, 15.0);
        size = floor(hash(vec2(v_uv.x, u_time * 10.0)) * 8.0);
        size = clamp(size, 0.0, 7.0);
        speed = floor(hash(vec2(v_uv.x, u_time * 11.0)) * 8.0);
        speed = clamp(speed, 0.0, 7.0);
        direction = floor(hash(vec2(v_uv.x, u_time * 12.0)) * 8.0);
        direction = clamp(direction, 0.0, 7.0);
      }
    }
  }

  // Re-pack
  float new_b = color * 8.0 + direction;
  float new_a = size * 8.0 + speed;

  gl_FragColor = vec4(x, y, new_b, new_a);
}
