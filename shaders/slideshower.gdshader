shader_type spatial;
render_mode unshaded;
render_mode depth_prepass_alpha;

uniform sampler2D tex;
uniform ivec2 sprite_size = ivec2(64, 64);
uniform ivec2 sprite_spacing;
uniform ivec2 sprites = ivec2(4, 4);
uniform int directions: hint_range(1, 8, 1) = 1;
uniform int[8] sequence_start;
uniform int[8] sequence_length;
uniform bool billboard = true;

uniform float animation_speed : hint_range(0.0, 5.0, 0.1) = 1.0;
instance uniform float offset : hint_range(-1.0, 1.0, 0.01) = 0.0;

varying vec2 sprite_starts;
varying vec2 tex_size;

void vertex() {
    if (billboard) {
        MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
    }

    // Figure out what direction
    vec3 norm = MODELVIEW_NORMAL_MATRIX * NORMAL;

    int direction = 0;
    if (directions == 2) {
        // FRONT: 0
        // BACK: 1
        direction = sign(norm.z) > 0.0 ? 0 : 1;
    } else if (directions == 4) {
        // FRONT: 0
        // RIGHT: 1
        // BACK: 2
        // LEFT: 3
        if (abs(norm.z) > abs(norm.x)) {
            direction = sign(norm.z) > 0.0 ? 0 : 2;
        } else {
            direction = sign(norm.x) > 0.0 ? 3 : 1;
        }
    } else if (directions == 8) {
        // FRONT: 0
        // FR-R: 1
        // RIGHT: 2
        // BA-R: 3
        // BACK: 4
        // ...
        float x = abs(norm.x);
        float z = abs(norm.z);
        float sx = sign(norm.x);
        float sz = sign(norm.z);

        if (z > x) {
            if (x == 0.0 || z / x > 2.0) {
                direction = sz > 0.0 ? 0 : 4;
            } else if (sx > 0.0) {
                direction = sz > 0.0 ? 7 : 5;
            } else {
                direction = sz > 0.0 ? 1 : 3;
            }
        } else {
            if (z == 0.0 || x / z > 2.0) {
                direction = sx > 0.0 ? 6 : 2;
            } else if (sz > 0.0) {
                direction = sx > 0.0 ? 7 : 1;
            } else {
                direction = sx > 0.0 ? 5 : 3;
            }
        }
    }

    // Transport needed information to the fragment shader only when we have a supported number of directions
    if (directions == 1 || directions == 2 || directions == 4 || directions == 8) {
        tex_size = vec2(textureSize(tex, 0));
         // Figure out what sprite we should use
        int sprite_idx = sequence_start[direction] + (int(round((TIME + (offset * animation_speed)) / animation_speed)) % max(1, sequence_length[direction]));
        vec2 sprite_offset = vec2(float(sprite_idx % sprites.x), float(sprite_idx / sprites.x));

        // Scale the UV
        //sprite_starts = 1.0 / (vec2(sprites) + vec2(sprites - 1) * vec2(sprite_spacing) / vec2(sprite_size));
        sprite_starts = (sprite_offset * vec2(sprite_size) + vec2(sprite_spacing) * sprite_offset) / tex_size;
    } else {
        sprite_starts = vec2(0.0);
        tex_size = vec2(1.1);
    }
}

void fragment() {
    vec4 color = texture(tex, UV * vec2(sprite_size) / vec2(tex_size) + sprite_starts);
    ALBEDO = color.rgb;
    ALPHA = color.a;
}