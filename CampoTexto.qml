import QtQuick
import QtQuick.Controls

// Editor SFN para el widget TextEdit de QGIS. Emite cambioSolicitado en cada
// edicion del usuario (asi los constraints y defaults dependientes reaccionan
// en vivo, igual que el widget nativo). Texto vacio = NULL (convencion nativa).
Item {
  id: campoTexto

  property var valor
  property var config: ({})
  property var campo
  property bool habilitado: true
  property var estilo
  property string tipoWidget: ""
  property bool validoHard: true
  property bool validoSoft: true

  signal cambioSolicitado(var valor, bool esNull)

  readonly property bool multilinea: !!(config && config["IsMultiline"])
  readonly property bool numerico: campo ? campo.isNumeric === true : false

  function textoDesdeValor() {
    return (valor === undefined || valor === null) ? "" : String(valor)
  }

  function colorBorde(conFoco) {
    if (!estilo) return "#C2C9D6"
    if (!validoHard) return estilo.colorError
    if (!validoSoft) return estilo.colorWarning
    return conFoco ? estilo.inputBordeActivo : estilo.inputBorde
  }

  function emitir(texto) {
    if (texto === "") {
      cambioSolicitado("", true)
      return
    }
    if (numerico) {
      // aceptar coma decimal (teclado es_AR) y rechazar texto con basura:
      // parseFloat("12abc") devolveria 12 y guardaria distinto de lo que se ve
      var limpio = texto.replace(",", ".")
      if (!/^[-+]?\d*\.?\d+$/.test(limpio))
        return
      var num = parseFloat(limpio)
      if (!isNaN(num) && isFinite(num))
        cambioSolicitado(num, false)
      return
    }
    cambioSolicitado(texto, false)
  }

  // Al cambiar el valor desde afuera (navegacion, defaults en cascada), refrescar
  // el texto solo si el usuario no esta escribiendo (el binding de text se rompe
  // con el primer input, este es el patron estandar).
  onValorChanged: {
    if (multilinea) {
      if (!areaTexto.activeFocus)
        areaTexto.text = textoDesdeValor()
    } else if (!lineaTexto.activeFocus) {
      lineaTexto.text = textoDesdeValor()
    }
  }

  width: parent ? parent.width : 200
  height: multilinea ? cajaMulti.height : 48

  // --- una linea ---
  Rectangle {
    visible: !campoTexto.multilinea
    width: parent.width
    height: 48
    radius: campoTexto.estilo ? campoTexto.estilo.radioInput : 12
    color: campoTexto.habilitado
      ? (campoTexto.estilo ? campoTexto.estilo.inputFondo : "#ffffff")
      : (campoTexto.estilo ? campoTexto.estilo.cardGris : "#EDEFF3")
    border.width: lineaTexto.activeFocus || !campoTexto.validoHard ? 2 : 1.5
    border.color: campoTexto.colorBorde(lineaTexto.activeFocus)

    TextInput {
      id: lineaTexto
      anchors.fill: parent
      anchors.leftMargin: 16
      anchors.rightMargin: 16
      verticalAlignment: TextInput.AlignVCenter
      font.pixelSize: 16
      color: campoTexto.estilo ? campoTexto.estilo.textoOscuro : "#1A2332"
      enabled: campoTexto.habilitado
      clip: true
      inputMethodHints: campoTexto.numerico ? Qt.ImhFormattedNumbersOnly : Qt.ImhNone
      maximumLength: campoTexto.campo && campoTexto.campo.length > 0 ? campoTexto.campo.length : 32767
      text: campoTexto.textoDesdeValor()
      onTextEdited: campoTexto.emitir(text)
    }
  }

  // --- multilinea ---
  Rectangle {
    id: cajaMulti
    visible: campoTexto.multilinea
    width: parent.width
    height: Math.max(96, areaTexto.contentHeight + 28)
    radius: campoTexto.estilo ? campoTexto.estilo.radioInput : 12
    color: campoTexto.habilitado
      ? (campoTexto.estilo ? campoTexto.estilo.inputFondo : "#ffffff")
      : (campoTexto.estilo ? campoTexto.estilo.cardGris : "#EDEFF3")
    border.width: areaTexto.activeFocus || !campoTexto.validoHard ? 2 : 1.5
    border.color: campoTexto.colorBorde(areaTexto.activeFocus)

    TextEdit {
      id: areaTexto
      anchors.fill: parent
      anchors.margins: 14
      font.pixelSize: 16
      color: campoTexto.estilo ? campoTexto.estilo.textoOscuro : "#1A2332"
      enabled: campoTexto.habilitado
      wrapMode: TextEdit.Wrap
      clip: true
      text: campoTexto.textoDesdeValor()
      onTextChanged: {
        if (activeFocus)
          campoTexto.emitir(text)
      }
    }
  }
}
