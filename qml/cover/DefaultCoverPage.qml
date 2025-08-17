import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0
import Nemo.DBus 2.0
import Nemo.Notifications 1.0

import ru.erhoof.imagedownloader 1.0

Cover {
    id: cover
    objectName: "defaultCover"

    anchors.fill: parent
    transparent: true

    property int currentImage: 0
    property int perPage: 24

    Notification {
        id: notification

        summary: qsTr("My Walls")
    }

    Component.onCompleted: {
        var xhr = new XMLHttpRequest();
        var request = 'https://wallhaven.cc/api/v1/search?sorting=toplist&topRange=1w';

        xhr.open("GET", request, true);

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    var jsonResponse = JSON.parse(xhr.responseText);

                    var i = 0;
                    for (var key in jsonResponse.data) {
                        wallModel.append({
                            id: jsonResponse.data[key].id,
                            thumbnail: jsonResponse.data[key].thumbs.small,
                            fullImage: jsonResponse.data[key].path,
                            resX: jsonResponse.data[key].dimension_x,
                            resY: jsonResponse.data[key].dimension_y,
                            createdAt: jsonResponse.data[key].created_at,
                            category: jsonResponse.data[key].category,
                            fileSize: jsonResponse.data[key].file_size,
                            views: jsonResponse.data[key].views,
                            favorites: jsonResponse.data[key].favorites
                        });
                    }

                    //per_page = jsonResponse.meta.per_page
                    image.updateImage();
                }
            }
        };

        xhr.send();
    }

    DBusInterface {
        id: ambienceInterface
        service: "com.jolla.ambienced"
        iface: "com.jolla.ambienced"
        path: "/com/jolla/ambienced"
    }

    ImageDownloader {
        id: imgDownloader

        onImageDownloaded: {
            downloadIndicator.running = false;

            if (filepath === "") {
                return;
            }

            var path = imgDownloader.getImagePath(wallModel.get(cover.currentImage).fullImage);

            ambienceInterface.call("setAmbience", ["file://" + path],
                function(result) {
                },
                function(error) {
                    console.log("Error setting ambience: " + error);
                    notification.body = qsTr("Ambience set error")
                    notification.publish()
                }
            );
        }
    }

    ListModel {
        id: wallModel
        property var id
        property var thumbnail
        property var fullImage
        property var resX
        property var resY
        property var createdAt
        property var category
        property var fileSize
        property var views
        property var favorites
    }

    Image {
        id: image
        x: (parent.orientation === Cover.Vertical) ? (parent.width - width) / 2 : Theme.paddingMedium * 4
        width: Math.min(parent.width, parent.height - coverActionArea.height) - Theme.paddingSmall
        height: width
        fillMode: Image.PreserveAspectCrop

        function updateImage() {
            source = wallModel.get(currentImage).thumbnail
            imageResolution.text = wallModel.get(currentImage).resX + "x" + wallModel.get(currentImage).resY
            imageViews.text = qsTr("Views: ") + wallModel.get(currentImage).views
            imageFavorites.text = qsTr("Favorites: ") + wallModel.get(currentImage).favorites
        }

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: image.width
                height: image.height
                radius: 10
            }
        }

        BusyIndicator {
            id: busyIndicator
            size: BusyIndicatorSize.Medium
            anchors.centerIn: image
            running: image.status != Image.Ready
        }

        BusyIndicator {
            id: downloadIndicator
            size: BusyIndicatorSize.Medium
            anchors.centerIn: image
        }
    }

    Label {
        id: imageResolution
        x: image.x + image.width + Theme.paddingMedium
        visible: (parent.orientation === Cover.Horizontal)
    }

    Label {
        id: imageViews
        y: imageResolution.y + imageResolution.height + Theme.paddingSmall
        x: image.x + image.width + Theme.paddingMedium
        font.pixelSize: Theme.fontSizeExtraSmall
        visible: (parent.orientation === Cover.Horizontal)
    }

    Label {
        id: imageFavorites
        y: imageViews.y + imageViews.height + Theme.paddingSmall
        x: image.x + image.width + Theme.paddingMedium
        font.pixelSize: Theme.fontSizeExtraSmall
        visible: (parent.orientation === Cover.Horizontal)
    }

    CoverActionList {
        CoverAction {
            iconSource: (cover.currentImage === 0) ? "" : "image://theme/icon-cover-previous"
            onTriggered: {
                if (cover.currentImage === 0) return

                cover.currentImage--;
                image.updateImage()
            }
        }

        CoverAction {
            iconSource: "image://theme/icon-cover-copy"

            onTriggered: {
                downloadIndicator.running = true;

                notification.body = qsTr("Downloading image")
                notification.publish()
                imgDownloader.downloadImage(wallModel.get(cover.currentImage).fullImage)
            }
        }

        CoverAction {
            iconSource: (cover.currentImage === cover.perPage - 1) ? "" : "image://theme/icon-cover-next"
            onTriggered: {
                if (cover.currentImage === cover.perPage - 1) return

                cover.currentImage++;
                image.updateImage()
            }
        }
    }
}
