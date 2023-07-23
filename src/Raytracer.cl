#define sqr(a) ((a)*(a))
#define EPSILON 0.0000001f

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

typedef struct _Sphere {
  Point center;
  float radius;
  uchar4 color;
} Sphere;

float getTriangleIntersection(Triangle t, Ray r) {
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

float3 getTriangleNormal(Triangle t) {
  return fast_normalize(cross(t.v1 - t.v0, t.v2 - t.v0));
}

float getSphereIntersection(Sphere s, Ray r) {
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

float3 getSphereNormal(float3 point, Sphere s) {
  return fast_normalize(point - s.center);
}

uchar4 dimmColor(float f, uchar4 color) {
  uchar4 r;
  r.x = f * color.x;
  r.y = f * color.y;
  r.z = f * color.z;
  r.w = color.w;
  return r;
}

__kernel void render(__global uchar4* img, Viewport viewport,
  __constant Triangle* triangles, unsigned int num_triangles,
  __constant Sphere* spheres, unsigned int num_spheres,
  Sphere light_source)
{
  unsigned short x = get_global_id(0);
  unsigned short y = get_global_id(1);

  Point viewport_point = viewport.upperLeft + x * viewport.vectorX + y * viewport.vectorY;
  Ray ray = { viewport.eyepoint, fast_normalize(viewport_point - viewport.eyepoint) };

  float min_distance = INFINITY;
  uchar4 color = {40, 40, 40, 255};
  float3 normal = {0.0f, 0.0f, 0.0f};

  for (unsigned int i = 0; i < num_triangles; i++) {
    float distance = getTriangleIntersection(triangles[i], ray);
    if (distance < min_distance) {
      min_distance = distance;
      color = triangles[i].color;
    normal = getTriangleNormal(triangles[i]);
    }
  }
  for (unsigned int i = 0; i < num_spheres; i++) {
    float distance = getSphereIntersection(spheres[i], ray);
    if (distance < min_distance) {
      min_distance = distance;
      color = spheres[i].color;
    normal = getSphereNormal(ray.origin + distance * ray.direction, spheres[i]);
    }
  }

  float3 intersection = ray.origin + ray.direction * (min_distance - 0.0001f);
  Ray shadow_ray = { intersection, fast_normalize(light_source.center - intersection) };
  float min_distance2 = INFINITY;
  for (unsigned int i = 0; i < num_triangles; i++)
  min_distance2 = min(getTriangleIntersection(triangles[i], shadow_ray), min_distance2);
  for (unsigned int i = 0; i < num_spheres; i++)
  min_distance2 = min(getSphereIntersection(spheres[i], shadow_ray), min_distance2);

  if(getSphereIntersection(light_source, shadow_ray) > min_distance2) {
  color = (uchar4){ 0, 0, 0, 255 };
  } else {
  color = dimmColor(fabs(dot(normal, shadow_ray.direction)), color);
  }

  img[y * get_global_size(0) + x] = color;
}
