#pragma once

#include <QApplication>
#include <QMouseEvent>
#include <QCursor>
#include <iostream>
#include "Camera.h"

#define DEG_TO_RAD (M_PI / 180)

class Controller : public QObject {
public:
  Controller(Resolution resolution)
    : cursor(Qt::BlankCursor)
  {
    this->resolution = resolution;
    cursor.setPos(resolution.w / 2, resolution.h / 2);
    QApplication::setOverrideCursor(cursor);
  }

  Camera getCamera() const {
    return Camera {
      {0, 0, 0},
      angleX,
      angleY,
      DEG_TO_RAD * 80.0,
      resolution
    };
  }

  bool eventFilter(QObject* obj, QEvent* event) {
    if (event->type() == QEvent::MouseMove) {
      QMouseEvent* e = static_cast<QMouseEvent*>(event);
      angleY -= (e->pos().x() - (resolution.w / 2)) / (float) resolution.w;
      angleX -= (e->pos().y() - (resolution.h / 2)) / (float) resolution.h;
      cursor.setPos(resolution.w / 2, resolution.h / 2);
      return true;
    }
    return false;
  }

private:
  float angleX = 0.0;
  float angleY = 0.0;
  Resolution resolution;
  QCursor cursor;
};
