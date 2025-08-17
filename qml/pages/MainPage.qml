import QtQuick 2.0
import Sailfish.Silica 1.0
import Aurora.Controls 1.0
import QtGraphicalEffects 1.0
import Nemo.DBus 2.0
import Nemo.Notifications 1.0
import QtQuick.Layouts 1.1
import Sailfish.Share 1.0

import ru.erhoof.imagedownloader 1.0

Page {
    id: page
    objectName: "mainPage"
    allowedOrientations: Orientation.All

    property int currentPage: 0
    property int lastPage: 0
    property string searchQuery: ""

    Component.onCompleted: {
        requestImages("", 0)

        notice.text = "Thanks, app by @erhoof";
        notice.show()
    }

    function requestImages(searchQuery, page) {
        var xhr = new XMLHttpRequest();
        var request = 'https://wallhaven.cc/api/v1/search';
        if(searchQuery !== "") {
            request += "?q=" + searchQuery;
        }
        if(page !== 0) {
            if(searchQuery !== "") {
                request += "&page=" + page;
            } else {
                request += "?page=" + page;
            }
        }

        xhr.open("GET", request, true);

        console.log(request);

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    var jsonResponse = JSON.parse(xhr.responseText);

                    for (var key in jsonResponse.data) {
                        wallsListView.model.append({
                            id: jsonResponse.data[key].id,
                            thumbnail: jsonResponse.data[key].thumbs.large,
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

                    currentPage = jsonResponse.meta.current_page
                    lastPage = jsonResponse.meta.last_page
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

    Notice {
        id: notice

        anchor: Notice.Top
        verticalOffset: parent.height - (isPortrait ? Theme.dp(55) : Theme.dp(100))
        duration: Notice.Short
    }

    ShareAction {
        id: shareAction

        title: qsTr("Share")
    }

    AppBar {
        id: appBar

        AppBarSearchField {
            id: searchField
            placeholderText: qsTr("Search query")

            EnterKey.onClicked: {
                page.currentPage = 0;
                page.lastPage = 0;
                page.searchQuery = text;

                wallModel.clear()
                requestImages(text, 1)

                focus = false;
            }
        }
    }

    SilicaFlickable {
        id: mainFlickable
        anchors {
            top: appBar.bottom
            bottom: parent.bottom
            left: parent.left
            right: parent.right

            leftMargin: Theme.horizontalPageMargin
            //rightMargin: Theme.horizontalPageMargin
        }

        VerticalScrollDecorator {
            flickable: column
        }

        contentHeight: column.height + Theme.paddingMedium

        Column {
            id: column
            x: (parent.width - width - Theme.horizontalPageMargin) / 2
            width: Math.min(mainFlickable.width, mainFlickable.height - 260) - Theme.horizontalPageMargin
            spacing: Theme.paddingMedium

            SilicaListView {
                id: wallsListView

                anchors {
                    left: parent.left
                    right: parent.right
                }
                height: contentHeight + Theme.horizontalPageMargin

                spacing: Theme.horizontalPageMargin

                model: ListModel {
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

                header: Item {
                    height: Theme.horizontalPageMargin
                }

                delegate: BackgroundItem {
                    id: wallItem
                    width: parent.width
                    height: width + 222

                    Rectangle {
                        width: parent.width
                        height: parent.height
                        radius: 10
                        color: Theme.rgba(Theme.highlightColor, 0.2)

                        Image {
                            id: image
                            width: parent.width
                            height: parent.width
                            fillMode: Image.PreserveAspectCrop
                            source: model.thumbnail

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

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors {
                                top: image.bottom
                                left: parent.left
                                right: parent.right
                                margins: Theme.paddingMedium
                                topMargin: Theme.paddingSmall
                            }

                            RowLayout {
                                width: parent.width

                                Label {
                                    Layout.alignment: Qt.AlignLeft
                                    text: model.resX + "x" + model.resY
                                }

                                Label {
                                    font.pixelSize: Theme.fontSizeSmall
                                    Layout.alignment: Qt.AlignRight
                                    text: Qt.formatDateTime(new Date(model.createdAt), "dd MMM yyyy")
                                    color: Theme.secondaryHighlightColor
                                }
                            }

                            Label {
                                function checkResolution() {
                                    var deviceMax = Math.max(Screen.width, Screen.height)
                                    var pictureMin = Math.min(model.resX, model.resY);
                                    return pictureMin > deviceMax;
                                }

                                text: checkResolution() ? qsTr("Good for the device") : qsTr("Bad for the device")
                                color: Theme.highlightColor
                                font.pixelSize: Theme.fontSizeSmall
                            }

                            Label {
                                text: qsTr("Category") + ": " + model.category
                                color: Theme.secondaryColor
                                font.pixelSize: Theme.fontSizeSmall
                            }

                            Label {
                                text: qsTr("Views") + ": " + model.views
                                color: Theme.secondaryColor
                                font.pixelSize: Theme.fontSizeSmall
                            }

                            Label {
                                text: qsTr("Favorites") + ": " + model.favorites
                                color: Theme.secondaryColor
                                font.pixelSize: Theme.fontSizeSmall
                            }
                        }
                    }

                    ImageDownloader {
                        id: imgDownloader

                        onImageDownloaded: {
                            downloadIndicator.running = false;

                            if (filepath === "") {
                                notice.text = qsTr("Failed to download the image");
                            } else {
                                notice.text = qsTr("Image downloaded");
                            }

                            notice.show()
                        }
                    }

                    PopupMenu {
                        property bool isDownloaded

                        id: imagePopup

                        PopupMenuItem {
                            function getSize() {
                                return (Math.round(model.fileSize / 1024 / 1024 * 100) / 100) + " MB";
                            }

                            text: qsTr("Download") + ", " + getSize()
                            hint: imagePopup.isDownloaded ? qsTr("Image is already downloaded") : ""
                            icon.source: "image://theme/icon-m-download"
                            enabled: !imagePopup.isDownloaded;

                            onClicked: {
                                notice.text = qsTr("Downloading image");
                                notice.show()
                                downloadIndicator.running = true;
                                imgDownloader.downloadImage(model.fullImage)
                            }
                        }

                        PopupMenuItem {
                            text: qsTr("Remove")
                            hint: imagePopup.isDownloaded ? "" : qsTr("Image is not downloaded")
                            icon.source: "image://theme/icon-m-delete"
                            enabled: imagePopup.isDownloaded;

                            onClicked: {
                                imgDownloader.removeImage(model.fullImage)
                                notice.text = qsTr("Image removed");
                                notice.show()
                            }
                        }

                        PopupMenuItem {
                            text: qsTr("Share")
                            hint: imagePopup.isDownloaded ? "" : qsTr("Image is not downloaded")
                            icon.source: "image://theme/icon-m-share"
                            enabled: imagePopup.isDownloaded;

                            onClicked: {
                                var path = imgDownloader.getImagePath(model.fullImage)

                                shareAction.resources = [path];
                                shareAction.mimeType = "image/*";
                                shareAction.trigger();
                            }
                        }

                        PopupMenuItem {
                            text: qsTr("Create an ambience")
                            hint: imagePopup.isDownloaded ? "" : qsTr("Image is not downloaded")
                            icon.source: "image://theme/icon-m-ambience"
                            enabled: imagePopup.isDownloaded;

                            Dialog {
                                id: ambienceDialog

                                DialogHeader {
                                    id: header
                                    title: qsTr("Creating an ambience")
                                }

                                Text {
                                    anchors.top: header.bottom
                                    width: parent.width - Theme.horizontalPageMargin * 2
                                    x: Theme.horizontalPageMargin

                                    color: Theme.secondaryColor
                                    wrapMode: Text.WordWrap
                                    elide: Text.ElideRight

                                    text: qsTr("Currently Aurora OS forbids ambience creation by 3rd party applications.\nYou can create ambience via Gallery App, the image you downloaded will be there.\n\nBut you can enable this feature, to enable it please edit application desktop file manually:\n\nOpen file:\n /usr/share/applications/ru.erhoof.walls.desktop\n\nAdd 'Ambience' permission at the end of the list and reboot the device, like so:\n\n") + "[X-Application]\nPermissions=Internet;Pictures;Ambience"
                                }
                            }

                            onClicked: {
                                var path = imgDownloader.getImagePath(model.fullImage);

                                ambienceInterface.call("setAmbience", ["file://" + path],
                                    function(result) {
                                        console.log("Ambience set successfully: " + result);
                                        notice.text = qsTr("Ambience created");
                                        notice.show()
                                    },
                                    function(error) {
                                        console.log("Error setting ambience: " + error);
                                        pageStack.push(ambienceDialog)
                                    }
                                );
                            }
                        }
                    }

                    onClicked: {
                        imagePopup.isDownloaded = imgDownloader.isImageDownloaded(model.fullImage);
                        imagePopup.open()
                    }
                }

                PushUpMenu {
                    id: pushUpMenu
                    quickSelect: true

                    MenuItem {
                        text: qsTr("Load mode")
                        enabled: (page.currentPage !== page.lastPage)

                        onClicked: {
                            page.requestImages(page.searchQuery, page.currentPage + 1)
                        }
                    }

                    MenuLabel { text: page.currentPage + ' / ' + page.lastPage}
                }
            }
        }
    }
}
