#pragma once

#include <stdint.h>

struct Resolution {
  uint16_t w;
  uint16_t h;
};

static bool operator== (const Resolution& r1, const Resolution& r2) {
  return r1.w == r2.w && r1.h == r2.h;
}

static bool operator!= (const Resolution& r1, const Resolution& r2) {
  return !(r1 == r2);
}
