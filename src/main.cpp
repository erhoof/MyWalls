#include <QtQuick>
#include <auroraapp.h>

#include "imagedownloader.h"

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> application(Aurora::Application::application(argc, argv));
    application->setOrganizationName(QStringLiteral("ru.erhoof"));
    application->setApplicationName(QStringLiteral("walls"));

    qmlRegisterType<ImageDownloader>("ru.erhoof.imagedownloader", 1, 0, "ImageDownloader");

    QScopedPointer<QQuickView> view(Aurora::Application::createView());
    view->setSource(Aurora::Application::pathTo(QStringLiteral("qml/walls.qml")));
    view->show();

    return application->exec();
}
