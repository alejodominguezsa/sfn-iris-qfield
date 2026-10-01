import QtQuick
import QtQuick.Controls

// Editor SFN para el widget Range de QGIS: steppers - / valor / + como el
// mockup. Config: Min/Max/Step/Precision/Suffix (el estilo Slider cae a esta
// misma variante en esta version).
Item {
  id: campoRango

  property var valor
  property var config: ({})
  property var campo
  property bool habilitado: true
  property var estilo
  property string tipoWidget: ""
  property bool validoHard: true
  property bool validoSoft: true

  signal cambioSolicitado(var valor, bool esNull)

  readonly property bool esDoble: campo ? (campo.type === 6 || campo.type === 38) : false
  readonly property real minimo: config && config["Min"] !== undefined ? Number(config["Min"]) : -Infinity
  readonly property real maximo: config && config["Max"] !== undefined ? Number(config["Max"]) : Infinity
  readonly property real paso: config && config["Step"] !== undefined ? Number(config["Step"]) : 1
  readonly property int precision: config && config["Precision"] !== undefined ? Number(config["Precision"]) : (esDoble ? 2 : 0)
  readonly property string sufijo: config && config["Suffix"] ? String(config["Suffix"]) : ""

  function redondear(n) {
    var factor = Math.pow(10, precision)
    return Math.round(n * factor) / factor
  }

  function acotar(n) {
    return Math.min(maximo, Math.max(minimo, n))
  }

  function numeroActual() {
    var n = parseFloat(valor)
    return (!isNaN(n) && isFinite(n)) ? n : 0
  }

  function aplicarPaso(direccion) {
    var nuevo = redondear(acotar(numeroActual() + direccion * paso))
    cambioSolicitado(nuevo, false)
    // refrescar el display aunque el input tenga foco (onValorChanged lo
    // saltea con foco para no pisar el tipeo, pero el stepper no es tipeo)
    entradaNumero.text = String(nuevo)
  }

  function emitirTexto(texto) {
    if (texto === "") {
      cambioSolicitado("", true)
      return
    }
    // "-" solo es tipeo incompleto de un negativo: no emitir nada
    if (texto === "-" || texto === "+")
      return
    // coma decimal del teclado es_AR + rechazo de texto no numerico
    var limpio = texto.replace(",", ".")
    if (!/^[-+]?\d*\.?\d+$/.test(limpio))
      return
    var n = parseFloat(limpio)
    if (!isNaN(n) && isFinite(n))
      cambioSolicitado(redondear(acotar(n)), false)
  }

  onValorChanged: {
    if (!entradaNumero.activeFocus)
      entradaNumero.text = (valor === undefined || valor === null) ? "" : String(valor)
  }

  width: parent ? parent.width : 200
  height: 48

  Row {
    width: parent.width
    spacing: 8

    Rectangle {
      width: 48
      height: 48
      radius: campoRango.estilo ? campoRango.estilo.radioInput : 12
      color: campoRango.estilo ? campoRango.estilo.azulBoton : "#E3E9F8"
      opacity: campoRango.habilitado ? 1 : 0.4

      Image {
        anchors.centerIn: parent
        width: 20
        height: 20
        sourceSize.width: 60
        sourceSize.height: 60
        source: Qt.resolvedUrl("icono_menos.svg")
      }
      MouseArea {
        anchors.fill: parent
        enabled: campoRango.habilitado
        onClicked: campoRango.aplicarPaso(-1)
      }
    }

    Rectangle {
      width: parent.width - 2 * 48 - 2 * 8
      height: 48
      radius: campoRango.estilo ? campoRango.estilo.radioInput : 12
      color: campoRango.habilitado
        ? (campoRango.estilo ? campoRango.estilo.inputFondo : "#ffffff")
        : (campoRango.estilo ? campoRango.estilo.cardGris : "#EDEFF3")
      border.width: entradaNumero.activeFocus || !campoRango.validoHard ? 2 : 1.5
      border.color: {
        if (!campoRango.estilo) return "#C2C9D6"
        if (!campoRango.validoHard) return campoRango.estilo.colorError
        if (!campoRango.validoSoft) return campoRango.estilo.colorWarning
        return entradaNumero.activeFocus ? campoRango.estilo.inputBordeActivo : campoRango.estilo.inputBorde
      }

      TextInput {
        id: entradaNumero
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: sufijoTexto.visible ? sufijoTexto.width + 18 : 12
        verticalAlignment: TextInput.AlignVCenter
        horizontalAlignment: TextInput.AlignHCenter
        font.pixelSize: 17
        font.weight: Font.DemiBold
        color: campoRango.estilo ? campoRango.estilo.textoOscuro : "#1A2332"
        enabled: campoRango.habilitado
        clip: true
        inputMethodHints: Qt.ImhFormattedNumbersOnly
        text: (campoRango.valor === undefined || campoRango.valor === null) ? "" : String(campoRango.valor)
        onTextEdited: campoRango.emitirTexto(text)
      }

      Text {
        id: sufijoTexto
        visible: campoRango.sufijo !== ""
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        text: campoRango.sufijo
        font.pixelSize: 14
        color: campoRango.estilo ? campoRango.estilo.textoSecundario : "#6D717F"
      }
    }

    Rectangle {
      width: 48
      height: 48
      radius: campoRango.estilo ? campoRango.estilo.radioInput : 12
      color: campoRango.estilo ? campoRango.estilo.azulBoton : "#E3E9F8"
      opacity: campoRango.habilitado ? 1 : 0.4

      Image {
        anchors.centerIn: parent
        width: 20
        height: 20
        sourceSize.width: 60
        sourceSize.height: 60
        source: Qt.resolvedUrl("icono_mas.svg")
      }
      MouseArea {
        anchors.fill: parent
        enabled: campoRango.habilitado
        onClicked: campoRango.aplicarPaso(1)
      }
    }
  }
}
