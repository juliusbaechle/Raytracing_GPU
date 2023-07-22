#include "Raytracer.h"
#include <iostream>
#include <QFile>
#include <QTextStream>

#define FATAL_ERROR(msg, err) { std::cout << msg << " " << err << std::endl; std::exit(-1); }

QList<QString> files = {
  "Raytracer.cl"
};

Raytracer::Raytracer() {
  cl_uint num_platforms;
  auto err = clGetPlatformIDs(0, NULL, &num_platforms);
  if (err != CL_SUCCESS)
    FATAL_ERROR("clGetPlatformIDs", err);
  if (num_platforms == 0)
    FATAL_ERROR("clGetPlatformIDs() error: num platforms!", 0);

  auto platforms = (cl_platform_id*)malloc(num_platforms * sizeof(cl_platform_id));
  if (platforms == NULL)
    FATAL_ERROR("malloc", ENOMEM);

  err = clGetPlatformIDs(num_platforms, platforms, &num_platforms);
  if (err != CL_SUCCESS)
    FATAL_ERROR("clGetPlatFormIDs", err);
  if (platforms == NULL)
    FATAL_ERROR("clGetPlatformIDs() error: platform!", 0);

  auto platform = platforms[1];
  err = clGetDeviceIDs(platform, CL_DEVICE_TYPE_ALL, 0, NULL, &num_platforms);
  if (err != CL_SUCCESS)
    FATAL_ERROR("clGetDeviceIDs", err);

  cl_device_id dev_id;
  err = clGetDeviceIDs(platform, CL_DEVICE_TYPE_GPU, 1, &dev_id, NULL);
  if (err != CL_SUCCESS)
    FATAL_ERROR("clGetDeviceIDs", err);

  m_context = clCreateContext(NULL, 1, &dev_id, NULL, NULL, &err);
  if (!m_context || err != CL_SUCCESS)
    FATAL_ERROR("clCreateContext", err);

  m_commands = clCreateCommandQueueWithProperties(m_context, dev_id, 0, &err);
  if (!m_commands || err != CL_SUCCESS)
    FATAL_ERROR("clCreateCommandQueue", err);

  const char** strings = load(files);
  cl_program program = clCreateProgramWithSource(m_context, files.size(), strings, NULL, &err);
  if (program == NULL || err != CL_SUCCESS)
    FATAL_ERROR("clCreateProgramWithSource", err);

  err = clBuildProgram(program, 0, NULL, NULL, NULL, NULL);
  if (err != CL_SUCCESS) {
    size_t len;
    clGetProgramBuildInfo(program, dev_id, CL_PROGRAM_BUILD_LOG, 0, NULL, &len);
    char* build_log = (char*)malloc(len);
    clGetProgramBuildInfo(program, dev_id, CL_PROGRAM_BUILD_LOG, len, build_log, NULL);
    printf("Build Info Log (len:%zd):\n%s", len, build_log);
    FATAL_ERROR("clBuildProgram", err);
  }

  m_kernel = clCreateKernel(program, "render", &err);
  if (m_kernel == NULL || err != CL_SUCCESS)
    FATAL_ERROR("clCreateKernel", err);
}

const char** Raytracer::load(QList<QString> files) {
  const char** arr = new const char* [files.size()];
  for (int i = 0; i < files.size(); i++)
    arr[i] = load(files[i]);
  return arr;
}

const char* Raytracer::load(QString filename) {
  QFile file(filename);
  assert(file.open(QIODevice::ReadOnly));
  QString str = QTextStream(&file).readAll();
  char* buf = new char[str.length()];
  strcpy(buf, str.toStdString().c_str());
  return buf;
}

void Raytracer::setResolution(Resolution resolution) {
  if(m_img.buf)
    delete[] m_img.buf;
  m_img.resolution = resolution;
  m_img.buf = new cl_uchar3[resolution.x * resolution.y];

  if(m_cl_image)
    clReleaseMemObject(m_cl_image);
  cl_int err;
  m_cl_image = clCreateBuffer(m_context, CL_MEM_WRITE_ONLY, sizeof(Color) * resolution.x * resolution.y, nullptr, &err);
  if (err != CL_SUCCESS)
    FATAL_ERROR("clCreateImage", err);

  err = clSetKernelArg(m_kernel, 0, sizeof(cl_mem), &m_cl_image);
  if (err != CL_SUCCESS)
    FATAL_ERROR("clSetKernelArg", err);
}

void Raytracer::setScene(const Scene scene) {
  if(m_cl_triangles)
    clReleaseMemObject(m_cl_triangles);

  auto cl_triangles = clCreateBuffer(m_context, CL_MEM_READ_ONLY, sizeof(Triangle) * scene.size, NULL, NULL);
  auto err = clEnqueueWriteBuffer(m_commands, cl_triangles, CL_TRUE, 0, sizeof(Triangle) * scene.size, scene.triangles, 0, NULL, NULL);
  if (err != CL_SUCCESS)
    FATAL_ERROR("clEnqueueWriteBuffer", err);

  err = clSetKernelArg(m_kernel, 2, sizeof(cl_mem), &cl_triangles);
  if (err != CL_SUCCESS)
    FATAL_ERROR("clSetKernelArg", err);

  err = clSetKernelArg(m_kernel, 3, sizeof(unsigned int), &scene.size);
  if (err != CL_SUCCESS)
    FATAL_ERROR("clSetKernelArg", err);
}

const Image& Raytracer::render(const Camera camera) {
  Viewport viewport = toViewport(camera);
  auto err = clSetKernelArg(m_kernel, 1, sizeof(Viewport), &viewport);
  if (err != CL_SUCCESS)
    FATAL_ERROR("clSetKernelArg", err);

  const size_t global_size[] = { m_img.resolution.x, m_img.resolution.y };
  err = clEnqueueNDRangeKernel(m_commands, m_kernel, 2, NULL, global_size, NULL, 0, NULL, NULL);
  if (err != CL_SUCCESS)
    FATAL_ERROR("clEnqueueNDRangeKernel", err);

  err = clEnqueueReadBuffer(m_commands, m_cl_image, CL_TRUE, 0, sizeof(Color) * m_img.resolution.x * m_img.resolution.y, m_img.buf, 0, NULL, NULL);
  if (err != CL_SUCCESS)
    FATAL_ERROR("clEnqueueReadBuffer", err);

  clFinish(m_commands);
  return m_img;
}
