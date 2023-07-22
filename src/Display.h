#pragma once

#include <QtWidgets>
#include <QBoxLayout>
#include <QImage>
#include "Image.h"
#include "Resolution.h"

class Display : public QWidget {
public:
  Display() : QWidget(nullptr) {
    label = new QLabel(this);
    setLayout(new QVBoxLayout(this));
    layout()->addWidget(label);
    layout()->setContentsMargins(0, 0, 0, 0);
    showFullScreen();
  }

  void show(const Image& img) {
    auto qImg = QImage((uchar*) img.buf, img.resolution.x, img.resolution.y, sizeof(cl_uchar4) * img.resolution.x, QImage::Format::Format_RGBA8888);
    label->setPixmap(QPixmap::fromImage(qImg));
  }

  Resolution getResolution() const {
    return Resolution { (uint16_t) geometry().width(), (uint16_t) geometry().height() };
  }

private:
  QLabel* label = nullptr;
};
