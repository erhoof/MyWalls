#ifndef IMAGEDOWNLOADER_H
#define IMAGEDOWNLOADER_H

#include <QObject>
#include <QNetworkAccessManager>

class ImageDownloader : public QObject
{
    Q_OBJECT
public:
    explicit ImageDownloader(QObject *parent = nullptr);

    Q_INVOKABLE void downloadImage(const QString &url);
    Q_INVOKABLE void removeImage(const QString &url);
    Q_INVOKABLE bool isImageDownloaded(const QString &url);
    Q_INVOKABLE QString getImagePath(const QString &url);

signals:
    void imageDownloaded(QString filepath);

private:
    QString lastPath;
    QNetworkAccessManager *manager;

private slots:
    void onFileDownloaded(QNetworkReply *reply);
};

#endif // IMAGEDOWNLOADER_H
