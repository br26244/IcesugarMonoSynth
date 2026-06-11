#include "display_spi.h"

#include "hardware/gpio.h"
#include "hardware/spi.h"
#include "hardware/sync.h"
#include "pico/stdlib.h"

#define SPI_PORT spi0
#define PIN_SCK  18
#define PIN_MOSI 19
#define PIN_CS   17

#define SPI_BAUD     1000000u
#define BLIT_MAX     255u
#define USE_BITBANG  1

#if USE_BITBANG
static void bb_byte(uint8_t b)
{
    for (int i = 7; i >= 0; i--) {
        gpio_put(PIN_MOSI, (b >> i) & 1);
        sleep_us(2);
        gpio_put(PIN_SCK, 1);
        sleep_us(2);
        gpio_put(PIN_SCK, 0);
    }
}

static void bb_write(const uint8_t *data, size_t len)
{
    for (size_t i = 0; i < len; i++) {
        bb_byte(data[i]);
    }
}
#endif

static void cs_begin(void)
{
    gpio_put(PIN_CS, 0);
}

static void cs_end(void)
{
    gpio_put(PIN_CS, 1);
}

void display_spi_init(void)
{
#if USE_BITBANG
    gpio_init(PIN_SCK);
    gpio_init(PIN_MOSI);
    gpio_set_dir(PIN_SCK, GPIO_OUT);
    gpio_set_dir(PIN_MOSI, GPIO_OUT);
    gpio_put(PIN_SCK, 0);
    gpio_put(PIN_MOSI, 0);
#else
    spi_init(SPI_PORT, SPI_BAUD);
    spi_set_format(SPI_PORT, 8, SPI_CPOL_0, SPI_CPHA_0, SPI_MSB_FIRST);
    gpio_set_function(PIN_SCK, GPIO_FUNC_SPI);
    gpio_set_function(PIN_MOSI, GPIO_FUNC_SPI);
#endif

    gpio_init(PIN_CS);
    gpio_set_dir(PIN_CS, GPIO_OUT);
    gpio_put(PIN_CS, 1);
}

void display_spi_fill(uint8_t code)
{
    const uint8_t cmd[] = { 0xAA, code, 0x55 };

    cs_begin();
#if USE_BITBANG
    bb_write(cmd, sizeof cmd);
#else
    spi_write_blocking(SPI_PORT, cmd, sizeof cmd);
#endif
    cs_end();
    sleep_ms(800);
}

static void blit_chunk(uint16_t x, uint16_t y, uint8_t w, uint8_t h,
                       const uint16_t *pixels, uint16_t stride)
{
    uint8_t hdr[6] = {
        0xBB,
        (uint8_t)x,
        (uint8_t)y,
        (uint8_t)(y >> 8),
        w,
        h
    };

    cs_begin();
#if USE_BITBANG
    bb_write(hdr, sizeof hdr);
#else
    spi_write_blocking(SPI_PORT, hdr, sizeof hdr);
#endif

    for (uint8_t row = 0; row < h; row++) {
        const uint16_t *line = pixels + (size_t)row * stride;
        for (uint8_t col = 0; col < w; col++) {
            uint16_t c = line[col];
            uint8_t px[2] = { (uint8_t)(c & 0xFF), (uint8_t)(c >> 8) };
#if USE_BITBANG
            bb_write(px, 2);
#else
            spi_write_blocking(SPI_PORT, px, 2);
#endif
        }
    }

    cs_end();
}

void display_spi_blit(uint16_t x, uint16_t y, uint16_t w, uint16_t h,
                      const uint16_t *pixels, uint16_t stride)
{
    if (w == 0 || h == 0 || y >= DISP_H) {
        return;
    }

    uint32_t irq = save_and_disable_interrupts();

    for (uint16_t row = 0; row < h; row += BLIT_MAX) {
        uint8_t chunk_h;
        if (h - row > BLIT_MAX) {
            chunk_h = (uint8_t)BLIT_MAX;
        } else {
            chunk_h = (uint8_t)(h - row);
        }

        for (uint16_t col = 0; col < w; col += BLIT_MAX) {
            uint8_t chunk_w;
            if (w - col > BLIT_MAX) {
                chunk_w = (uint8_t)BLIT_MAX;
            } else {
                chunk_w = (uint8_t)(w - col);
            }

            const uint16_t *src = pixels + (size_t)row * stride + col;
            blit_chunk(x + col, y + row, chunk_w, chunk_h, src, stride);
        }
    }

    restore_interrupts(irq);
}

void display_spi_solid(uint16_t color)
{
    static uint16_t row[DISP_W];

    for (int i = 0; i < DISP_W; i++) {
        row[i] = color;
    }

    for (int y = 0; y < DISP_H; y++) {
        display_spi_blit(0, (uint16_t)y, DISP_W, 1, row, DISP_W);
    }
}
