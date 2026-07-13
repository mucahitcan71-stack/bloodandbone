shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

// Cim tabani uzerine FBM maskesiyle seyrek toprak/tas lekeleri (yumusak gecis).
uniform sampler2D cim_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D toprak_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D tas_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D noise_tex : filter_linear, repeat_enable;

uniform vec2 doku_tekrar = vec2(24.0, 16.0);
uniform float leke_olcek = 3.0;
uniform float toprak_miktar = 0.15;
uniform float tas_miktar = 0.08;
uniform float gecis_genislik = 0.25;
uniform float renk_varyasyon = 0.1;

// Hafif FBM noise (bolge heightmap ustune eklenir). Mantik Y=0 kalir.
uniform float yukseklik = 4.0;
uniform float yukseklik_olcek = 2000.0;

// Boyanan heightmap: FORMAT_RGF — R = float Yukseklik, G = bake AO.
uniform sampler2D heightmap_tex : filter_linear, repeat_disable;
uniform vec2 heightmap_min = vec2(0.0);
uniform vec2 heightmap_max = vec2(1.0);
uniform float heightmap_aktif = 0.0;

// Yukseklik/egim tabanli doku (WorldSystem consts).
uniform float yukseklik_doku_etki = 0.4;
uniform float yukseklik_renk_olcek = 350.0;
uniform float egim_esik_1 = 0.15;
uniform float egim_esik_2 = 0.45;
uniform float ao_guc = 0.35;

varying float v_yukseklik;
varying float v_egim;
varying float v_ao;

float fbm3(vec2 uv) {
	float v = 0.0;
	float a = 0.5;
	float s = 0.0;
	vec2 p = uv;
	for (int i = 0; i < 3; i++) {
		v += a * texture(noise_tex, p).r;
		s += a;
		p = p * 2.13 + vec2(0.37, 0.71);
		a *= 0.5;
	}
	return v / s;
}

// 3 oktav yumusak FBM; merkezlenmis ~[-0.5, 0.5]
float fbm_yukseklik(vec2 xz) {
	vec2 p = xz / max(yukseklik_olcek, 1.0);
	float v = 0.0;
	float a = 0.5;
	float s = 0.0;
	for (int i = 0; i < 3; i++) {
		v += a * texture(noise_tex, p).r;
		s += a;
		p = p * 2.03 + vec2(0.17, 0.41);
		a *= 0.5;
	}
	return (v / s) - 0.5;
}

float noise_h(vec2 local_xz) {
	return fbm_yukseklik(local_xz) * yukseklik;
}

vec2 heightmap_uv(vec2 world_xz) {
	vec2 span = heightmap_max - heightmap_min;
	if (span.x < 0.001 || span.y < 0.001) {
		return vec2(-1.0);
	}
	return (world_xz - heightmap_min) / span;
}

float heightmap_h(vec2 world_xz) {
	if (heightmap_aktif < 0.5) {
		return 0.0;
	}
	vec2 uv = heightmap_uv(world_xz);
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		return 0.0;
	}
	return texture(heightmap_tex, uv).r;
}

float heightmap_ao(vec2 world_xz) {
	if (heightmap_aktif < 0.5) {
		return 1.0;
	}
	vec2 uv = heightmap_uv(world_xz);
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		return 1.0;
	}
	return texture(heightmap_tex, uv).g;
}

float toplam_h(vec2 world_xz, vec2 local_xz) {
	return noise_h(local_xz) + heightmap_h(world_xz);
}

// Fractal sample — tiling kirici (buyuk + kucuk olcek mix).
vec3 doku_fractal(sampler2D tex, vec2 uv) {
	return mix(texture(tex, uv).rgb, texture(tex, uv * 0.31).rgb, 0.5);
}

void vertex() {
	vec2 local_xz = VERTEX.xz;
	vec2 world_xz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
	float h = toplam_h(world_xz, local_xz);
	VERTEX.y += h;
	v_yukseklik = h;
	v_ao = heightmap_ao(world_xz);

	// Yukseklik turevlerinden normal (DirectionalLight egim golgesi + slope doku)
	float hm_span = max(heightmap_max.x - heightmap_min.x, 1.0);
	float eps = max(hm_span * 0.004, max(yukseklik_olcek * 0.002, 2.0));
	float hx = toplam_h(world_xz + vec2(eps, 0.0), local_xz + vec2(eps, 0.0))
			- toplam_h(world_xz - vec2(eps, 0.0), local_xz - vec2(eps, 0.0));
	float hz = toplam_h(world_xz + vec2(0.0, eps), local_xz + vec2(0.0, eps))
			- toplam_h(world_xz - vec2(0.0, eps), local_xz - vec2(0.0, eps));
	vec3 n = normalize(vec3(-hx / (2.0 * eps), 1.0, -hz / (2.0 * eps)));
	NORMAL = n;
	// slope = 1 - clamp(dot(n, up), 0, 1) — world Y-up
	v_egim = 1.0 - clamp(dot(n, vec3(0.0, 1.0, 0.0)), 0.0, 1.0);
	TANGENT = normalize(cross(vec3(0.0, 0.0, 1.0), n));
	if (length(TANGENT) < 0.001) {
		TANGENT = vec3(1.0, 0.0, 0.0);
	}
	BINORMAL = cross(n, TANGENT);
}

void fragment() {
	vec2 uv = UV * doku_tekrar;
	vec3 cim = doku_fractal(cim_tex, uv);
	vec3 toprak = doku_fractal(toprak_tex, uv * 0.9);
	vec3 tas = doku_fractal(tas_tex, uv * 1.1);

	// Genis olcekli cim ton varyasyonu (±renk_varyasyon)
	float ton = texture(noise_tex, UV * leke_olcek * 0.22 + vec2(0.61, 0.13)).r;
	cim *= 1.0 + (ton - 0.5) * 2.0 * renk_varyasyon;

	// --- 1) Slope-based texture (primary) ---
	// < egim_esik_1 → cim; esik1..esik2 → grass↔dirt; > esik2 → dirt/rock
	float slope = v_egim;
	float egim_toprak = smoothstep(egim_esik_1, egim_esik_2, slope);
	float egim_tas = smoothstep(egim_esik_2, min(egim_esik_2 + 0.28, 1.0), slope);

	// Duz alanlarda hafif noise lekeleri (dik egimde slope hakim)
	float m = fbm3(UV * leke_olcek);
	float t_lo = 1.0 - toprak_miktar - gecis_genislik;
	float t_hi = 1.0 - toprak_miktar;
	float leke_toprak = smoothstep(t_lo, t_hi, m) * (1.0 - egim_toprak);

	float m_tas = fbm3(UV * leke_olcek * 1.35 + vec2(0.41, 0.17));
	float r_lo = 1.0 - tas_miktar - gecis_genislik;
	float r_hi = 1.0 - tas_miktar;
	float leke_tas = smoothstep(r_lo, r_hi, m_tas) * leke_toprak;

	float toprak_k = max(egim_toprak, leke_toprak);
	float tas_k = max(egim_tas * 0.85, leke_tas);

	// --- 4) Height-based albedo tint ---
	float hn = clamp(v_yukseklik / max(yukseklik_renk_olcek, 1.0), -1.0, 1.0);
	float h_tepe = max(hn, 0.0) * yukseklik_doku_etki;
	float h_vadi = max(-hn, 0.0) * yukseklik_doku_etki;
	// Yuksek: kuru/acik toprak; alcak: yesil kalir / koyu
	toprak_k = clamp(toprak_k + h_tepe * 0.65, 0.0, 1.0);
	toprak_k *= 1.0 - h_vadi * 0.55;
	// Dik egim asla cim kalmaz
	toprak_k = max(toprak_k, egim_toprak);

	vec3 col = mix(cim, toprak, toprak_k);
	col = mix(col, tas, tas_k);

	col *= 1.0 + h_tepe * 0.35;
	col = mix(col, col * vec3(0.72, 0.93, 0.68), h_vadi);

	// --- 5) Bake AO ---
	col *= mix(1.0, v_ao, ao_guc);

	ALBEDO = col;
	ROUGHNESS = 1.0;
}
