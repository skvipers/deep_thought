shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// Базовые текстуры
uniform sampler2D base_texture : source_color, hint_default_white;
uniform sampler2D grass_texture : source_color, hint_default_white;
uniform sampler2D overlay1_texture : source_color, hint_default_white;
uniform sampler2D overlay2_texture : source_color, hint_default_white;

// Настройки наложения
uniform float grass_threshold : hint_range(0.0, 1.0) = 0.7;
uniform float grass_blend_strength : hint_range(0.0, 2.0) = 1.5;
uniform float grass_overlap : hint_range(0.0, 0.5) = 0.1;
uniform float overlay1_strength : hint_range(0.0, 1.0) = 0.0;
uniform float overlay2_strength : hint_range(0.0, 1.0) = 0.0;

// Направления для каждого слоя
uniform int grass_direction : hint_range(0, 5) = 0;
uniform int overlay1_direction : hint_range(0, 5) = 2;
uniform int overlay2_direction : hint_range(0, 5) = 4;

// Цветовые модификаторы
uniform vec4 base_color : source_color = vec4(1.0);
uniform vec4 grass_tint : source_color = vec4(1.0);

// Настройки материала
uniform float roughness : hint_range(0.0, 1.0) = 1.0;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float alpha_cutoff : hint_range(0.0, 1.0) = 0.5;

varying vec3 world_normal;
varying vec3 local_position;

float get_direction_factor(vec3 normal, int direction) {
	switch (direction) {
		case 0: return max(0.0, normal.y);
		case 1: return max(0.0, -normal.y);
		case 2: return max(0.0, normal.z);
		case 3: return max(0.0, -normal.z);
		case 4: return max(0.0, normal.x);
		case 5: return max(0.0, -normal.x);
		default: return 0.0;
	}
}

vec2 get_face_uv(vec3 local_pos, vec3 normal) {
	vec3 abs_normal = abs(normal);
	vec3 uv_pos = local_pos + 0.5;
	
	if (abs_normal.y > abs_normal.x && abs_normal.y > abs_normal.z) {
		return vec2(uv_pos.x, 1.0 - uv_pos.z);
	} else if (abs_normal.x > abs_normal.z) {
		return vec2(uv_pos.z, 1.0 - uv_pos.y);
	} else {
		return vec2(uv_pos.x, 1.0 - uv_pos.y);
	}
}

vec4 sample_texture_safe(sampler2D tex, vec2 uv) {
	vec2 safe_uv = clamp(uv, 0.002, 0.998);
	return texture(tex, safe_uv);
}

void vertex() {
	world_normal = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz;
	local_position = VERTEX;
}

void fragment() {
	vec3 norm = normalize(world_normal);
	vec2 face_uv = get_face_uv(local_position, norm);
	
	vec4 base = sample_texture_safe(base_texture, face_uv) * base_color;
	float grass_factor = get_direction_factor(norm, grass_direction);
	
	// Вычисляем зону перехода с перекрытием
	float transition_start = grass_threshold - grass_overlap;
	float transition_end = grass_threshold + grass_overlap;
	
	vec4 result = base;
	
	// В зоне перехода делаем двойную выборку
	if (grass_factor > transition_start) {
		vec4 grass = sample_texture_safe(grass_texture, face_uv) * grass_tint;
		
		if (grass.a > 0.01) {
			// Создаем плавную маску перехода
			float mask = 0.0;
			
			if (grass_factor < transition_start) {
				// До зоны перехода - только база
				mask = 0.0;
			} else if (grass_factor > transition_end) {
				// После зоны перехода - полная трава
				mask = 1.0;
			} else {
				// В зоне перехода - плавное смешивание
				float t = (grass_factor - transition_start) / (transition_end - transition_start);
				// Используем кубическую интерполяцию для более плавного перехода
				mask = t * t * (3.0 - 2.0 * t);
			}
			
			mask *= grass_blend_strength;
			
			// Смешиваем с учетом альфа-канала обеих текстур
			float blend_alpha = grass.a * mask;
			result = mix(base, grass, blend_alpha);
			
			// Дополнительное смешивание на краях для устранения швов
			if (grass_factor > transition_start && grass_factor < transition_end) {
				// Берем среднее значение цвета на границе
				vec4 edge_color = (base + grass) * 0.5;
				float edge_factor = 1.0 - abs(grass_factor - grass_threshold) / grass_overlap;
				edge_factor = pow(edge_factor, 2.0) * 0.3; // Тонкая полоса смешивания
				result = mix(result, edge_color, edge_factor);
			}
		}
	}
	
	// Оверлеи остаются без изменений
	if (overlay1_strength > 0.0) {
		vec4 overlay1 = sample_texture_safe(overlay1_texture, face_uv);
		if (overlay1.a > 0.01) {
			float overlay1_factor = get_direction_factor(norm, overlay1_direction);
			float overlay1_mask = overlay1_factor * overlay1_strength;
			result = mix(result, overlay1, overlay1_mask * overlay1.a);
		}
	}
	
	if (overlay2_strength > 0.0) {
		vec4 overlay2 = sample_texture_safe(overlay2_texture, face_uv);
		if (overlay2.a > 0.01) {
			float overlay2_factor = get_direction_factor(norm, overlay2_direction);
			float overlay2_mask = overlay2_factor * overlay2_strength;
			result = mix(result, overlay2, overlay2_mask * overlay2.a);
		}
	}
	
	result *= COLOR;
	
	// ФИКС: Принудительная непрозрачность для боковых и нижней граней
	if (abs(norm.y) < 0.5 || norm.y < -0.5) {
		// Боковые грани или нижняя грань - делаем полностью непрозрачными
		result.a = 1.0;
	}
	
	// Альтернатива: всегда непрозрачный результат (раскомментируйте если нужно)
	// result.a = 1.0;
	
	if (result.a < alpha_cutoff) {
		discard;
	}
	
	ALBEDO = result.rgb;
	ALPHA = result.a;
	ROUGHNESS = roughness;
	METALLIC = metallic;
}