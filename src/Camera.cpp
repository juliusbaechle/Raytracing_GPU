#include "Camera.h"
#include <cmath>

Viewport toViewport(Camera camera) {
  const Vector vectorX = rotateY({1, 0, 0}, camera.angleY);
  const Vector vectorY = rotateY(rotateX({0, -1, 0}, camera.angleX), camera.angleY);
  const float distance = (camera.resolution.x / 2) / tan(camera.viewAngleY / 2);
  const Point viewport_center = times(rotateY(rotateX({0, 0, -1}, camera.angleX), camera.angleY), distance);
  const Point viewport_upper_left = sub(viewport_center, add(times(vectorX, 0.5 * camera.resolution.x), times(vectorY, 0.5 * camera.resolution.y)));
  return { viewport_upper_left, vectorX, vectorY, camera.eyepoint };
}
