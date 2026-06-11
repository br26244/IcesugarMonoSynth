#include "synth_ui.h"

#include <stdio.h>
#include "display_spi.h"
#include "lvgl.h"
#include "pico/stdlib.h"

#define BUF_LINES 16

#define TOP_H  (DISP_H / 5)
#define BOT_H  (DISP_H / 5)
#define MID_H  (DISP_H - TOP_H - BOT_H)
#define BOT_Y  (TOP_H + MID_H)

static uint8_t draw_buf[DISP_W * BUF_LINES * sizeof(lv_color16_t)];

static lv_display_t *display;
static lv_obj_t *root;
static lv_obj_t *adsr_labels[4];
static lv_obj_t *param_arcs[3];
static lv_obj_t *param_labels[3];
static lv_obj_t *square_panel;
static lv_obj_t *saw_panel;
static lv_obj_t *square_label;
static lv_obj_t *saw_label;
static bool ui_ready;

static void flush_cb(lv_display_t *disp, const lv_area_t *area, uint8_t *px_map)
{
    int32_t w = lv_area_get_width(area);
    int32_t h = lv_area_get_height(area);
    uint32_t stride_bytes = lv_draw_buf_width_to_stride(w, LV_COLOR_FORMAT_RGB565);

    display_spi_blit((uint16_t)area->x1, (uint16_t)area->y1,
                     (uint16_t)w, (uint16_t)h,
                     (const uint16_t *)px_map, (uint16_t)(stride_bytes / 2));

    lv_display_flush_ready(disp);
}

static void strip_padding(lv_obj_t *obj)
{
    lv_obj_set_style_pad_all(obj, 0, 0);
    lv_obj_set_style_pad_row(obj, 0, 0);
    lv_obj_set_style_pad_column(obj, 0, 0);
    lv_obj_set_style_border_width(obj, 0, 0);
    lv_obj_set_style_radius(obj, 0, 0);
    lv_obj_remove_flag(obj, LV_OBJ_FLAG_SCROLLABLE);
}

static lv_obj_t *make_panel(lv_obj_t *parent, int x, int y, int w, int h,
                            uint32_t bg_hex, lv_border_side_t borders)
{
    lv_obj_t *panel = lv_obj_create(parent);
    lv_obj_set_pos(panel, x, y);
    lv_obj_set_size(panel, w, h);
    strip_padding(panel);
    lv_obj_set_style_bg_color(panel, lv_color_hex(bg_hex), 0);
    lv_obj_set_style_border_width(panel, 1, 0);
    lv_obj_set_style_border_color(panel, lv_color_hex(0x424242), 0);
    lv_obj_set_style_border_side(panel, borders, 0);

    return panel;
}

static lv_obj_t *make_centered_label(lv_obj_t *parent, const char *text)
{
    lv_obj_t *label = lv_label_create(parent);
    lv_label_set_text(label, text);
    lv_obj_set_style_text_color(label, lv_color_white(), 0);
    lv_obj_center(label);

    return label;
}

static lv_obj_t *make_arc(lv_obj_t *parent, int x, int y, int size)
{
    lv_obj_t *arc = lv_arc_create(parent);
    lv_obj_set_pos(arc, x, y);
    lv_obj_set_size(arc, size, size);
    lv_arc_set_rotation(arc, 270);
    lv_arc_set_bg_angles(arc, 0, 360);
    lv_arc_set_range(arc, 0, 100);
    lv_arc_set_value(arc, 0);
    lv_obj_set_style_arc_width(arc, 10, LV_PART_MAIN);
    lv_obj_set_style_arc_width(arc, 10, LV_PART_INDICATOR);
    lv_obj_set_style_arc_color(arc, lv_color_hex(0x424242), LV_PART_MAIN);
    lv_obj_set_style_arc_color(arc, lv_color_hex(0x42A5F5), LV_PART_INDICATOR);
    lv_obj_set_style_bg_opa(arc, LV_OPA_TRANSP, LV_PART_KNOB);
    lv_obj_set_style_pad_all(arc, 4, LV_PART_KNOB);
    lv_obj_remove_flag(arc, LV_OBJ_FLAG_SCROLLABLE);

    return arc;
}

static int percent_from_4bit(uint8_t value)
{
    if (value > 15) {
        value = 15;
    }

    return (int)value * 100 / 15;
}

static int percent_from_pitch(uint8_t value)
{
    if (value > 48) {
        value = 48;
    }

    return (int)value * 100 / 48;
}

static void build_ui(void)
{
    lv_obj_t *screen = lv_screen_active();
    strip_padding(screen);
    lv_obj_set_style_bg_color(screen, lv_color_hex(0x212121), 0);

    root = lv_obj_create(screen);
    lv_obj_set_pos(root, 0, 0);
    lv_obj_set_size(root, DISP_W, DISP_H);
    strip_padding(root);
    lv_obj_set_style_bg_color(root, lv_color_hex(0x212121), 0);

    static const char *adsr_names[4] = { "A", "D", "S", "R" };
    static const uint32_t adsr_colors[4] = {
        0x1565C0,
        0x00897B,
        0x6A1B9A,
        0xC62828
    };

    const int quarter_w = DISP_W / 4;
    for (int i = 0; i < 4; i++) {
        int x = i * quarter_w;
        int w = quarter_w;
        lv_border_side_t borders = LV_BORDER_SIDE_TOP | LV_BORDER_SIDE_BOTTOM | LV_BORDER_SIDE_RIGHT;

        if (i == 0) {
            borders = borders | LV_BORDER_SIDE_LEFT;
        }
        if (i == 3) {
            w = DISP_W - x;
        }

        lv_obj_t *panel = make_panel(root, x, 0, w, TOP_H, adsr_colors[i], borders);
        adsr_labels[i] = make_centered_label(panel, adsr_names[i]);
    }

    make_panel(root, 0, TOP_H, DISP_W, MID_H, 0x212121, LV_BORDER_SIDE_NONE);

    const int col_w = DISP_W / 3;
    const int arc_size = (MID_H < col_w) ? MID_H - 16 : col_w - 16;
    const int arc_y = TOP_H + (MID_H - arc_size) / 2 - 8;
    static const char *param_names[3] = { "pitch", "low pass", "high pass" };

    for (int i = 0; i < 3; i++) {
        int arc_x = i * col_w + (col_w - arc_size) / 2;
        param_arcs[i] = make_arc(root, arc_x, arc_y, arc_size);
        param_labels[i] = lv_label_create(root);
        lv_label_set_text(param_labels[i], param_names[i]);
        lv_obj_set_style_text_color(param_labels[i], lv_color_white(), 0);
        lv_obj_align_to(param_labels[i], param_arcs[i], LV_ALIGN_OUT_BOTTOM_MID, 0, 0);
    }

    const int half_w = DISP_W / 2;
    square_panel = make_panel(root, 0, BOT_Y, half_w, BOT_H, 0x455A64,
                              LV_BORDER_SIDE_TOP | LV_BORDER_SIDE_RIGHT);
    saw_panel = make_panel(root, half_w, BOT_Y, DISP_W - half_w, BOT_H, 0x5D4037,
                           LV_BORDER_SIDE_TOP | LV_BORDER_SIDE_LEFT);
    square_label = make_centered_label(square_panel, "square");
    saw_label = make_centered_label(saw_panel, "saw");
}

static void refresh_now(void)
{
    for (int i = 0; i < 20; i++) {
        lv_timer_handler();
        sleep_ms(5);
    }
}

void synthUiInit(void)
{
    display_spi_init();
    sleep_ms(200);
    display_spi_fill(0);

    lv_init();

    display = lv_display_create(DISP_W, DISP_H);
    lv_display_set_flush_cb(display, flush_cb);
    lv_display_set_color_format(display, LV_COLOR_FORMAT_RGB565);
    lv_display_set_buffers(display, draw_buf, NULL, sizeof draw_buf,
                           LV_DISPLAY_RENDER_MODE_PARTIAL);

    build_ui();
    ui_ready = true;
}

void synthUiRefresh(const synthUiState *state)
{
    char text[32];

    if (!ui_ready || state == NULL) {
        return;
    }

    snprintf(text, sizeof text, "A %u", state->attack);
    lv_label_set_text(adsr_labels[0], text);
    snprintf(text, sizeof text, "D %u", state->decay);
    lv_label_set_text(adsr_labels[1], text);
    snprintf(text, sizeof text, "S %u", state->sustain);
    lv_label_set_text(adsr_labels[2], text);
    snprintf(text, sizeof text, "R %u", state->release);
    lv_label_set_text(adsr_labels[3], text);

    lv_arc_set_value(param_arcs[0], percent_from_pitch(state->pitch));
    snprintf(text, sizeof text, "pitch %u", state->pitch);
    lv_label_set_text(param_labels[0], text);

    lv_arc_set_value(param_arcs[1], percent_from_4bit(state->lowpass));
    snprintf(text, sizeof text, "low pass %u", state->lowpass);
    lv_label_set_text(param_labels[1], text);

    lv_arc_set_value(param_arcs[2], percent_from_4bit(state->highpass));
    snprintf(text, sizeof text, "high pass %u", state->highpass);
    lv_label_set_text(param_labels[2], text);

    if (state->square_on) {
        lv_obj_set_style_bg_color(square_panel, lv_color_hex(0xFDD835), 0);
        lv_obj_set_style_text_color(square_label, lv_color_black(), 0);
    } else {
        lv_obj_set_style_bg_color(square_panel, lv_color_hex(0x455A64), 0);
        lv_obj_set_style_text_color(square_label, lv_color_white(), 0);
    }

    if (state->saw_on) {
        lv_obj_set_style_bg_color(saw_panel, lv_color_hex(0xFDD835), 0);
        lv_obj_set_style_text_color(saw_label, lv_color_black(), 0);
    } else {
        lv_obj_set_style_bg_color(saw_panel, lv_color_hex(0x5D4037), 0);
        lv_obj_set_style_text_color(saw_label, lv_color_white(), 0);
    }

    lv_obj_invalidate(root);
    refresh_now();
}
