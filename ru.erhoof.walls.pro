TARGET = ru.erhoof.walls

CONFIG += \
    auroraapp

PKGCONFIG += \

SOURCES += \
    src/imagedownloader.cpp \
    src/main.cpp \

HEADERS += \
    src/imagedownloader.h

DISTFILES += \
    rpm/ru.erhoof.walls.spec \

AURORAAPP_ICONS = 86x86 108x108 128x128 172x172

CONFIG += auroraapp_i18n

TRANSLATIONS += \
    translations/ru.erhoof.walls.ts \
    translations/ru.erhoof.walls-ru.ts \
