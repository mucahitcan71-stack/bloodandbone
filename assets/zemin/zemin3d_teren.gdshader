shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

// Cim tabani uzerine noise maskesiyle toprak ve tas lekeleri bindirir.
uniform sampler2D cim_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D toprak_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D tas_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D noise_tex : filter_linear, repeat_enable;

uniform vec2 doku_tekrar = vec2(24.0, 16.0);
uniform float noise_olcek = 4.0;
uniform float toprak_esik = 0.52;
uniform float tas_esik = 0.68;
uniform float gecis = 0.10;
uniform float renk_varyasyon = 0.12;

// Hafif tepecikler (sadece gorsel; oyun mantigi duz kalir)
uniform float yukseklik = 40.0;
uniform float tepe_olcek = 1.6;
uniform float kenar_sondurme = 0.12;

float tepe_h(vec2 uv) {
	float h = texture(noise_tex, uv * tepe_olcek + vec2(0.19, 0.83)).r;
	// Kenarlarda sifira insin ki plane siluetinde bosluk olusmasin
	vec2 kf = smoothstep(vec2(0.0), vec2(kenar_sondurme), uv)
		* smoothstep(vec2(0.0), vec2(kenar_sondurme), vec2(1.0) - uv);
	return (h - 0.5) * yukseklik * kf.x * kf.y;
}

void vertex() {
	float h = tepe_h(UV);
	VERTEX.y += h;
	// Normal: komsu orneklerle sonlu fark
	float adim = 0.01;
	float hx = tepe_h(UV + vec2(adim, 0.0)) - tepe_h(UV - vec2(adim, 0.0));
	float hz = tepe_h(UV + vec2(0.0, adim)) - tepe_h(UV - vec2(0.0, adim));
	// UV adimini dunya birimine cevir (plane boyutu ~ doku_tekrar orantili;
	// gorsel amac icin sabit olcek yeterli)
	float dunya_adim = adim * 2.0 * 4000.0;
	NORMAL = normalize(vec3(-hx / dunya_adim * 2.0, 1.0, -hz / dunya_adim * 2.0));
}

void fragment() {
	vec2 uv = UV * doku_tekrar;
	vec3 cim = texture(cim_tex, uv).rgb;
	vec3 toprak = texture(toprak_tex, uv * 0.9).rgb;
	vec3 tas = texture(tas_tex, uv * 1.1).rgb;

	float n1 = texture(noise_tex, UV * noise_olcek).r;
	float n2 = texture(noise_tex, UV * noise_olcek * 3.1 + vec2(0.37, 0.71)).r;
	float m = n1 * 0.72 + n2 * 0.28;

	float toprak_k = smoothstep(toprak_esik, toprak_esik + gecis, m);
	float tas_k = smoothstep(tas_esik, tas_esik + gecis, m);

	vec3 col = mix(cim, toprak, toprak_k);
	col = mix(col, tas, tas_k);

	// Genis olcekli ton varyasyonu: tekrar hissini kirar
	float ton = texture(noise_tex, UV * noise_olcek * 0.35 + vec2(0.61, 0.13)).r;
	col *= 1.0 + (ton - 0.5) * 2.0 * renk_varyasyon;

	ALBEDO = col;
	ROUGHNESS = 1.0;
}
