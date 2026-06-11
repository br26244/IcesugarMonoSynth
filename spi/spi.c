#include <stdio.h>
#include "pico/stdlib.h"
#include "pico/stdio.h"
#include "pico/stdio_usb.h"
#include "hardware/gpio.h"
#include "hardware/spi.h"
#include "synth_ui.h"

#define SPIPORT     spi1
#define BAUDRATE 500000
#define SPISCKPIN  10
#define SPIRXPIN   12
#define SPICSPIN   13

#define PINLED      16
#define HOSTSTART   'C'  //sends c to start streaming

#define PARAM_SYNC0 0xFF
#define PARAM_SYNC1 0x55
#define PARAM_SYNC2 0xAA
#define PARAM_PAYLOAD_LEN 8
#define AUDIO_IDLE 128
#define DISPLAY_UPDATE_MS 5000

typedef enum {
    PARAM_WAIT_SYNC0,
    PARAM_WAIT_SYNC1,
    PARAM_WAIT_SYNC2,
    PARAM_READ_PAYLOAD
} paramParseState;

static paramParseState param_state = PARAM_WAIT_SYNC0;
static uint8_t param_payload[PARAM_PAYLOAD_LEN];
static uint8_t param_index = 0;

static void discardPendingSpi(void)
{
    uint8_t byte;
    while (spi_is_readable(SPIPORT)) {
        spi_read_blocking(SPIPORT, 0, &byte, 1);
    }
}

static void resetParamParser(void)
{
    param_state = PARAM_WAIT_SYNC0;
    param_index = 0;
}

static void applyParamPayload(synthUiState *ui_state)
{
    if (ui_state == NULL) {
        return;
    }

    ui_state->pitch = param_payload[0];
    ui_state->lowpass = param_payload[1] & 0x0F;
    ui_state->highpass = param_payload[2] & 0x0F;
    ui_state->attack = param_payload[3] & 0x0F;
    ui_state->decay = param_payload[4] & 0x0F;
    ui_state->sustain = param_payload[5] & 0x0F;
    ui_state->release = param_payload[6] & 0x0F;
    ui_state->square_on = (param_payload[7] & 0x01) != 0;
    ui_state->saw_on = (param_payload[7] & 0x02) != 0;
}

static uint8_t handleSpiByte(uint8_t byte, synthUiState *ui_state)
{
    uint8_t audio_byte = byte;

    if (param_state == PARAM_WAIT_SYNC0) {
        if (byte == PARAM_SYNC0) {
            param_state = PARAM_WAIT_SYNC1;
            audio_byte = AUDIO_IDLE;
        }
    } else if (param_state == PARAM_WAIT_SYNC1) {
        if (byte == PARAM_SYNC1) {
            param_state = PARAM_WAIT_SYNC2;
            audio_byte = AUDIO_IDLE;
        } else {
            param_state = PARAM_WAIT_SYNC0;
        }
    } else if (param_state == PARAM_WAIT_SYNC2) {
        if (byte == PARAM_SYNC2) {
            param_state = PARAM_READ_PAYLOAD;
            param_index = 0;
            audio_byte = AUDIO_IDLE;
        } else {
            param_state = PARAM_WAIT_SYNC0;
        }
    } else if (param_state == PARAM_READ_PAYLOAD) {
        param_payload[param_index] = byte;
        param_index++;
        audio_byte = AUDIO_IDLE;

        if (param_index == PARAM_PAYLOAD_LEN) {
            applyParamPayload(ui_state);
            resetParamParser();
        }
    } else {
        resetParamParser();
    }

    return audio_byte;
}

static void drainPendingParams(synthUiState *ui_state)
{
    while (spi_is_readable(SPIPORT)) {
        uint8_t byte = 0;
        spi_read_blocking(SPIPORT, 0, &byte, 1);
        handleSpiByte(byte, ui_state);
    }
}

int main(void)
{
    stdio_init_all();

    synthUiState ui_state = {
        .attack = 0,
        .decay = 0,
        .sustain = 15,
        .release = 0,
        .pitch = 12,
        .lowpass = 0,
        .highpass = 0,
        .square_on = false,
        .saw_on = false
    };

    spi_init(SPIPORT, BAUDRATE);
    spi_set_format(SPIPORT, 8, SPI_CPOL_0, SPI_CPHA_0, SPI_MSB_FIRST);
    spi_set_slave(SPIPORT, true);

    gpio_set_function(SPISCKPIN, GPIO_FUNC_SPI);
    gpio_set_function(SPIRXPIN, GPIO_FUNC_SPI);
    gpio_set_function(SPICSPIN, GPIO_FUNC_SPI);
    gpio_pull_up(SPICSPIN);

    gpio_init(PINLED);
    gpio_set_dir(PINLED, GPIO_OUT);
    gpio_put(PINLED, 0);

    synthUiInit();
    synthUiRefresh(&ui_state);

    bool streaming = false;
    absolute_time_t next_display_update = make_timeout_time_ms(DISPLAY_UPDATE_MS);

    while (true) {
        if (time_reached(next_display_update)) {
            drainPendingParams(&ui_state);
            synthUiRefresh(&ui_state);
            resetParamParser();
            discardPendingSpi();
            next_display_update = make_timeout_time_ms(DISPLAY_UPDATE_MS);
        }

        if (!streaming) {
            drainPendingParams(&ui_state);
            gpio_put(PINLED, 0);

            if (stdio_usb_connected()) {
                int ch = getchar_timeout_us(0);
                if (ch == HOSTSTART) {
                    puts_raw("SQW1");
                    stdio_flush();
                    streaming = true;
                    gpio_put(PINLED, 1);
                }
            }

            sleep_ms(1);
        } else {
            uint8_t sample = 0;
            spi_read_blocking(SPIPORT, 0, &sample, 1);
            putchar_raw(handleSpiByte(sample, &ui_state));
        }
    }

    return 0;
}
