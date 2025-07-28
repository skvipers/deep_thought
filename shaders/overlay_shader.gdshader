shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// Базовые текстуры
uniform sampler2D base_texture : source_color, hint_default_white;
uniform sampler2D grass_texture : source_color, hint_default_white;
uniform sampler2D overlay_texture_atlas : source_color, hint_default_white; // Атлас с текстурами оверлеев

// Размер атласа (например, 4x4 = 16 текстур)
uniform vec2 atlas_size = vec2(4.0, 4.0);

// Глобальные настройки биома (для простого режима)
uniform int biome_id : hint_range(0, 31) = 0;
uniform sampler2D biome_colors : source_color; // Градиент с цветами биомов
uniform bool use_simple_biome = true;

// Настройки материала
uniform float roughness : hint_range(0.0, 1.0) = 1.0;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float alpha_cutoff : hint_range(0.0, 1.0) = 0.5;

// Вспомогательные переменные
varying vec3 world_normal;
varying vec3 local_position;
varying vec4 packed_overlay_data;

// ДОБАВЛЕНО: Безопасная выборка текстур (исправляет прозрачную обводку)
vec4 sample_texture_safe(sampler2D tex, vec2 uv) {
    vec2 safe_uv = clamp(uv, 0.002, 0.998);
    return texture(tex, safe_uv);
}

// ИСПРАВЛЕНО: Функция для получения UV координат из атласа
vec2 get_atlas_uv(vec2 base_uv, int texture_index) {
    float atlas_w = atlas_size.x;
    float atlas_h = atlas_size.y;

    float x = mod(float(texture_index), atlas_w);
    float y = floor(float(texture_index) / atlas_w);

    vec2 tile_size = 1.0 / atlas_size;
    vec2 tile_offset = vec2(x, y) * tile_size;

    // ИСПРАВЛЕНО: Сжимаем UV в пределы тайла с отступами от краев
    vec2 margin = vec2(0.01) / atlas_size; // Отступ от краев тайла
    vec2 safe_tile_size = tile_size - 2.0 * margin;
    vec2 safe_base_uv = clamp(base_uv, 0.0, 1.0);

    return tile_offset + margin + safe_base_uv * safe_tile_size;
}

// Распаковка данных из vertex color
struct OverlayData {
    float grass_strength;
    int biome_modifier;
    int overlay1_type;
    float overlay1_strength;
    int overlay2_type;
    float overlay2_strength;
    int grass_direction;
    int overlay1_direction;
    int overlay2_direction;
};

OverlayData unpack_overlay_data(vec4 packed_color) {
    OverlayData data;

    // R канал: трава (4 бита) + биом модификатор (4 бита)
    float r_data = packed_color.r * 255.0;
    data.grass_strength = floor(r_data / 16.0) / 15.0;
    data.biome_modifier = int(mod(r_data, 16.0));

    // G канал: оверлей 1 тип (4 бита) + сила (4 бита)
    float g_data = packed_color.g * 255.0;
    data.overlay1_type = int(floor(g_data / 16.0));
    data.overlay1_strength = mod(g_data, 16.0) / 15.0;

    // B канал: оверлей 2 тип (4 бита) + сила (4 бита)
    float b_data = packed_color.b * 255.0;
    data.overlay2_type = int(floor(b_data / 16.0));
    data.overlay2_strength = mod(b_data, 16.0) / 15.0;

    // A канал: направления (3+3+2 бита)
    float a_data = packed_color.a * 255.0;
    data.grass_direction = int(floor(a_data / 32.0));
    data.overlay1_direction = int(mod(floor(a_data / 4.0), 8.0));
    data.overlay2_direction = int(mod(a_data, 4.0));

    return data;
}

// ИСПРАВЛЕНО: Заменил switch на if-else для лучшей совместимости
float get_direction_factor(vec3 normal, int direction) {
    if (direction == 0) {
        return max(0.0, normal.y);        // Вверх (Y+)
    } else if (direction == 1) {
        return max(0.0, -normal.y);       // Вниз (Y-)
    } else if (direction == 2) {
        return max(0.0, normal.z);        // Север (Z+)
    } else if (direction == 3) {
        return max(0.0, -normal.z);       // Юг (Z-)
    } else if (direction == 4) {
        return max(0.0, normal.x);        // Восток (X+)
    } else if (direction == 5) {
        return max(0.0, -normal.x);       // Запад (X-)
    } else if (direction == 6) {
        return 1.0;                       // Все направления
    } else {
        return 0.0;
    }
}

// ИСПРАВЛЕНО: Упрощенная и более надежная функция получения UV координат
vec2 get_face_uv(vec3 local_pos, vec3 normal) {
    vec3 abs_normal = abs(normal);

    // Нормализуем координаты в диапазон 0-1
    vec3 uv_pos = fract(local_pos + 0.5);

    if (abs_normal.y > abs_normal.x && abs_normal.y > abs_normal.z) {
        // Горизонтальные грани (верх/низ)
        return vec2(uv_pos.x, uv_pos.z);
    } else if (abs_normal.x > abs_normal.z) {
        // Вертикальные грани X
        return vec2(uv_pos.z, uv_pos.y);
    } else {
        // Вертикальные грани Z
        return vec2(uv_pos.x, uv_pos.y);
    }
}

void vertex() {
    // Передаём нормаль в мировых координатах
    world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
    // Передаём локальные координаты вершин
    local_position = VERTEX;
    // Передаём упакованные данные оверлеев
    packed_overlay_data = COLOR;
}

void fragment() {
    // Нормализуем нормаль
    vec3 norm = normalize(world_normal);

    // Получаем правильные UV-координаты для каждой грани
    vec2 face_uv = get_face_uv(local_position, norm);

    // Распаковываем данные оверлеев
    OverlayData overlay_data = unpack_overlay_data(packed_overlay_data);

    // ИСПРАВЛЕНО: Используем безопасную выборку базовой текстуры
    vec4 base = sample_texture_safe(base_texture, face_uv);
    vec4 result = base;

    // Получаем цвет биома
    vec3 biome_tint = vec3(1.0);
    if (use_simple_biome) {
        // Простой режим - один биом на чанк
        biome_tint = texture(biome_colors, vec2(float(biome_id) / 32.0, 0.5)).rgb;
    } else {
        // Продвинутый режим - используем модификатор из vertex data
        int local_biome = (biome_id + overlay_data.biome_modifier) % 32;
        biome_tint = texture(biome_colors, vec2(float(local_biome) / 32.0, 0.5)).rgb;
    }

    // ИСПРАВЛЕНО: Применяем траву с безопасной выборкой
    if (overlay_data.grass_strength > 0.01) {
        vec4 grass = sample_texture_safe(grass_texture, face_uv);
        float grass_factor = get_direction_factor(norm, overlay_data.grass_direction);
        float grass_mask = grass_factor * overlay_data.grass_strength;

        if (grass.a > 0.01) {
            // Применяем биом tint к траве
            grass.rgb *= biome_tint;
            // ИСПРАВЛЕНО: убираем двойное применение альфы
            result = mix(result, grass, grass_mask);
        }
    }

    // ИСПРАВЛЕНО: Применяем первый оверлей с безопасной выборкой из атласа
    if (overlay_data.overlay1_strength > 0.01 && overlay_data.overlay1_type > 0) {
        vec2 overlay1_uv = get_atlas_uv(face_uv, overlay_data.overlay1_type - 1);
        vec4 overlay1 = texture(overlay_texture_atlas, overlay1_uv);

        if (overlay1.a > 0.01) {
            float overlay1_factor = get_direction_factor(norm, overlay_data.overlay1_direction);
            float overlay1_mask = overlay1_factor * overlay_data.overlay1_strength;
            result = mix(result, overlay1, overlay1_mask);
        }
    }

    // ИСПРАВЛЕНО: Применяем второй оверлей с безопасной выборкой из атласа
    if (overlay_data.overlay2_strength > 0.01 && overlay_data.overlay2_type > 0) {
        vec2 overlay2_uv = get_atlas_uv(face_uv, overlay_data.overlay2_type - 1);
        vec4 overlay2 = texture(overlay_texture_atlas, overlay2_uv);

        if (overlay2.a > 0.01) {
            float overlay2_factor = get_direction_factor(norm, overlay_data.overlay2_direction);
            float overlay2_mask = overlay2_factor * overlay_data.overlay2_strength;
            result = mix(result, overlay2, overlay2_mask);
        }
    }

    // ИСПРАВЛЕНО: Принудительная непрозрачность для всех граней
    result.a = 1.0;

    if (result.a < alpha_cutoff) {
        discard;
    }

    ALBEDO = result.rgb;
    ALPHA = result.a;
    ROUGHNESS = roughness;
    METALLIC = metallic;
}