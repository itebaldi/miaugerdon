shader_type canvas_item;
// O fogo atrás da logo. A arte veio sobre preto, então é somada ao que está
// atrás: o preto não soma nada e não precisa de recorte. A ondulação cresce da
// base para a ponta, como numa chama de verdade, e a chama respira de altura.
render_mode blend_add;

uniform float intensidade : hint_range(0.0, 2.0) = 1.0;
uniform float ondulacao = 0.014;
// altura da base das chamas na imagem (0 = topo, 1 = pé)
uniform float base = 0.84;

void fragment() {
	float altura = clamp((base - UV.y) / base, 0.0, 1.0);
	float onda = sin(UV.y * 38.0 - TIME * 6.0 + sin(UV.x * 9.0 + TIME * 1.3) * 2.0) * 0.6
		+ sin(UV.y * 17.0 - TIME * 3.7 + UV.x * 23.0) * 0.4;
	vec2 uv = UV;
	uv.x += onda * ondulacao * altura;
	uv.y = base - (base - uv.y) * (1.0 - 0.04 * sin(TIME * 5.3 + UV.x * 4.0));
	vec3 cor = texture(TEXTURE, uv).rgb;
	// COLOR chega com o modulate do nó: o alfa dele acende e apaga o fogo
	COLOR = vec4(cor * intensidade * COLOR.a, 1.0);
}
