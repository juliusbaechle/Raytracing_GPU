#define sqr(a) ((a)*(a))
#define EPSILON 0.001f

typedef float3 Vector;
typedef float3 Point;

typedef struct _Ray {
  Point origin;
  Vector direction;
} Ray;

float angleTo(Vector v1, Vector v2) {
  float dotProduct = dot(v1, v2);
  dotProduct /= fast_length(v1);
  dotProduct /= fast_length(v2);
  if (dotProduct < -1.0f)
    dotProduct = -1.0f;
  if (dotProduct > 1.0f)
    dotProduct = 1.0f;
  return acos(dotProduct);
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
  uchar reflective;
} Triangle;

float intersectTriangle(Triangle t, Ray* r) {
  Vector edge1 = t.v1 - t.v0;
  Vector edge2 = t.v2 - t.v0;

  Vector h = cross(r->direction, edge2);
  float a = dot(edge1, h);

  if (fabs(a) < EPSILON)
    return INFINITY;

  float f = 1.0f / a;

  Vector s = r->origin - t.v0;
  float u = f * dot(s, h);
  if (u < 0.0f || u > 1.0f)
    return INFINITY;

  Vector q = cross(s, edge1);
  float v = f * dot(r->direction, q);
  if (v < 0.0f || u + v > 1.0f)
    return INFINITY;

  float d = f * dot(edge2, q);
  if (d < EPSILON)
    return INFINITY;
  return d;
}

typedef struct _Sphere {
  Point center;
  float radius;
  uchar4 color;
  uchar reflective;
  uchar refractive;
} Sphere;

float intersectSphere(Sphere s, Ray* r) {
  float3 rayToCenter = s.center - r->origin ;
  float dotProduct = dot(r->direction, rayToCenter);
  float d = sqr(dotProduct) - dot(rayToCenter,rayToCenter) + sqr(s.radius);
  if (d < EPSILON)
    return INFINITY;

  float root = half_sqrt(d);
  float t = dotProduct - root;
  if (t < EPSILON) {
    t = dotProduct + root;
    if (t < EPSILON)
      return INFINITY;
  }
  return t;
}

uchar4 dimmColor(uchar4 color, float f) {
  uchar4 r;
  r.x = f * color.x;
  r.y = f * color.y;
  r.z = f * color.z;
  r.w = color.w;
  return r;
}

typedef struct _Intersection {
  float distance;
  float3 point;
  uchar4 color;
  float3 normal;
  bool reflective;
  bool refractive;
} Intersection;

typedef struct _Scene {
  unsigned char num_triangles;
  __constant Triangle* triangles;
  unsigned char num_spheres;
  __constant Sphere* spheres;
  Sphere light_source;
} Scene;

Intersection intersect(Scene* scene, Ray* ray) {
  Intersection isct = { INFINITY, {0, 0, 0}, {40, 40, 40, 255}, {0, 0, 0}, false, false };
  for (unsigned int i = 0; i < scene->num_triangles; i++) {
  Triangle t = scene->triangles[i];
    float distance = intersectTriangle(t, ray);
    if (distance < isct.distance) {
      isct.distance = distance;
    isct.point = ray->origin + distance * ray->direction;
      isct.normal = fast_normalize(cross(t.v1 - t.v0, t.v2 - t.v0));
    isct.reflective = false;
    isct.reflective = t.reflective;
      isct.color = t.color;
    }
  }
  for (unsigned int i = 0; i < scene->num_spheres; i++) {
    Sphere s = scene->spheres[i];
    float distance = intersectSphere(s, ray);
    if (distance < isct.distance) {
      isct.distance = distance;
    isct.point = ray->origin + distance * ray->direction;
      isct.normal = fast_normalize(isct.point - s.center);
    isct.reflective = s.reflective;
    isct.refractive = s.refractive;
      isct.color = s.color;
    }
  }
  return isct;
}

float getLight(Scene* scene, Intersection* isct) {
  Ray shadow_ray = { isct->point, fast_normalize(scene->light_source.center - isct->point) };
  float distance_to_light = intersectSphere(scene->light_source, &shadow_ray);
  for (unsigned int i = 0; i < scene->num_triangles; i++)
    if (intersectTriangle(scene->triangles[i], &shadow_ray) < distance_to_light)
    return 0.0f;
  for (unsigned int i = 0; i < scene->num_spheres; i++)
    if (intersectSphere(scene->spheres[i], &shadow_ray) < distance_to_light)
    return 0.0f;
  return fabs(dot(isct->normal, shadow_ray.direction));
}

Ray reflect(Ray* ray, Intersection* isct) {
  return (Ray) { isct->point, ray->direction - 2 * dot(ray->direction, isct->normal) * isct->normal };
}

Ray refract(Ray* ray, Intersection* isct, float refrIndex) {
  float a1, n1ToN2;
  if (dot(ray->direction, isct->normal) < 0.0f) {
    a1 = angleTo(ray->direction, -1.0f * isct->normal);
    n1ToN2 = 1.0f / refrIndex;
  } else {
    a1 = angleTo(ray->direction, isct->normal);
    n1ToN2 = refrIndex / 1.0f;
  }

  float a2 = asin(min(n1ToN2 * sin(a1), 1.0f));
  float3 direction = n1ToN2 * ray->direction - (cos(a2) - n1ToN2 * cos(a1)) * isct->normal;
  return (Ray){ isct->point, fast_normalize(direction) };

  //Ray transmissedRay = (Ray){ isct.point, fast_normalize(direction) };
  //uchar4 transmissedColor = raytrace(scene, transmissedRay, traceDepth++);
  //if (n1ToN2 > 1.0f)
  //  return transmissedColor;
  //
  //Ray reflectedRay = (Ray){ isct.point, ray->direction - 2 * dot(ray->direction, isct.normal) * isct.normal };
  //uchar4 reflectedColor = raytrace(scene, reflectedRay, traceDepth++);
  //float fresnelCoeff = sqr(sin(a1 - a2) / sin(a1 + a2));
  //return dimmColor(reflectedColor, fresnelCoeff) + dimmColor(transmissedColor, (1 - fresnelCoeff));
}

#define MAX_RAYS 10

uchar4 raytrace(Scene* scene, Ray* ray) {
  for (int i = 0; i < MAX_RAYS; i++) {
    Intersection isct = intersect(scene, ray);
    if (isct.reflective)
    *ray = reflect(ray, &isct);
  else if (isct.refractive)
    *ray = refract(ray, &isct, 1.52f);
    else
    return dimmColor(isct.color, getLight(scene, &isct));
  }
  return (uchar4) { 40, 0, 0, 255 };
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
  Scene scene = { num_triangles, triangles, num_spheres, spheres, light_source };
  img[y * get_global_size(0) + x] = raytrace(&scene, &ray);
}
