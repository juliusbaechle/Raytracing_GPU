#include "Vector.h"
#include <cmath>

Vector times(Vector v, float f) {
  return {v.x * f, v.y * f, v.z * f};
}

Vector sub(Vector minuend, Vector subtrahend) {
  return {minuend.x - subtrahend.x, minuend.y - subtrahend.y, minuend.z - subtrahend.z};
}

Vector add(Vector v1, Vector v2) {
  return {v1.x + v2.x, v1.y + v2.y, v1.z + v2.z};
}

Vector normalize(Vector v) {
  float length = sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
  return times(v, 1/length);
}

Vector cross(Vector v1, Vector v2) {
  Vector v;
  v.x = v1.y * v2.z - v1.z * v2.y;
  v.y = v1.z * v2.x - v1.x * v2.z;
  v.z = v1.x * v2.y - v1.y * v2.x;
  return v;
}

float dot(Vector v1, Vector v2) {
  return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z;
}

Vector rotateX(Vector v, float f) {
  Vector r;
  r.x = v.x;
  r.y = cos(f) * v.y - sin(f) * v.z;
  r.z = sin(f) * v.y + cos(f) * v.z;
  return r;
}

Vector rotateY(Vector v, float f) {
  Vector r;
  r.x = cos(f) * v.x + sin(f) * v.z;
  r.y = v.y;
  r.z = -sin(f) * v.x + cos(f) * v.z;
  return r;
}

Vector rotateZ(Vector v, float f) {
  Vector r;
  r.x = cos(f) * v.x - sin(f) * v.y;
  r.y = sin(f) * v.x + cos(f) * v.y;
  r.z = v.z;
  return r;
}
