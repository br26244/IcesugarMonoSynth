#ifndef SYNTH_UI_H
#define SYNTH_UI_H

#include <stdbool.h>
#include <stdint.h>

typedef struct {
    uint8_t attack;
    uint8_t decay;
    uint8_t sustain;
    uint8_t release;
    uint8_t pitch;
    uint8_t lowpass;
    uint8_t highpass;
    bool square_on;
    bool saw_on;
} synthUiState;

void synthUiInit(void);
void synthUiRefresh(const synthUiState *state);

#endif
