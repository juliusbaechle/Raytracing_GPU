#define sqr(a) ((a)*(a))
#define EPSILON 0.0001f // used to counteract numeric noise

typedef float3 Vector;
typedef float3 Point;

typedef struct _Ray {
  Point origin;
  Vector direction;
} Ray;

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

float intersectTriangle(Triangle t, const Ray* r) {
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

float intersectSphere(Sphere s, const Ray* r) {
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

uchar4 addColor(uchar4 color1, uchar4 color2) {
  uchar4 r;
  r.x = color1.x + color2.x;
  r.y = color1.y + color2.y;
  r.z = color1.z + color2.z;
  r.w = 255;
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

Intersection intersect(const Scene* scene, const Ray* ray) {
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

float getLight(const Scene* scene, const Intersection* isct) {
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

Ray reflect(const Ray* ray, const Intersection* isct) {
  return (Ray) { isct->point, ray->direction - 2 * dot(ray->direction, isct->normal) * isct->normal };
}

#define MAX_STACK_SIZE 10

typedef struct _RayStack {
  Ray rays[MAX_STACK_SIZE];
  float weights[MAX_STACK_SIZE];
  uchar4 colors[MAX_STACK_SIZE];
  uint pointer;
  uint size;
} RayStack;

void refract(RayStack* stack, const Intersection* isct, float refrIndex) {
  const Ray* ray = &stack->rays[stack->pointer];
  float cosI = fabs(dot(isct->normal, ray->direction));
  float index = dot(isct->normal, ray->direction) < 0.0f ? 1.0f / refrIndex : refrIndex / 1.0f;
  float cosT = sqrt(1.0f - sqr(index) * (1.0f - sqr(cosI)));
  float3 direction = (index * ray->direction) + (index * cosI - cosT) * isct->normal;
  Ray transmissedRay = (Ray){ isct->point, fast_normalize(direction) };

  if (index > 1.0f) {
    stack->rays[stack->pointer] = transmissedRay;
    stack->weights[stack->pointer] = 1.0f;
  } else {
  float coeff = sqr((index * cosI - cosT) / (index * cosI + cosT));
  stack->rays[stack->pointer] = transmissedRay;
    stack->weights[stack->pointer] = (1.0f - coeff);
    stack->rays[stack->size] = reflect(ray, isct);
    stack->weights[stack->size] = coeff;
  stack->size++;
  }
}

uchar4 raytrace(const Scene* scene, const Ray* ray) {
  RayStack stack;
  stack.size = 1;
  stack.pointer = 0;
  stack.rays[stack.pointer] = *ray;
  stack.weights[stack.pointer] = 1.0f;
  uint counter = 0;

  while (stack.pointer < stack.size && stack.pointer < MAX_STACK_SIZE - 1 && counter < 20) {
    Intersection isct = intersect(scene, &stack.rays[stack.pointer]);
    if (isct.reflective) {
    stack.rays[stack.pointer] = reflect(&stack.rays[stack.pointer], &isct);
  } else if (isct.refractive) {
    refract(&stack, &isct, 1.52f);
    } else {
    stack.colors[stack.pointer] = dimmColor(isct.color, getLight(scene, &isct));
    stack.pointer++;
  }
  counter++;
  }

  uchar4 color = {0, 0, 0, 255};
  for (int i = 0; i < stack.size; i++)
    color = addColor(color, dimmColor(stack.colors[i], stack.weights[i]));
  return color;
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
