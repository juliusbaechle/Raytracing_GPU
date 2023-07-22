#pragma once

#include "Resolution.h"
#include "Vector.h"

struct Camera {
  Point eyepoint;
  float angleX;
  float angleY;
  float viewAngleY;
  Resolution resolution;
};

struct Viewport {
  Point upperLeft;
  Vector vectorX;
  Vector vectorY;
  Point eyepoint;
};

Viewport toViewport(Camera camera);
