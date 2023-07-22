#pragma once

typedef struct _Vector {
  float x;
  float y;
  float z;
} Vector;

typedef Vector Point;

typedef struct _Ray {
  Point origin;
  Vector direction;
} Ray;


Vector times(Vector v, float f);
Vector sub(Vector minuend, Vector subtrahend);
Vector add(Vector v1, Vector v2);
Vector unitVector(Vector v);
Vector cross(Vector v1, Vector v2);
float dot(Vector v1, Vector v2);
Vector rotateX(Vector v, float f);
Vector rotateY(Vector v, float f);
Vector rotateZ(Vector v, float f);
