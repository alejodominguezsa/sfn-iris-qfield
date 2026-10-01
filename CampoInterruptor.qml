import QtQuick

// Widget CheckBox de QGIS (booleano o par de estados custom) como switch SFN.
Item {
  id: campoInterruptor

  property var valor
  property var config: ({})
  property var campo
  property bool habilitado: false
  property var estilo
  property string tipoWidget: ""
  property bool validoHard: true
  property bool validoSoft: true

  signal cambioSolicitado(var valor, bool esNull)

  // QMetaType Bool = 1
  readonly property bool esBool: campo ? campo.type === 1 : false
  readonly property var estadoOn: config && config["CheckedState"] !== undefined && config["CheckedState"] !== ""
    ? config["CheckedState"] : (esBool ? true : 1)
  readonly property var estadoOff: config && config["UncheckedState"] !== undefined && config["UncheckedState"] !== ""
    ? config["UncheckedState"] : (esBool ? false : 0)

  readonly property bool prendido: {
    if (valor === undefined || valor === null)
      return false
    if (esBool) {
      // GPKG puede devolver 'true'/'false' como texto
      if (typeof valor === "string")
        return valor.toLowerCase() === "true"
      return valor === true || valor === 1
    }
    return String(valor) === String(estadoOn)
  }

  width: parent ? parent.width : 200
  height: 32

  Row {
    spacing: 12

    Rectangle {
      width: 52
      height: 30
      radius: 15
      anchors.verticalCenter: parent.verticalCenter
      color: campoInterruptor.prendido
        ? (campoInterruptor.estilo ? campoInterruptor.estilo.azul : "#1C45AB")
        : (campoInterruptor.estilo ? campoInterruptor.estilo.inputBorde : "#C2C9D6")
      opacity: campoInterruptor.habilitado ? 1 : 0.5

      Rectangle {
        width: 24
        height: 24
        radius: 12
        color: "#ffffff"
        anchors.verticalCenter: parent.verticalCenter
        x: campoInterruptor.prendido ? parent.width - width - 3 : 3

        Behavior on x {
          NumberAnimation {
            duration: 120
          }
        }
      }

      MouseArea {
        anchors.fill: parent
        enabled: campoInterruptor.habilitado
        onClicked: campoInterruptor.cambioSolicitado(
          campoInterruptor.prendido ? campoInterruptor.estadoOff : campoInterruptor.estadoOn, false)
      }
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: campoInterruptor.prendido ? qsTr("Si") : qsTr("No")
      font.pixelSize: 16
      font.weight: Font.DemiBold
      color: campoInterruptor.estilo ? campoInterruptor.estilo.textoOscuro : "#1A2332"
    }
  }
}
