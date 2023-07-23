typedef float3 Vector;
typedef float3 Point;

typedef struct _Ray {
  Point origin;
  Vector direction;
} Ray;

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

typedef struct _Viewport {
  Point upperLeft;
  Vector vectorX;
  Vector vectorY;
  Point eyepoint;
} Viewport;

typedef struct _Triangle {
  Point v0;
  Point v1;
  Point v2;
  uchar4 color;
} Triangle;

float getIntersection(Triangle t, Ray r) {
  const float EPSILON = 0.0000001f;
  Vector edge1 = t.v1 - t.v0;
  Vector edge2 = t.v2 - t.v0;

  Vector h = cross(r.direction, edge2);
  float a = dot(edge1, h);

  if (fabs(a) < EPSILON)
    return INFINITY;

  float f = 1.0f / a;

  Vector s = r.origin - t.v0;
  float u = f * dot(s, h);
  if (u < 0.0f || u > 1.0f)
    return INFINITY;

  Vector q = cross(s, edge1);
  float v = f * dot(r.direction, q);
  if (v < 0.0f || u + v > 1.0f)
    return INFINITY;

  float d = f * dot(edge2, q);
  if (d < EPSILON)
    return INFINITY;
  return d;
}


__kernel void render(__global uchar4* img, Viewport viewport, __constant Triangle* triangles, unsigned int triangles_size) {
  unsigned short x = get_global_id(0);
  unsigned short y = get_global_id(1);

  Point viewport_point = viewport.upperLeft + x * viewport.vectorX + y * viewport.vectorY;
  Ray ray = { viewport.eyepoint, fast_normalize(viewport_point - viewport.eyepoint) };

  float min_distance = INFINITY;
  uchar4 color = {40, 40, 40, 255};
  for (unsigned int i = 0; i < triangles_size; i++) {
    float distance = getIntersection(triangles[i], ray);
    if (distance < min_distance) {
      min_distance = distance;
      color = triangles[i].color;
    }
  }

  img[y * get_global_size(0) + x] = color;
}
