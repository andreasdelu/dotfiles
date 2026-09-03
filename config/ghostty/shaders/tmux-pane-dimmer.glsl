// Dim tmux pane content outside the active pane.
//
// tmux cannot composite over application-defined colours, so
// ~/.tmux/bin/emit-pane-metadata sends the current pane rectangle to reserved
// terminal palette entries 160-165. Ghostty exposes those entries to this
// shader through iPalette without requiring a shader/config reload.

const float DIM_OPACITY = 0.2;

float paletteByte(float value) {
    return floor(value * 255.0 + 0.5);
}

// Two unsigned 12-bit values are packed into one RGB palette entry.
vec2 unpackPair(vec3 color) {
    float red = paletteByte(color.r);
    float green = paletteByte(color.g);
    float blue = paletteByte(color.b);

    return vec2(
        red * 16.0 + floor(green / 16.0),
        mod(green, 16.0) * 256.0 + blue
    );
}

bool insideRect(vec2 point, vec2 topLeft, vec2 bottomRight) {
    return point.x >= topLeft.x && point.x < bottomRight.x &&
           point.y >= topLeft.y && point.y < bottomRight.y;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    fragColor = texture2D(iChannel0, uv);

    vec3 marker = iPalette[160];
    bool metadataValid =
        paletteByte(marker.r) == 84.0 &&
        paletteByte(marker.g) == 77.0 &&
        paletteByte(marker.b) == 1.0;
    if (!metadataValid) return;

    vec2 gridSize = unpackPair(iPalette[161]);
    vec2 activeTopLeft = unpackPair(iPalette[162]);
    vec2 activeBottomRight = unpackPair(iPalette[163]);
    vec2 contentRows = unpackPair(iPalette[164]);
    vec2 cellPixels = unpackPair(iPalette[165]);
    if (gridSize.x <= 0.0 || gridSize.y <= 0.0 ||
        cellPixels.x <= 0.0 || cellPixels.y <= 0.0) return;

    // Ghostty's Metal renderer and tmux both use top-left origins. Balanced
    // padding puts any pixels outside the terminal grid equally on each edge.
    vec2 gridPixels = gridSize * cellPixels;
    vec2 gridOrigin = max((iResolution.xy - gridPixels) * 0.5, vec2(0.0));
    vec2 cell = (fragCoord - gridOrigin) / cellPixels;
    bool inContent = cell.y >= contentRows.x && cell.y < contentRows.y;
    bool inActivePane = insideRect(cell, activeTopLeft, activeBottomRight);

    if (inContent && !inActivePane) {
        fragColor.rgb = mix(fragColor.rgb, vec3(0.0), DIM_OPACITY);
    }
}
