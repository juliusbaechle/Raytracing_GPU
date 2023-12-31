#pragma once

#include <QList>
#include <QString>

#include "Image.h"
#include "Camera.h"
#include "Scene.h"

#include <CL/cl.h>

class Raytracer {
public:
  Raytracer();
  void setResolution(Resolution resolution);
  void setScene(const Scene scene);
  const Image& render(const Camera camera);

private:
  const char** load(QList<QString> files);

private:
  cl_command_queue m_commands;
  cl_kernel m_kernel;
  cl_context m_context;
  cl_mem m_cl_image = nullptr;
  cl_mem m_cl_triangles = nullptr;
  cl_mem m_cl_spheres = nullptr;
  Image m_img { nullptr, {0, 0} };
};
