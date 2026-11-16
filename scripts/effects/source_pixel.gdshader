shader_type canvas_item;
// Supplied PNGs retain their original soft/noisy alpha. Clean only at render time.
uniform float alpha_cutoff : hint_range(0.0, 1.0) = 0.5;
void fragment() {
 vec4 pixel = texture(TEXTURE, UV);
 if (pixel.a < alpha_cutoff) { discard; }
 COLOR = vec4(pixel.rgb, 1.0);
}
