#ifndef DISPLAY_SPI_H
#define DISPLAY_SPI_H

#include <stdint.h>
#include <stdbool.h>

#define DISP_W 480
#define DISP_H 272

void display_spi_init(void);
void display_spi_fill(uint8_t code);
void display_spi_blit(uint16_t x, uint16_t y, uint16_t w, uint16_t h,
                      const uint16_t *pixels, uint16_t stride);
void display_spi_solid(uint16_t color);

#endif
