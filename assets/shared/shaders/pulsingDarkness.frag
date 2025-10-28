#pragma header

uniform float _time;
uniform float _pulseIntensity;
uniform float _pulseSpeed;
uniform float _focusX;
uniform float _focusY;
uniform float _focusRadius;
uniform float _darknessPower;
uniform float _rimIntensity;
uniform float _distortStrength;

// Noise function for more organic pulsing
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

void main() {
    vec2 uv = openfl_TextureCoordv;
    vec4 color = flixel_texture2D(bitmap, uv);

    // Calculate focus point in UV coordinates (0.0 to 1.0)
    vec2 focusPoint = vec2(_focusX, _focusY);

    // Distance from current pixel to focus point
    float dist = distance(uv, focusPoint);

    // Normalized distance based on focus radius
    float normalizedDist = smoothstep(0.0, _focusRadius, dist);

    // Pulsing effect using sine wave with time
    float pulse = sin(_time * _pulseSpeed) * 0.5 + 0.5;
    pulse = pow(pulse, 2.0); // Make pulse more dramatic

    // Add noise for organic feel
    float noiseValue = noise(uv * 8.0 + _time * 0.5) * 0.1;
    pulse += noiseValue;

    // Combine pulse with distance for pulsing darkness
    float darknessAmount = normalizedDist * _pulseIntensity * pulse;
    darknessAmount = pow(darknessAmount, _darknessPower);

    // Create rim lighting effect around focus area
    float rimMask = 1.0 - smoothstep(_focusRadius * 0.8, _focusRadius * 1.2, dist);
    float rim = rimMask * _rimIntensity * pulse;

    // Apply subtle distortion near the focus point
    vec2 distortUV = uv;
    if (dist < _focusRadius) {
        vec2 direction = normalize(uv - focusPoint);
        float distortFactor = (1.0 - normalizedDist) * _distortStrength * pulse;
        distortUV += direction * sin(_time * 3.0) * distortFactor * 0.01;
        color = flixel_texture2D(bitmap, distortUV);
    }

    // Apply darkness effect
    vec3 darkenedColor = color.rgb * (1.0 - darknessAmount);

    // Add rim lighting
    darkenedColor += vec3(rim * 0.3, rim * 0.5, rim * 0.8); // Blue-ish rim light

    // Ensure focus area stays relatively bright
    float focusBrightness = 1.0 - smoothstep(0.0, _focusRadius * 0.5, dist);
    darkenedColor = mix(darkenedColor, color.rgb, focusBrightness * 0.3);

    gl_FragColor = vec4(darkenedColor, color.a);
}
