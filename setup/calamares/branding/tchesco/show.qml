/* Slideshow do instalador Tchesco OS */
import QtQuick 2.0
import calamares.slideshow 1.0

Presentation {
    id: presentation

    function nextSlide() {
        if (!presentation.goToNextSlide()) {
            presentation.currentSlide = 0
        }
    }

    Timer {
        id: slideshowTimer
        interval: 5000
        repeat: true
        running: presentation.activatedInCalamares
        onTriggered: presentation.nextSlide()
    }

    Slide {
        anchors.fill: parent
        Image {
            id: background
            source: "welcome.png"
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
        }
        Text {
            anchors.centerIn: parent
            color: "#ffffff"
            font.pixelSize: 28
            font.bold: true
            text: "Bem-vindo ao Tchesco OS 1.0"
            style: Text.Outline
            styleColor: "#000000"
        }
    }

    Slide {
        anchors.fill: parent
        Image {
            source: "welcome.png"
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
        }
        Column {
            anchors.centerIn: parent
            spacing: 12
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                color: "#ffffff"
                font.pixelSize: 22
                font.bold: true
                text: "Visual macOS no Linux"
                style: Text.Outline
                styleColor: "#000000"
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                color: "#dddddd"
                font.pixelSize: 16
                text: "KDE Plasma 6 • Plank Dock • WhiteSur Theme"
                style: Text.Outline
                styleColor: "#000000"
            }
        }
    }

    Slide {
        anchors.fill: parent
        Image {
            source: "welcome.png"
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
        }
        Column {
            anchors.centerIn: parent
            spacing: 12
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                color: "#ffffff"
                font.pixelSize: 22
                font.bold: true
                text: "Pronto para Desenvolver"
                style: Text.Outline
                styleColor: "#000000"
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                color: "#dddddd"
                font.pixelSize: 16
                text: "VS Code • Docker • Node.js • Python • Rust • Go"
                style: Text.Outline
                styleColor: "#000000"
            }
        }
    }

    Slide {
        anchors.fill: parent
        Image {
            source: "welcome.png"
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
        }
        Column {
            anchors.centerIn: parent
            spacing: 12
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                color: "#ffffff"
                font.pixelSize: 22
                font.bold: true
                text: "Gaming Ready"
                style: Text.Outline
                styleColor: "#000000"
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                color: "#dddddd"
                font.pixelSize: 16
                text: "Steam • Lutris • Wine • GameMode • MangoHud"
                style: Text.Outline
                styleColor: "#000000"
            }
        }
    }
}
