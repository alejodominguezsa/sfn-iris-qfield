import QtQuick

// Una fila de opcion estilo QField (casilla + etiqueta + separador inferior)
// con paleta SFN. La usan CampoOpciones y CampoRelacion en sus grillas.
// exclusiva=true dibuja la casilla redonda (seleccion unica).
Item {
  id: filaOpcion

  property var estilo
  property string texto: ""
  property bool marcada: false
  property bool habilitado: false
  property bool exclusiva: false

  signal alternada()

  height: Math.max(44, textoOpcion.height + 16)

  Rectangle {
    anchors.bottom: parent.bottom
    width: parent.width
    height: 1
    color: filaOpcion.estilo ? filaOpcion.estilo.cardBorde : "#E3E6EC"
  }

  Rectangle {
    id: casilla
    width: 22
    height: 22
    radius: filaOpcion.exclusiva ? 11 : 5
    anchors.left: parent.left
    anchors.leftMargin: 4
    anchors.verticalCenter: parent.verticalCenter
    color: filaOpcion.marcada
      ? (filaOpcion.estilo ? filaOpcion.estilo.azul : "#1C45AB")
      : "transparent"
    border.width: filaOpcion.marcada ? 0 : 2
    border.color: filaOpcion.estilo ? filaOpcion.estilo.inputBorde : "#C2C9D6"
    opacity: filaOpcion.habilitado ? 1 : 0.55

    Image {
      visible: filaOpcion.marcada && !filaOpcion.exclusiva
      anchors.centerIn: parent
      width: 13
      height: 13
      sourceSize.width: 39
      sourceSize.height: 39
      source: Qt.resolvedUrl("icono_check_guardar.svg")
    }

    Rectangle {
      visible: filaOpcion.marcada && filaOpcion.exclusiva
      anchors.centerIn: parent
      width: 8
      height: 8
      radius: 4
      color: "#ffffff"
    }
  }

  Text {
    id: textoOpcion
    anchors.left: casilla.right
    anchors.leftMargin: 12
    anchors.right: parent.right
    anchors.rightMargin: 6
    anchors.verticalCenter: parent.verticalCenter
    text: filaOpcion.texto
    font.pixelSize: 15
    font.weight: filaOpcion.marcada ? Font.DemiBold : Font.Normal
    color: filaOpcion.estilo ? filaOpcion.estilo.textoOscuro : "#1A2332"
    wrapMode: Text.WordWrap
    opacity: filaOpcion.habilitado || filaOpcion.marcada ? 1 : 0.7
  }

  MouseArea {
    anchors.fill: parent
    enabled: filaOpcion.habilitado
    onClicked: filaOpcion.alternada()
  }
}
