#pragma once

#include <QApplication>
#include <QMouseEvent>
#include <QCursor>
#include <QTimer>
#include <QFlags>
#include <iostream>
#include "Camera.h"

#define DEG_TO_RAD (M_PI / 180)

enum class Direction { Forward = 1, Right = 2, Backward = 4, Left = 8 };

class Controller : public QObject {
public:
  Controller(Resolution resolution)
    : cursor(Qt::BlankCursor)
    , directions({})
  {
    this->resolution = resolution;
    cursor.setPos(resolution.x / 2, resolution.y / 2);
    QApplication::setOverrideCursor(cursor);

    QObject::connect(&timer, &QTimer::timeout, this, &Controller::updatePosition);
    timer.start(10);
  }

  Camera getCamera() const {
    return Camera {
      position,
      angleX,
      angleY,
      DEG_TO_RAD * 100.0,
      resolution
    };
  }

private:
  bool eventFilter(QObject* obj, QEvent* event) {
    if (event->type() == QEvent::MouseMove) {
      QMouseEvent* e = static_cast<QMouseEvent*>(event);
      angleY -= (e->pos().x() - (resolution.x / 2)) / (float) resolution.x;
      angleX -= (e->pos().y() - (resolution.y / 2)) / (float) resolution.y;
      cursor.setPos(resolution.x / 2, resolution.y / 2);
      return true;
    }
    if (event->type() == QEvent::KeyPress) {
      QKeyEvent* e = static_cast<QKeyEvent*>(event);
      if(e->key() == Qt::Key::Key_E)
        directions.setFlag(Direction::Forward, true);
      if(e->key() == Qt::Key::Key_F)
        directions.setFlag(Direction::Right, true);
      if(e->key() == Qt::Key::Key_D)
        directions.setFlag(Direction::Backward, true);
      if(e->key() == Qt::Key::Key_S)
        directions.setFlag(Direction::Left, true);
    }
    if (event->type() == QEvent::KeyRelease) {
      QKeyEvent* e = static_cast<QKeyEvent*>(event);
      if(e->key() == Qt::Key::Key_E)
        directions.setFlag(Direction::Forward, false);
      if(e->key() == Qt::Key::Key_F)
        directions.setFlag(Direction::Right, false);
      if(e->key() == Qt::Key::Key_D)
        directions.setFlag(Direction::Backward, false);
      if(e->key() == Qt::Key::Key_S)
        directions.setFlag(Direction::Left, false);
    }
    return false;
  }

  void updatePosition() {
    auto vForward = rotateY({0, 0, -1}, angleY);
    if(directions.testFlag(Direction::Forward))
      position = add(position, vForward);
    if(directions.testFlag(Direction::Backward))
      position = add(position, times(vForward, -1));

    auto vRight = rotateY({1, 0, 0}, angleY);
    if(directions.testFlag(Direction::Right))
      position = add(position, vRight);
    if(directions.testFlag(Direction::Left))
      position = add(position, times(vRight, -1));
  }

private:
  float angleX = 0.0;
  float angleY = 0.0;
  Resolution resolution;
  QCursor cursor;
  QTimer timer;
  Point position = {0, 0, 0};
  QFlags<Direction> directions;
};
