#pragma once

#include "Resolution.h"
#include "Color.h"

struct Image {
  Color* buf;
  Resolution resolution;
};
