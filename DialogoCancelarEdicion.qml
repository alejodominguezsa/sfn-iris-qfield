import QtQuick

// Dialogo binario al salir del modo edicion con cambios sin guardar. Replica
// la logica del dialogo nativo de QField ("se perderan todos los cambios")
// con la paleta SFN. Overlay propio para no depender de estilos del Theme.
Rectangle {
  id: dialogo

  property var estilo

  signal seguirEditando()
  signal descartar()

  visible: false
  color: "#99000000"

  function abrir() {
    visible = true
  }

  // bloquear los taps al contenido de abajo
  MouseArea {
    anchors.fill: parent
    onClicked: {}
  }

  Rectangle {
    anchors.centerIn: parent
    width: Math.min(parent.width - 48, 380)
    height: contenidoDialogo.height + 48
    radius: 16
    color: dialogo.estilo ? dialogo.estilo.hojaFondo : "#ffffff"

    Column {
      id: contenidoDialogo
      anchors.centerIn: parent
      width: parent.width - 48
      spacing: 14

      Text {
        width: parent.width
        text: qsTr("Cancelar edicion")
        font.pixelSize: 19
        font.bold: true
        color: dialogo.estilo ? dialogo.estilo.textoOscuro : "#1A2332"
      }

      Text {
        width: parent.width
        text: qsTr("Estas por salir de la edicion: se van a perder los cambios sin guardar. ¿Continuar?")
        font.pixelSize: 15
        color: dialogo.estilo ? dialogo.estilo.texto : "#373F52"
        wrapMode: Text.WordWrap
      }

      Row {
        anchors.right: parent.right
        spacing: 10

        Rectangle {
          width: textoSeguir.width + 36
          height: 42
          radius: 21
          color: dialogo.estilo ? dialogo.estilo.azulBoton : "#E3E9F8"

          Text {
            id: textoSeguir
            anchors.centerIn: parent
            text: qsTr("Seguir editando")
            font.pixelSize: 14
            font.bold: true
            color: dialogo.estilo ? dialogo.estilo.azul : "#1C45AB"
          }
          MouseArea {
            anchors.fill: parent
            onClicked: {
              dialogo.visible = false
              dialogo.seguirEditando()
            }
          }
        }

        Rectangle {
          width: textoDescartar.width + 36
          height: 42
          radius: 21
          color: dialogo.estilo ? dialogo.estilo.colorError : "#EF4444"

          Text {
            id: textoDescartar
            anchors.centerIn: parent
            text: qsTr("Descartar")
            font.pixelSize: 14
            font.bold: true
            color: "#ffffff"
          }
          MouseArea {
            anchors.fill: parent
            onClicked: {
              dialogo.visible = false
              dialogo.descartar()
            }
          }
        }
      }
    }
  }
}
