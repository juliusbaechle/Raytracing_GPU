#include "Scene.h"
#include <cmath>

#define EPSILON 0.0000001

float getIntersection(Triangle t, Ray r) {
  auto edge1 = sub(t.v1, t.v0);
  auto edge2 = sub(t.v2, t.v0);

  auto h = cross(r.direction, edge2);
  auto a = dot(edge1, h);

  if (fabs(a) < EPSILON)
    return INFINITY;

  auto f = 1.0 / a;

  auto s = sub(r.origin, t.v0);
  auto u = f * dot(s, h);
  if (u < 0.0 || u > 1.0)
    return INFINITY;

  auto q = cross(s, edge1);
  auto v = f * dot(r.direction, q);
  if (v < 0.0 || u + v > 1.0)
    return INFINITY;

  float d = f * dot(edge2, q);
  if (d < EPSILON)
    return INFINITY;
  return d;
}

inline float sqr(float f) { return f * f; }

float getIntersection(Sphere s, Ray r) {
  float a = sqr(r.direction.x) + sqr(r.direction.y) + sqr(r.direction.z);
  float b = 2 * (r.direction.x * (r.origin.x - s.center.x) + r.direction.y * (r.origin.y - s.center.y) + r.direction.z * (r.origin.z - s.center.z));
  float c = sqr(r.origin.x - s.center.x) + sqr(r.origin.y - s.center.y) + sqr(r.origin.z - s.center.z) - sqr(s.radius);

  float underRoot = sqr(b) - 4 * a * c;
  if (underRoot < 0)
    return INFINITY;

  float root = sqrt(underRoot);
  float x1 = (-b - root) / (2 * a);
  if (x1 > EPSILON)
    return x1;

  float x2 = (-b + root) / (2 * a);
  if (x2 > EPSILON)
    return x2;

  return INFINITY;
}
