import QtQuick
import Theme

// Widget DateTime de QGIS: input con icono de calendario que abre el
// QfCalendarPanel del propio QField (ya pintado de azul por nuestro Theme).
// Trade-off documentado: el calendario es del Theme nativo, no SFN puro.
Item {
  id: campoFecha

  property var valor
  property var config: ({})
  property var campo
  property bool habilitado: false
  property var estilo
  property string tipoWidget: ""
  property bool validoHard: true
  property bool validoSoft: true

  signal cambioSolicitado(var valor, bool esNull)

  readonly property string formatoDisplay: config && config["display_format"]
    ? config["display_format"] : "yyyy-MM-dd HH:mm:ss"
  readonly property string formatoCampo: config && config["field_format"]
    ? config["field_format"] : "yyyy-MM-dd HH:mm:ss"
  // QMetaType: QString=10, QDate=14, QTime=15
  readonly property bool campoEsString: campo ? campo.type === 10 : false
  readonly property bool esNulo: valor === undefined || valor === null || valor === ""

  function valorComoDate() {
    if (esNulo)
      return new Date()
    if (campoEsString) {
      var d = Date.fromLocaleString(Qt.locale(), String(valor), formatoCampo)
      return (d && !isNaN(d.getTime())) ? d : new Date()
    }
    return valor
  }

  function textoDisplay() {
    if (esNulo)
      return qsTr("Sin fecha")
    var texto = Qt.formatDateTime(campoEsString ? valorComoDate() : valor, formatoDisplay)
    return texto !== "" ? texto : String(valor)
  }

  width: parent ? parent.width : 200
  height: 48

  Rectangle {
    width: parent.width
    height: 48
    radius: campoFecha.estilo ? campoFecha.estilo.radioInput : 12
    color: campoFecha.habilitado
      ? (campoFecha.estilo ? campoFecha.estilo.inputFondo : "#ffffff")
      : "transparent"
    border.width: campoFecha.habilitado ? 1.5 : 0
    border.color: {
      if (!campoFecha.estilo) return "#C2C9D6"
      if (!campoFecha.validoHard) return campoFecha.estilo.colorError
      if (!campoFecha.validoSoft) return campoFecha.estilo.colorWarning
      return campoFecha.estilo.inputBorde
    }

    Text {
      anchors.left: parent.left
      anchors.leftMargin: campoFecha.habilitado ? 16 : 0
      anchors.right: iconoCal.left
      anchors.rightMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      text: campoFecha.textoDisplay()
      font.pixelSize: 17
      font.weight: Font.DemiBold
      elide: Text.ElideRight
      color: campoFecha.esNulo
        ? (campoFecha.estilo ? campoFecha.estilo.textoDeshabilitado : "#8B94A6")
        : (campoFecha.estilo ? campoFecha.estilo.textoOscuro : "#1A2332")
    }

    Image {
      id: iconoCal
      visible: campoFecha.habilitado
      anchors.right: parent.right
      anchors.rightMargin: 14
      anchors.verticalCenter: parent.verticalCenter
      width: 20
      height: 20
      sourceSize.width: 60
      sourceSize.height: 60
      source: Qt.resolvedUrl("icono_calendario.svg")
    }

    MouseArea {
      anchors.fill: parent
      enabled: campoFecha.habilitado
      onClicked: {
        panelCalendario.selectedDate = campoFecha.valorComoDate()
        panelCalendario.open()
      }
    }
  }

  // CONFIRMAR-EN-BUILD: QfCalendarPanel abrible desde un plugin
  QfCalendarPanel {
    id: panelCalendario
    // QDate (14) sin hora; QTime (15) sin fecha; para campos string decide el formato
    showDatePicker: campoFecha.campo && campoFecha.campo.type === 15
      ? false
      : (campoFecha.campoEsString ? /(yyyy|MM|dd)/.test(campoFecha.formatoCampo) : true)
    showTimePicker: campoFecha.campo && campoFecha.campo.type === 14
      ? false
      : (campoFecha.campoEsString ? /(HH|hh|mm|ss)/.test(campoFecha.formatoCampo) : true)
    onDateTimePicked: function (fecha) {
      if (fecha === undefined || fecha === null) {
        campoFecha.cambioSolicitado("", true)
        return
      }
      if (campoFecha.campoEsString)
        campoFecha.cambioSolicitado(Qt.formatDateTime(fecha, campoFecha.formatoCampo), false)
      else
        campoFecha.cambioSolicitado(fecha, false)
    }
  }
}
