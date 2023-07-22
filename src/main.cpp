#include <QApplication>
#include <QThread>
#include <QCursor>
#include "Controller.h"
#include "Raytracer.h"
#include "Display.h"

Point luf {-150, 100, -200};
Point ldf {-150, -100, -200};
Point ruf {150, 100, -200};
Point rdf {150, -100, -200};
Point lub {-150, 100, 200};
Point ldb {-150, -100, 200};
Point rub {150, 100, 200};
Point rdb {150, -100, 200};

Triangle triangles[] = {
  Triangle{ ldf, ruf, luf, { 255, 0, 0, 255 } },
  Triangle{ ldf, ruf, rdf, { 255, 30, 0, 255 } },
  Triangle{ ldb, luf, lub, { 0, 255, 0, 255 } },
  Triangle{ ldb, luf, ldf, { 0, 200, 55, 255 } },
  Triangle{ rdb, ruf, rub, { 0, 255, 0, 255 } },
  Triangle{ rdb, ruf, rdf, { 0, 200, 55, 255 } },
  Triangle{ luf, rub, lub, { 0, 0, 255, 255 } },
  Triangle{ luf, rub, ruf, { 0, 55, 200, 255 } },
  Triangle{ ldf, rdb, ldb, { 0, 0, 255, 255 } },
  Triangle{ ldf, rdb, rdf, { 0, 55, 200, 255 } },
};

Scene scene = {
  10,
  triangles
};

int main(int argc, char** argv) {
  QApplication app(argc, argv);
  QDir::setCurrent(QApplication::applicationDirPath());
  Display display;
  Raytracer raytracer;
  Controller controller (display.getResolution());
  app.installEventFilter(&controller);

  QThread thread;
  std::atomic<int> counter;
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
