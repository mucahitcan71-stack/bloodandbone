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

// Hafif tepecikler (sadece gorsel; oyun mantigi duz kalir)
uniform float yukseklik = 40.0;
uniform float tepe_olcek = 1.6;
uniform float kenar_sondurme = 0.12;

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

float tepe_h(vec2 uv) {
	float h = texture(noise_tex, uv * tepe_olcek + vec2(0.19, 0.83)).r;
	vec2 kf = smoothstep(vec2(0.0), vec2(kenar_sondurme), uv)
		* smoothstep(vec2(0.0), vec2(kenar_sondurme), vec2(1.0) - uv);
	return (h - 0.5) * yukseklik * kf.x * kf.y;
}

void vertex() {
	float h = tepe_h(UV);
	VERTEX.y += h;
	float adim = 0.01;
	float hx = tepe_h(UV + vec2(adim, 0.0)) - tepe_h(UV - vec2(adim, 0.0));
	float hz = tepe_h(UV + vec2(0.0, adim)) - tepe_h(UV - vec2(0.0, adim));
	float dunya_adim = adim * 2.0 * 4000.0;
	NORMAL = normalize(vec3(-hx / dunya_adim * 2.0, 1.0, -hz / dunya_adim * 2.0));
}

void fragment() {
	vec2 uv = UV * doku_tekrar;
	vec3 cim = texture(cim_tex, uv).rgb;
	vec3 toprak = texture(toprak_tex, uv * 0.9).rgb;
	vec3 tas = texture(tas_tex, uv * 1.1).rgb;

	// Genis olcekli cim ton varyasyonu (±renk_varyasyon)
	float ton = texture(noise_tex, UV * leke_olcek * 0.22 + vec2(0.61, 0.13)).r;
	cim *= 1.0 + (ton - 0.5) * 2.0 * renk_varyasyon;

	float m = fbm3(UV * leke_olcek);
	float t_lo = 1.0 - toprak_miktar - gecis_genislik;
	float t_hi = 1.0 - toprak_miktar;
	float toprak_k = smoothstep(t_lo, t_hi, m);

	// Tas sadece toprak bolgelerinde
	float m_tas = fbm3(UV * leke_olcek * 1.35 + vec2(0.41, 0.17));
	float r_lo = 1.0 - tas_miktar - gecis_genislik;
	float r_hi = 1.0 - tas_miktar;
	float tas_k = smoothstep(r_lo, r_hi, m_tas) * toprak_k;

	vec3 col = mix(cim, toprak, toprak_k);
	col = mix(col, tas, tas_k);

	ALBEDO = col;
	ROUGHNESS = 1.0;
}
