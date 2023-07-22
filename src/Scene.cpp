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
