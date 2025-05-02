shader_type canvas_item;

uniform float x_threshold : hint_range(0.0, 1.0) = 0.5;
uniform bool x_use_greater_than = false;

uniform float y_threshold : hint_range(0.0, 1.0) = 0.5;
uniform bool y_use_greater_than = false;

void fragment() {
    bool x_condition = x_use_greater_than ? (SCREEN_UV.x > x_threshold) : (SCREEN_UV.x < x_threshold);
    bool y_condition = y_use_greater_than ? (SCREEN_UV.y > y_threshold) : (SCREEN_UV.y < y_threshold);

    // Apply transparency if either condition is met
    if (x_condition || y_condition) {
        COLOR.a = 0.0;
    }
}