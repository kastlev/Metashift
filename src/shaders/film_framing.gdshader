shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

group_uniforms Preset_Framing;
uniform int ratio_preset : hint_enum(
    "Manual",
    "Square ( 1  | 1 )",
    "Lighthouse ( 1.19  | 1 )",
    "Flicker ( 1.33  | 1 )",
    "Academy ( 1.37  | 1 )",
    "Euro ( 1.66  | 1 )",
    "US ( 1.85  | 1 )",
    "CinemaScope ( 2.35  | 1 )",
    "Panavision ( 2.39  | 1 )",
    "Polyvision ( 4.0  | 1 )"
) = 0; 
/** Preset index that selects a target aspect ratio (or Manual) to automatically calculate letterbox/pillarbox framing. */

group_uniforms Manual_Adjustments;
/** Toggles visibility of the framing bars (letterboxing/pillarboxing). */
uniform bool frame_visible = true; 
/** Solid color used for the framing bars when they are visible. */
uniform vec4 frame_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
/** Manual fractional height of the top framing bar (used directly when ratio_preset is Manual). */ 
uniform float top_bar    : hint_range(0.0, 0.5, 0.001) = 0.0; 
/** Manual fractional height of the bottom framing bar (used directly when ratio_preset is Manual). */
uniform float bottom_bar : hint_range(0.0, 0.5, 0.001) = 0.0; 
/** Manual fractional width of the left framing bar (used directly when ratio_preset is Manual). */
uniform float left_bar   : hint_range(0.0, 0.5, 0.001) = 0.0; 
/** Manual fractional width of the right framing bar (used directly when ratio_preset is Manual). */
uniform float right_bar  : hint_range(0.0, 0.5, 0.001) = 0.0; 

group_uniforms Vignette;
/** Toggles the vignette darkening effect applied to the image. */
uniform bool vignette_on = true;
/** When true the vignette automatically adapts to the framed image area (recommended).  
    When false it uses the old full-screen behaviour. */
uniform bool adaptive_vignette = true;
/** Controls how far the vignette extends from the edges toward the center. */
uniform float vignette_intensity : hint_range(0.0, 1.0, 0.001) = 0.5;
/** Controls the overall strength of the vignette color blend. */ 
uniform float vignette_opacity   : hint_range(0.0, 1.0, 0.001) = 0.5; 
/** Color overlaid by the vignette effect (typically black). */
uniform vec4 vignette_color      : source_color = vec4(0.0, 0.0, 0.0, 1.0);
/** Normalized coordinates of the vignette center *relative to the framed image area* (0.5, 0.5 = center of the visible picture). */ 
uniform vec2 vignette_center     = vec2(0.5, 0.5); 

group_uniforms Dynamic_Camera;
/** Toggles dynamic camera simulation (gate weave + handheld shake) applied only to the image UV. */
uniform bool dynamic_on = false; 

/** Gate weave style: A = Simplified wave (original), B = discrete random pulse per film frame. */
uniform int gate_weave_style : hint_enum("A - Simplified", "B - Developed") = 0;
/** Frequency of the gate weave oscillation (only used when A - Simplified is selected). */
uniform float gate_weave_speed  : hint_range(0.0, 50.0, 0.1) = 15.0; 
/** Intensity of the vertical film-gate weave jitter (UV offset, works in both styles). */
uniform float gate_weave_amount : hint_range(0.0, 0.05, 0.0001) = 0.002; 
/** Simulated film frame rate used only when B - Developed is selected. */
uniform float film_fps : hint_range(1.0, 120.0, 0.1) = 24.0; 

/** Additional intensity modulation for the discrete gate weave pulse (makes option B feel more mechanical). */
uniform float pulse_intensity : hint_range(0.0, 2.0, 0.01) = 0.22;
/** Rate at which the gate-weave pulse intensity changes (multiplier of film_fps). Randomised via hash. */
uniform float pulse_rate : hint_range(0.2, 1.0, 0.05) = 0.5; 

/** Brightness flicker intensity for the old projector lamp effect (only in style B). */
uniform float projector_flicker_intensity : hint_range(0.0, 0.3, 0.001) = 0.08;
/** Rate at which the projector lamp brightness pulses (multiplier of film_fps). Fully randomised. */
uniform float projector_flicker_rate : hint_range(0.2, 2.0, 0.05) = 1.0; 

/** Frequency of the handheld camera shake motion. */
uniform float handheld_shake_speed  : hint_range(0.0, 5.0, 0.1) = 1.0; 
/** Intensity of the handheld camera shake motion. */
uniform float handheld_shake_amount : hint_range(0.0, 0.1, 0.001) = 0.005; 

float hash(float n) { return fract(sin(n) * 43758.5453123); }

void fragment() {
    // Fixed UV for bars + vignette
    vec2 uv_mask  = SCREEN_UV;
    // Drifting UV for the image
    vec2 uv_image = SCREEN_UV;

    // --- Dynamic Camera (image only) ---
    if (dynamic_on) {
        float jitter;
        if (gate_weave_style == 0) {          // A - Simplified
            jitter = sin(TIME * gate_weave_speed)
                   * gate_weave_amount
                   * hash(floor(TIME * 20.0));
        } else {                              // B - Developed (gate weave + mechanical pulse)
            float frame_index = floor(TIME * film_fps);
            float base_jitter = (hash(frame_index) * 2.0 - 1.0) * gate_weave_amount;

            // Gate-weave strength pulse
            float pulse_index = floor(TIME * film_fps * pulse_rate);
            float pulse = 1.0 + (hash(pulse_index) * 2.0 - 1.0) * pulse_intensity;

            jitter = base_jitter * pulse;
        }

        vec2 sway = vec2(
            sin(TIME * handheld_shake_speed * 0.7),
            cos(TIME * handheld_shake_speed * 1.3)
        ) * handheld_shake_amount;

        uv_image += vec2(sway.x, jitter + sway.y);
    }

    uv_image = clamp(uv_image, 0.0, 1.0);

    // --- Aspect Ratio / Framing (uses uv_mask) ---
    vec2 screen_res = 1.0 / SCREEN_PIXEL_SIZE;
    float screen_aspect = screen_res.x / screen_res.y;

    float target_ratio = 0.0;
    if      (ratio_preset == 1) target_ratio = 1.0;
    else if (ratio_preset == 2) target_ratio = 1.19;
    else if (ratio_preset == 3) target_ratio = 1.33;
    else if (ratio_preset == 4) target_ratio = 1.37;
    else if (ratio_preset == 5) target_ratio = 1.66;
    else if (ratio_preset == 6) target_ratio = 1.85;
    else if (ratio_preset == 7) target_ratio = 2.35;
    else if (ratio_preset == 8) target_ratio = 2.39;
    else if (ratio_preset == 9) target_ratio = 4.00;

    float f_top = top_bar;
    float f_bot = bottom_bar;
    float f_l   = left_bar;
    float f_r   = right_bar;

    if (target_ratio > 0.0) {
        if (screen_aspect > target_ratio) {
            float inset = (1.0 - (target_ratio / screen_aspect)) * 0.5;
            f_l = inset; f_r = inset;
        } else {
            float inset = (1.0 - (screen_aspect / target_ratio)) * 0.5;
            f_top = inset; f_bot = inset;
        }
    }

    bool is_framed =
        (uv_mask.y < f_top) || (uv_mask.y > 1.0 - f_bot) ||
        (uv_mask.x < f_l)   || (uv_mask.x > 1.0 - f_r);

    // --- Sample drifting image ---
    vec4 tex = texture(screen_texture, uv_image);
    vec3 final_rgb = tex.rgb;

    // --- Vignette (adapts to framed area when adaptive_vignette is true) ---
    if (vignette_on) {
        if (adaptive_vignette && !is_framed) {
            // Adaptive vignette (bias-free, equal on all sides)
            float visible_w = 1.0 - f_l - f_r + 0.000001;
            float visible_h = 1.0 - f_top - f_bot + 0.000001;
            vec2 image_uv = vec2(
                (uv_mask.x - f_l) / visible_w,
                (uv_mask.y - f_top) / visible_h
            );

            vec2 vignette_uv = image_uv - vignette_center;

            float image_aspect = screen_aspect * visible_w / visible_h;
            float max_dist = 0.5 * sqrt(image_aspect * image_aspect + 1.0);
            vec2 aspect_uv = (vignette_uv * vec2(image_aspect, 1.0)) / max_dist;

            float dist = length(aspect_uv);
            float v_grad = smoothstep(0.8 - vignette_intensity, 1.0, dist);
            final_rgb = mix(final_rgb, vignette_color.rgb, v_grad * vignette_opacity);
        } 
        else {
            // Old full-screen vignette (fallback)
            vec2 aspect_uv = (uv_mask - vignette_center) * vec2(screen_aspect, 1.0);
            float dist = length(aspect_uv);
            float v_grad = smoothstep(0.8 - vignette_intensity, 1.0, dist);
            final_rgb = mix(final_rgb, vignette_color.rgb, v_grad * vignette_opacity);
        }
    }

    // === Projector lamp brightness flicker (only in style B) ===
    if (dynamic_on && gate_weave_style == 1) {
        float flicker_index = floor(TIME * film_fps * projector_flicker_rate);
        float flicker = 1.0 + (hash(flicker_index) * 2.0 - 1.0) * projector_flicker_intensity;
        final_rgb *= flicker;
    }

    // --- Output with bar visibility toggle ---
    if (frame_visible && is_framed) {
        COLOR = frame_color;
    } else {
        COLOR = vec4(final_rgb, tex.a);
    }
}