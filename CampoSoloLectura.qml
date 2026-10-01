import QtQuick
import org.qfield

// Presentacion de solo lectura de un valor de campo. Es el unico componente del
// modo lectura (para todos los tipos de widget) y el fallback universal en modo
// edicion para widgets todavia no implementados.
// Contrato comun de los Campo*: valor / config / campo / habilitado / estilo /
// tipoWidget, señal cambioSolicitado (aca nunca se emite).
Item {
  id: campoLectura

  property var valor
  property var config: ({})
  property var campo
  property bool habilitado: false
  property var estilo
  property string tipoWidget: ""
  property bool validoHard: true
  property bool validoSoft: true
  // si viene no vacio, el campo cayo al fallback en modo edicion: mostrar el
  // tipo de widget en pantalla (sirve de diagnostico en campo)
  property string tipoNoEditable: ""

  signal cambioSolicitado(var valor, bool esNull)

  readonly property bool esNulo: {
    if (valor === undefined || valor === null || valor === "")
      return true
    try {
      return FeatureUtils.attributeIsNull(valor)
    } catch (err) {
      return false
    }
  }

  function textoDisplay() {
    if (esNulo)
      return qsTr("Sin datos")

    // fechas: usar el formato de display del widget si existe
    if (campo && campo.isDateOrTime) {
      var formato = (config && config["display_format"]) ? config["display_format"] : "yyyy-MM-dd HH:mm:ss"
      var texto = Qt.formatDateTime(valor, formato)
      return texto !== "" ? texto : String(valor)
    }

    // booleano real (QMetaType Bool = 1)
    if (campo && campo.type === 1)
      return (valor === true || String(valor).toLowerCase() === "true") ? qsTr("Si") : qsTr("No")

    // CheckBox con estados custom
    if (tipoWidget === "CheckBox" && config && config["CheckedState"] !== undefined)
      return String(valor) === String(config["CheckedState"]) ? qsTr("Si") : qsTr("No")

    // numerico con sufijo del widget Range
    if (tipoWidget === "Range" && config && config["Suffix"])
      return String(valor) + " " + config["Suffix"]

    return String(valor)
  }

  width: parent ? parent.width : 200
  height: textoValor.height + (notaTipo.visible ? notaTipo.height + 4 : 0)

  Text {
    id: textoValor
    width: parent.width
    text: campoLectura.textoDisplay()
    font.pixelSize: 17
    font.weight: Font.DemiBold
    color: campoLectura.esNulo
      ? (campoLectura.estilo ? campoLectura.estilo.textoDeshabilitado : "#8B94A6")
      : (campoLectura.estilo ? campoLectura.estilo.textoOscuro : "#1A2332")
    wrapMode: Text.WordWrap
  }

  Text {
    id: notaTipo
    visible: campoLectura.tipoNoEditable !== ""
    anchors.top: textoValor.bottom
    anchors.topMargin: 4
    width: parent.width
    text: qsTr("(widget %1: sin editor todavia)").arg(campoLectura.tipoNoEditable)
    font.pixelSize: 11
    color: campoLectura.estilo ? campoLectura.estilo.textoDeshabilitado : "#8B94A6"
  }
}
