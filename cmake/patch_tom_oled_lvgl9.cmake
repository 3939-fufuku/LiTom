# zmk-tom-oled still targets the LVGL 8 and Zephyr 3 input APIs. Keep the
# compatibility rewrite here until that module ships native ZMK v0.4 support.
set(TOM_OLED_WIDGET_DIR "${ZEPHYR_BASE}/../zmk-tom-oled/boards/shields/tom_oled/widgets")

if(NOT EXISTS "${TOM_OLED_WIDGET_DIR}")
  return()
endif()

function(litom_replace_in_file path old new)
  if(NOT EXISTS "${path}")
    return()
  endif()

  file(READ "${path}" content)
  string(REPLACE "${old}" "${new}" updated "${content}")
  if(NOT updated STREQUAL content)
    file(WRITE "${path}" "${updated}")
  endif()
endfunction()

file(GLOB_RECURSE TOM_OLED_SOURCES "${TOM_OLED_WIDGET_DIR}/*.c")
foreach(source IN LISTS TOM_OLED_SOURCES)
  litom_replace_in_file("${source}" "LV_IMG_CF_INDEXED_1BIT" "LV_COLOR_FORMAT_I1")
  litom_replace_in_file("${source}" "LV_IMG_CF_TRUE_COLOR" "LV_COLOR_FORMAT_NATIVE")
  litom_replace_in_file("${source}" "lv_point_t" "lv_point_precise_t")
endforeach()

set(TOM_OLED_IMAGE_SOURCES
  "${TOM_OLED_WIDGET_DIR}/assets/codex_status_images.c"
  "${TOM_OLED_WIDGET_DIR}/bongo_cat_images.c"
  "${TOM_OLED_WIDGET_DIR}/modifiers_sym.c"
  "${TOM_OLED_WIDGET_DIR}/output_status_sym.c"
)

function(litom_patch_image_descriptor source width stride)
    set(old ".header.cf = LV_COLOR_FORMAT_I1,\n  .header.always_zero = 0,\n  .header.reserved = 0,\n  .header.w = ${width},")
    set(new ".header.magic = LV_IMAGE_HEADER_MAGIC,\n  .header.cf = LV_COLOR_FORMAT_I1,\n  .header.flags = 0,\n  .header.w = ${width},\n  .header.stride = ${stride},")
    litom_replace_in_file("${source}" "${old}" "${new}")

    set(old ".header.cf = LV_COLOR_FORMAT_I1,\n    .header.always_zero = 0,\n    .header.reserved = 0,\n    .header.w = ${width},")
    set(new ".header.magic = LV_IMAGE_HEADER_MAGIC,\n    .header.cf = LV_COLOR_FORMAT_I1,\n    .header.flags = 0,\n    .header.w = ${width},\n    .header.stride = ${stride},")
    litom_replace_in_file("${source}" "${old}" "${new}")
endfunction()

foreach(source IN LISTS TOM_OLED_IMAGE_SOURCES)
  litom_patch_image_descriptor("${source}" 50 7)
  litom_patch_image_descriptor("${source}" 14 2)
  litom_patch_image_descriptor("${source}" 9 2)
  litom_patch_image_descriptor("${source}" 5 1)
endforeach()

set(trackball "${TOM_OLED_WIDGET_DIR}/trackball_activity.c")
litom_replace_in_file("${trackball}"
  "static void trackball_input_listener(struct input_event *ev) {"
  "static void trackball_input_listener(struct input_event *ev, void *user_data) {\n    ARG_UNUSED(user_data);\n")
litom_replace_in_file("${trackball}"
  "INPUT_CALLBACK_DEFINE(NULL, trackball_input_listener);"
  "INPUT_CALLBACK_DEFINE(NULL, trackball_input_listener, NULL);")

set(output_status "${TOM_OLED_WIDGET_DIR}/output_status.c")
litom_replace_in_file("${output_status}" "zmk_endpoints_selected()" "zmk_endpoint_get_selected()")

set(battery "${TOM_OLED_WIDGET_DIR}/battery_status.c")
file(READ "${battery}" battery_content)
if(NOT battery_content MATCHES "static void litom_canvas_draw_rect\\(")
  litom_replace_in_file("${battery}"
    "static void draw_battery(lv_obj_t *canvas, uint8_t level, bool usb_present) {"
    "static void litom_canvas_draw_rect(lv_obj_t *canvas, int32_t x, int32_t y, int32_t width,\n                                   int32_t height, const lv_draw_rect_dsc_t *dsc) {\n    bool outline = dsc->border_width > 0;\n    for (int32_t row = y; row < y + height; row++) {\n        for (int32_t column = x; column < x + width; column++) {\n            bool border = column == x || column == x + width - 1 || row == y ||\n                          row == y + height - 1;\n            if (!outline || border) {\n                lv_canvas_set_px(canvas, column, row, lv_color_white(), LV_OPA_COVER);\n            }\n        }\n    }\n}\n\nstatic void draw_battery(lv_obj_t *canvas, uint8_t level, bool usb_present) {")
endif()
litom_replace_in_file("${battery}" "lv_canvas_draw_rect(" "litom_canvas_draw_rect(")
litom_replace_in_file("${battery}" "lv_canvas_set_px(canvas, 0, 0, lv_color_white());"
  "lv_canvas_set_px(canvas, 0, 0, lv_color_white(), LV_OPA_COVER);")
litom_replace_in_file("${battery}" "lv_canvas_set_px(canvas, 4, 0, lv_color_white());"
  "lv_canvas_set_px(canvas, 4, 0, lv_color_white(), LV_OPA_COVER);")

set(peripheral "${TOM_OLED_WIDGET_DIR}/peripheral_status.c")
litom_replace_in_file("${peripheral}" "lv_canvas_set_px(canvas, x, y, lv_color_black());"
  "lv_canvas_set_px(canvas, x, y, lv_color_black(), LV_OPA_COVER);")
litom_replace_in_file("${peripheral}" "timer->user_data" "lv_timer_get_user_data(timer)")
