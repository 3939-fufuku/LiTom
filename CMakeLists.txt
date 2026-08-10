include(${CMAKE_CURRENT_LIST_DIR}/cmake/patch_tom_oled_lvgl9.cmake)

target_sources_ifdef(CONFIG_LITOM_PREFER_USB_ENDPOINT_ON_READY app PRIVATE src/prefer_usb_endpoint.c)
target_sources_ifdef(CONFIG_LITOM_AUTO_MOUSE_LAYER app PRIVATE src/auto_mouse_layer.c)
