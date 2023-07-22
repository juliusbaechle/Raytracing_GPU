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
    auto qImg = QImage((uchar*) img.buf, img.resolution.w, img.resolution.h, 3 * img.resolution.w, QImage::Format::Format_RGB888);
    label->setPixmap(QPixmap::fromImage(qImg));
  }

  Resolution getResolution() const {
    return Resolution { (uint16_t) geometry().width(), (uint16_t) geometry().height() };
  }

private:
  QLabel* label = nullptr;
};
