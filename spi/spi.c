#include <stdio.h>
#include "pico/stdlib.h"
#include "pico/stdio.h"
#include "pico/stdio_usb.h"
#include "hardware/gpio.h"
#include "hardware/spi.h"

#define SPIPORT     spi1
#define BAUDRATE 500000
#define SPISCKPIN  10
#define SPIRXPIN   12
#define SPICSPIN   13

#define PINLED      16
#define HOSTSTART   'C'  //sends c to start streaming


static void discardPendingSpi(void)
{
    uint8_t byte;
    while (spi_is_readable(SPIPORT)) {
        spi_read_blocking(SPIPORT, 0, &byte, 1);
    }
}

int main(void)
{
    stdio_init_all();

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

    bool streaming = false;

    while (true) {
        if (!streaming) {
            discardPendingSpi();
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
            putchar_raw(sample);
        }
    }

    return 0;
}
