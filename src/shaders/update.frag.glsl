precision highp float;
varying vec2 v_uv;
uniform sampler2D u_state;
uniform sampler2D u_presence;
uniform float u_baseSpeed;
uniform vec2 u_resolution;
uniform float u_lookahead;
uniform float u_time;
uniform float u_mutationChance;
uniform float u_collisionThresh;

const float PI = 3.14159265359;


float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}


// Direction index 0-15 -> movement vector (22.5° steps)
vec2 dirVec(float dir) {
  float angle = dir * PI / 8.0;
  return vec2(sin(angle), cos(angle));
}

void main() {
  vec4 data = texture2D(u_state, v_uv);
  float x = data.r;
  float y = data.g;

  // Unpack B channel: color*16 + direction
  float packed_b = floor(data.b + 0.5);
  float color = floor(packed_b / 16.0);
  float direction = packed_b - color * 16.0;

  // Unpack A channel: integer part = size*8 + speed, fractional part = energy
  float intPart = floor(data.a);
  float size = floor(intPart / 8.0);
  float speed = (intPart - size * 8.0)+.2;

  // === MOVEMENT ===
  vec2 moveDir = dirVec(direction);
  float speedMul = speed; // 0.5 to 2.0

  // Convert lookahead from pixels to UV space
  vec2 laUV = vec2(u_lookahead / u_resolution.x, u_lookahead / u_resolution.y);

  // Sample presence map ahead
  vec2 ahead = fract(vec2(x, y) + moveDir * laUV + 1.0);
  vec4 presAhead = texture2D(u_presence, ahead);

  bool collided = false;

  // Obstacle threshold: more than ~1 particle ahead
  if (presAhead.r > u_collisionThresh) {
    float dodgeChance = hash(vec2(v_uv.x, 0.123)) * 0.6;
    float dodgeRoll = hash(vec2(v_uv.x, u_time));

    if (dodgeRoll < dodgeChance) {
      float sideRoll = hash(vec2(v_uv.x, u_time * 2.0));
      float dodgeDir = sideRoll < 0.5
        ? mod(direction + 4.0, 16.0)
        : mod(direction + 12.0, 16.0);

      vec2 dodgeMoveDir = dirVec(dodgeDir);
      vec2 dodgeAhead = fract(vec2(x, y) + dodgeMoveDir * laUV + 1.0);
      vec4 presDodge = texture2D(u_presence, dodgeAhead);

      if (presDodge.r < 1.0 / 64.0) {
        x += dodgeMoveDir.x * u_baseSpeed * speedMul;
        y += dodgeMoveDir.y * u_baseSpeed * speedMul;
      } else {
        collided = true;
        // x += moveDir.x * u_baseSpeed * speedMul;
        // y += moveDir.y * u_baseSpeed * speedMul;
      }
    } else {
      collided = true;
      // x += moveDir.x * u_baseSpeed * speedMul;
      // y += moveDir.y * u_baseSpeed * speedMul;
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

    // Mutation on collision (existing mechanic)
  }

  // === FLOCKING BONUS ===
  // Sample presence at current position for neighbor info



  // Re-pack
  float new_b = color * 16.0 + direction;
  float new_a = floor(size * 8.0 + speed);

  gl_FragColor = vec4(x, y, new_b, new_a);
}
