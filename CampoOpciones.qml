import QtQuick
import QtQuick.Controls

// Widget ValueMap de QGIS (opciones fijas del proyecto) con estilo SFN.
// Es un dropdown como el nativo: input con caret que despliega un panel de
// opciones (con buscador si hay muchas). En lectura muestra la etiqueta
// humana del valor almacenado.
Item {
  id: campoOpciones

  property var valor
  property var config: ({})
  property var campo
  property bool habilitado: false
  property var estilo
  property string tipoWidget: ""
  property bool validoHard: true
  property bool validoSoft: true

  signal cambioSolicitado(var valor, bool esNull)

  property string filtro: ""

  // valor centinela que QGIS usa para la entrada NULL del mapa
  readonly property string centinelaNull: "{2839923C-8B7D-419E-B84B-CA2FE9B80EC7}"

  // config["map"]: lista de {etiqueta: valorAlmacenado} (QGIS 3) o mapa plano
  // (legacy). OJO: la lista llega de C++ como QVariantList y puede NO pasar
  // Array.isArray (leccion v0.3.2: caia a la rama legacy y mostraba 0,1,2...);
  // se detecta lista por .length numerico.
  readonly property var opciones: {
    var resultado = []
    if (!config || !config["map"])
      return resultado
    var mapa = config["map"]
    if (mapa && typeof mapa.length === "number") {
      for (var i = 0; i < mapa.length; i++) {
        var entrada = mapa[i]
        for (var etiqueta in entrada) {
          if (String(entrada[etiqueta]) !== centinelaNull)
            resultado.push({ "etiqueta": etiqueta, "valorMapa": entrada[etiqueta] })
        }
      }
    } else {
      for (var clave in mapa) {
        if (String(mapa[clave]) !== centinelaNull)
          resultado.push({ "etiqueta": clave, "valorMapa": mapa[clave] })
      }
    }
    return resultado
  }

  readonly property bool esNulo: valor === undefined || valor === null || valor === ""

  function etiquetaActual() {
    if (esNulo)
      return qsTr("Sin datos")
    for (var i = 0; i < opciones.length; i++) {
      if (String(opciones[i].valorMapa) === String(valor))
        return opciones[i].etiqueta
    }
    return "(" + String(valor) + ")"
  }

  width: parent ? parent.width : 200
  height: habilitado ? 48 : textoLectura.height

  // --- lectura: etiqueta resuelta ---
  Text {
    id: textoLectura
    visible: !campoOpciones.habilitado
    width: parent.width
    text: campoOpciones.etiquetaActual()
    font.pixelSize: 17
    font.weight: Font.DemiBold
    color: campoOpciones.esNulo
      ? (campoOpciones.estilo ? campoOpciones.estilo.textoDeshabilitado : "#8B94A6")
      : (campoOpciones.estilo ? campoOpciones.estilo.textoOscuro : "#1A2332")
    wrapMode: Text.WordWrap
  }

  // --- edicion: input desplegable ---
  Rectangle {
    visible: campoOpciones.habilitado
    width: parent.width
    height: 48
    radius: campoOpciones.estilo ? campoOpciones.estilo.radioInput : 12
    color: campoOpciones.estilo ? campoOpciones.estilo.inputFondo : "#ffffff"
    border.width: !campoOpciones.validoHard ? 2 : 1.5
    border.color: {
      if (!campoOpciones.estilo) return "#C2C9D6"
      if (!campoOpciones.validoHard) return campoOpciones.estilo.colorError
      if (!campoOpciones.validoSoft) return campoOpciones.estilo.colorWarning
      return campoOpciones.estilo.inputBorde
    }

    Text {
      anchors.left: parent.left
      anchors.leftMargin: 16
      anchors.right: caret.left
      anchors.rightMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      text: campoOpciones.etiquetaActual()
      font.pixelSize: 16
      font.weight: Font.DemiBold
      elide: Text.ElideRight
      color: campoOpciones.esNulo
        ? (campoOpciones.estilo ? campoOpciones.estilo.textoDeshabilitado : "#8B94A6")
        : (campoOpciones.estilo ? campoOpciones.estilo.textoOscuro : "#1A2332")
    }

    Canvas {
      id: caret
      width: 14
      height: 8
      anchors.right: parent.right
      anchors.rightMargin: 16
      anchors.verticalCenter: parent.verticalCenter
      onPaint: {
        var ctx = getContext("2d")
        ctx.reset()
        ctx.strokeStyle = campoOpciones.estilo ? String(campoOpciones.estilo.azul) : "#1C45AB"
        ctx.lineWidth = 2.5
        ctx.lineCap = "round"
        ctx.lineJoin = "round"
        ctx.beginPath()
        ctx.moveTo(1.5, 1.5)
        ctx.lineTo(width / 2, height - 1.5)
        ctx.lineTo(width - 1.5, 1.5)
        ctx.stroke()
      }
    }

    MouseArea {
      anchors.fill: parent
      onClicked: {
        campoOpciones.filtro = ""
        panelOpciones.open()
      }
    }
  }

  // --- panel desplegable de opciones ---
  Popup {
    id: panelOpciones
    parent: Overlay.overlay
    x: Math.round((parent.width - width) / 2)
    y: Math.round((parent.height - height) / 2)
    width: Math.min(parent ? parent.width - 40 : 360, 420)
    height: Math.min(contenidoPanel.implicitHeight + 32, parent ? parent.height * 0.7 : 500)
    modal: true
    padding: 16

    background: Rectangle {
      radius: 16
      color: campoOpciones.estilo ? campoOpciones.estilo.hojaFondo : "#ffffff"
      border.width: 1.5
      border.color: campoOpciones.estilo ? campoOpciones.estilo.cardBorde : "#E3E6EC"
    }

    contentItem: Column {
      id: contenidoPanel
      spacing: 10

      // buscador
      Rectangle {
        visible: campoOpciones.opciones.length > 8
        width: parent.width
        height: 44
        radius: campoOpciones.estilo ? campoOpciones.estilo.radioInput : 12
        color: campoOpciones.estilo ? campoOpciones.estilo.card : "#F7F8FA"
        border.width: 1.5
        border.color: campoOpciones.estilo ? campoOpciones.estilo.inputBorde : "#C2C9D6"

        Image {
          anchors.left: parent.left
          anchors.leftMargin: 12
          anchors.verticalCenter: parent.verticalCenter
          width: 18
          height: 18
          sourceSize.width: 54
          sourceSize.height: 54
          source: Qt.resolvedUrl("icono_buscar.svg")
        }

        TextInput {
          anchors.fill: parent
          anchors.leftMargin: 40
          anchors.rightMargin: 12
          verticalAlignment: TextInput.AlignVCenter
          font.pixelSize: 15
          color: campoOpciones.estilo ? campoOpciones.estilo.textoOscuro : "#1A2332"
          clip: true
          text: campoOpciones.filtro
          onTextChanged: campoOpciones.filtro = text

          Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: parent.text === ""
            text: qsTr("Buscar")
            font.pixelSize: 15
            color: campoOpciones.estilo ? campoOpciones.estilo.textoDeshabilitado : "#8B94A6"
          }
        }
      }

      Flickable {
        width: parent.width
        height: Math.min(columnaListado.height,
          (panelOpciones.parent ? panelOpciones.parent.height * 0.7 : 500) - 120)
        contentHeight: columnaListado.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
          id: columnaListado
          width: parent.width

          // opcion para limpiar el campo
          FilaOpcion {
            estilo: campoOpciones.estilo
            width: parent.width
            texto: qsTr("Sin dato")
            exclusiva: true
            habilitado: true
            marcada: campoOpciones.esNulo
            onAlternada: {
              campoOpciones.cambioSolicitado("", true)
              panelOpciones.close()
            }
          }

          Repeater {
            model: campoOpciones.opciones
            delegate: FilaOpcion {
              estilo: campoOpciones.estilo
              width: columnaListado.width
              texto: modelData.etiqueta
              exclusiva: true
              habilitado: true
              marcada: !campoOpciones.esNulo && String(modelData.valorMapa) === String(campoOpciones.valor)
              visible: campoOpciones.filtro === ""
                || String(modelData.etiqueta).toLowerCase().indexOf(campoOpciones.filtro.toLowerCase()) !== -1
              onAlternada: {
                campoOpciones.cambioSolicitado(modelData.valorMapa, false)
                panelOpciones.close()
              }
            }
          }
        }
      }
    }
  }
}
