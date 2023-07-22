typedef struct _Color {
  unsigned char r;
  unsigned char g;
  unsigned char b;
} Color;

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


Vector times(Vector v, float f) {
  Vector r;
  r.x = f * v.x;
  r.y = f * v.y;
  r.z = f * v.z;
  return r;
}

Vector sub(Vector minuend, Vector subtrahend) {
  Vector r;
  r.x = minuend.x - subtrahend.x;
  r.y = minuend.y - subtrahend.y;
  r.z = minuend.z - subtrahend.z;
  return r;
}

Vector add(Vector v1, Vector v2) {
  Vector r;
  r.x = v1.x + v2.x;
  r.y = v1.y + v2.y;
  r.z = v1.z + v2.z;
  return r;
}

Vector unitVector(Vector v) {
  float length = half_rsqrt(v.x * v.x + v.y * v.y + v.z * v.z);
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
  Color color;
} Triangle;

float getIntersection(Triangle t, Ray r) {
  const float EPSILON = 0.0000001f;
  Vector edge1 = sub(t.v1, t.v0);
  Vector edge2 = sub(t.v2, t.v0);

  Vector h = cross(r.direction, edge2);
  float a = dot(edge1, h);

  if (fabs(a) < EPSILON)
    return INFINITY;

  float f = 1.0f / a;

  Vector s = sub(r.origin, t.v0);
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


__kernel void render(__global Color* img, Viewport viewport, __constant Triangle* triangles, unsigned int triangles_size) {
  unsigned short x = get_global_id(0);
  unsigned short y = get_global_id(1);

  Point viewport_point = add(add(viewport.upperLeft, times(viewport.vectorX, x)), times(viewport.vectorY, y));
  Ray ray = { viewport.eyepoint, unitVector(sub(viewport_point, viewport.eyepoint)) };

  float min_distance = INFINITY;
  Color color = {40, 40, 40};
  for (unsigned int i = 0; i < triangles_size; i++) {
    float distance = getIntersection(triangles[i], ray);
    if (distance < min_distance) {
      min_distance = distance;
      color = triangles[i].color;
    }
  }

  img[y * get_global_size(0) + x] = color;
}
