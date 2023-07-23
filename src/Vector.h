#pragma once

#include <CL/cl.h>

typedef cl_float3 Vector;
typedef cl_float3 Point;

typedef struct _Ray {
  Point origin;
  Vector direction;
} Ray;


Vector times(Vector v, float f);
Vector sub(Vector minuend, Vector subtrahend);
Vector add(Vector v1, Vector v2);
Vector normalize(Vector v);
Vector cross(Vector v1, Vector v2);
float dot(Vector v1, Vector v2);
Vector rotateX(Vector v, float f);
Vector rotateY(Vector v, float f);
Vector rotateZ(Vector v, float f);
