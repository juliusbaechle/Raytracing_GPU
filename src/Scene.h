#pragma once

#include "Vector.h"
#include "Color.h"

struct Triangle {
  Point v0;
  Point v1;
  Point v2;
  Color color;
};

struct Scene {
  uint32_t size;
  Triangle* triangles;
};

float getIntersection(Triangle t, Ray r);
