shader_type canvas_item;

uniform sampler2D OverlayEffect : hint_roughness_r, repeat_disable;
uniform sampler2D TintGradient : source_color, repeat_disable;

uniform float EffectStrength : hint_range(0.0, 3.0);
uniform float TextureEffect : hint_range(0.0, 1.0) = 0.8;

uniform float Feather = 1.0;
uniform float MinRadius = 0.815;
uniform float MaxRadius = 0.0;

uniform float PulseSpeed = 3.0;
uniform float PulsePower = 0.2;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

void fragment() {
	if (EffectStrength == 0.0){
		discard;
	}
	
	vec3 color = textureLod(screen_texture,SCREEN_UV,0.0).rgb;
	
	vec2 adjustedUV = SCREEN_UV * 2.0 - 1.0;
	float circle = length(adjustedUV);
	float effectBlend = clamp(EffectStrength / 3.0, 0.0, 1.0);
	float currentRadius = mix(MinRadius, MaxRadius, effectBlend);
	float mask = 1.0 - smoothstep(currentRadius, currentRadius + Feather, circle);
	
	float hardCutoff = clamp(EffectStrength, 0, 1);
	float averageValue = (color.r + color.g + color.b) / 3.0;
	
	vec3 currentTint = texture(TintGradient, vec2(effectBlend, 0.5)).rgb;
	currentTint *= averageValue;
	
	float overlayTextureValue = texture(OverlayEffect, SCREEN_UV).r;
	mask = mask * (1.0 + (sin(TIME * PulseSpeed) * PulsePower));
	overlayTextureValue = mix(mask, mask * overlayTextureValue, TextureEffect);
	
	vec3 currentOverlayColor = mix(currentTint, color, overlayTextureValue);
	COLOR = vec4(mix(color, currentOverlayColor, hardCutoff), 1.0);
}