#include <QStandardPaths>
#include <QDir>
#include <QNetworkReply>
#include <QNetworkRequest>

#include "imagedownloader.h"

ImageDownloader::ImageDownloader(QObject *parent)
    : QObject{parent}, manager(new QNetworkAccessManager(this)) {
    connect(manager, &QNetworkAccessManager::finished, this, &ImageDownloader::onFileDownloaded);
}

void ImageDownloader::downloadImage(const QString &url) {
    auto path = QStandardPaths::writableLocation(QStandardPaths::PicturesLocation);
    QDir dir(path + "/Wall App Wallpapers/");
    if(!dir.exists()) {
        dir.mkpath(".");
    }

    QUrl qUrl(url);
    auto fullPath = path + "/Wall App Wallpapers/" + qUrl.fileName();

    QFile file(fullPath);
    if(file.exists()) {
        emit imageDownloaded(fullPath);
        return;
    }

    QNetworkRequest request(qUrl);

    lastPath = fullPath;
    manager->get(request);
}

void ImageDownloader::removeImage(const QString &url) {
    auto path = QStandardPaths::writableLocation(QStandardPaths::PicturesLocation);
    QDir dir(path + "/Wall App Wallpapers/");
    if(!dir.exists()) {
        return;
    }

    QUrl qUrl(url);
    auto fullPath = path + "/Wall App Wallpapers/" + qUrl.fileName();

    QFile file(fullPath);
    file.remove();
}

bool ImageDownloader::isImageDownloaded(const QString &url) {
    auto path = QStandardPaths::writableLocation(QStandardPaths::PicturesLocation);
    QDir dir(path + "/Wall App Wallpapers/");
    if(!dir.exists()) {
        return false;
    }

    QUrl qUrl(url);
    auto fullPath = path + "/Wall App Wallpapers/" + qUrl.fileName();

    QFile file(fullPath);
    return file.exists();
}

QString ImageDownloader::getImagePath(const QString &url) {
    auto path = QStandardPaths::writableLocation(QStandardPaths::PicturesLocation);
    QDir dir(path + "/Wall App Wallpapers/");
    if(!dir.exists()) {
        return "";
    }

    QUrl qUrl(url);
    return path + "/Wall App Wallpapers/" + qUrl.fileName();
}

void ImageDownloader::onFileDownloaded(QNetworkReply *reply) {
    if (reply->error() == QNetworkReply::NoError) {
        QFile newFile(lastPath);
        newFile.open(QIODevice::WriteOnly);
        newFile.write(reply->readAll());
        newFile.close();

        qDebug() << "Got file and saved it";
        emit imageDownloaded(lastPath);
    } else {
        qDebug() << "File request error";
        emit imageDownloaded("");
    }
    reply->deleteLater();
    lastPath = "";
}
