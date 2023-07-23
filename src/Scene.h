#pragma once

#include "Vector.h"
#include "Color.h"

struct Triangle {
  Point v0;
  Point v1;
  Point v2;
  Color color;
  bool reflective;
};

struct Sphere {
  Point center;
  float radius;
  Color color;
  bool reflective;
};

struct Scene {
  uint32_t num_triangles;
  Triangle* triangles;
  uint32_t num_spheres;
  Sphere* spheres;
  Sphere light_source;
};
