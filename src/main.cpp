#include <QApplication>
#include <QThread>
#include <QCursor>
#include "Controller.h"
#include "Raytracer.h"
#include "Display.h"

// right, up, back
Point luf {-4,  2, -8};
Point ldf {-4, -2, -8};
Point ruf { 4,  2, -8};
Point rdf { 4, -2, -8};
Point lub {-4,  2,  8};
Point ldb {-4, -2,  8};
Point rub { 4,  2,  8};
Point rdb { 4, -2,  8};

Triangle triangles[] = {
  Triangle{ ldf, ruf, luf, { 255, 0, 0, 255 }, false },
  Triangle{ ldf, ruf, rdf, { 255, 30, 0, 255 }, false },
  Triangle{ ldb, luf, lub, { 0, 255, 0, 255 }, false },
  Triangle{ ldb, luf, ldf, { 0, 200, 55, 255 }, false },
  Triangle{ rdb, ruf, rub, { 0, 255, 0, 255 }, false },
  Triangle{ rdb, ruf, rdf, { 0, 200, 55, 255 }, false },
  Triangle{ luf, rub, lub, { 0, 0, 255, 255 }, false },
  Triangle{ luf, rub, ruf, { 0, 55, 200, 255 }, false },
  Triangle{ ldf, rdb, ldb, { 0, 0, 255, 255 }, false },
  Triangle{ ldf, rdb, rdf, { 0, 55, 200, 255 }, false },
};

Sphere spheres[] = {
  Sphere{ {0, 0, -0.55}, 0.5, { 200, 200, 200, 255 }, true },
  Sphere{ {0, 0,  0.55}, 0.5, { 200, 200, 200, 255 }, true }
};

Sphere light_source { {0, 1.9, 0}, 1, {255, 255, 255, 255}, false };

Scene scene = {
  10,
  triangles,
  2,
  spheres,
  light_source
};

int main(int argc, char** argv) {
  QApplication app(argc, argv);
  QDir::setCurrent(QApplication::applicationDirPath());
  Display display;
  Raytracer raytracer;
  Controller controller (display.getResolution());
  app.installEventFilter(&controller);

  QThread thread;
  std::atomic<int> counter = 0;
  QObject::connect(&thread, &QThread::started, [&](){
    raytracer.setResolution(display.getResolution());
    raytracer.setScene(scene);
    while(!thread.isInterruptionRequested()) {
      Camera camera = controller.getCamera();
      Image img = raytracer.render(camera);
      display.show(img);
      counter++;
    }
  });

  QTimer timer (&app);
  QObject::connect(&timer, &QTimer::timeout, [&](){
    std::cout << counter.load() << " fps" << std::endl;
    counter = 0;
  });
  timer.start(1000);

  thread.start();
  app.exec();

  thread.quit();
  thread.requestInterruption();
  thread.wait();
}
