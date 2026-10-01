import QtQuick
import QtQuick.Controls
import org.qfield

// Widget ValueRelation de QGIS (opciones desde otra capa) con estilo SFN.
// Multi (la grilla de checkboxes del form nativo): casillas ordenadas con
// separadores y columnas segun config["NofColumns"], buscador en edicion.
// Single: dropdown como el nativo (input con caret que abre el panel).
// Reusa FeatureCheckListModel, el MISMO modelo C++ del widget nativo: resuelve
// opciones, checked y la serializacion del valor (array Postgres "{a,b}" en
// campos texto, lista nativa en campos JSON/lista) sin logica propia.
Item {
  id: campoRelacion

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
  // display del valor actual en modo single; lo capturan las filas del panel
  property string displayActual: ""

  readonly property bool esMulti: config && Number(config["AllowMulti"]) === 1
  readonly property bool esNulo: valor === undefined || valor === null || valor === ""
    || String(valor) === "{}" || String(valor) === "[]"

  onValorChanged: {
    if (esNulo)
      displayActual = ""
  }

  readonly property int columnas: {
    if (config && config["NofColumns"] !== undefined && Number(config["NofColumns"]) > 1)
      return Number(config["NofColumns"])
    return 1
  }

  // CONFIRMAR-EN-BUILD: resolucion de la capa de referencia desde el config.
  readonly property var capaReferencia: {
    if (!config)
      return null
    try {
      if (config["LayerName"]) {
        var porNombre = qgisProject.mapLayersByName(config["LayerName"])
        if (porNombre && porNombre.length > 0)
          return porNombre[0]
      }
    } catch (err) {}
    try {
      if (config["Layer"] && typeof qgisProject.mapLayer === "function") {
        var porId = qgisProject.mapLayer(config["Layer"])
        if (porId)
          return porId
      }
    } catch (err2) {}
    return null
  }

  readonly property bool disponible: capaReferencia !== null && capaReferencia !== undefined

  // attributeValue se asigna al final (mismo orden que el widget nativo)
  FeatureCheckListModel {
    id: listaOpciones
    allowMulti: campoRelacion.esMulti
    attributeField: campoRelacion.campo
    currentLayer: campoRelacion.capaReferencia
    keyField: campoRelacion.config && campoRelacion.config["Key"] ? campoRelacion.config["Key"] : ""
    displayValueField: campoRelacion.config && campoRelacion.config["Value"] ? campoRelacion.config["Value"] : ""
    filterExpression: campoRelacion.config && campoRelacion.config["FilterExpression"] ? campoRelacion.config["FilterExpression"] : ""
    attributeValue: campoRelacion.valor !== undefined && campoRelacion.valor !== null ? campoRelacion.valor : ""
  }

  // El modelo rearma attributeValue al togglear una opcion; el guard de
  // aplicarCambio (mismoValor) corta cualquier eco de vuelta.
  Connections {
    target: listaOpciones
    function onListUpdated() {
      if (!campoRelacion.habilitado)
        return
      var nuevo = listaOpciones.attributeValue
      var vacio = nuevo === undefined || nuevo === null || nuevo === "" || String(nuevo) === "{}"
      campoRelacion.cambioSolicitado(nuevo, vacio)
    }
  }

  width: parent ? parent.width : 200
  height: {
    if (!disponible)
      return textoNoDisponible.height
    if (esMulti)
      return columnaMulti.height
    return habilitado ? 48 : textoLecturaSingle.height
  }

  // fallback: capa de referencia no encontrada -> valor crudo + nota
  Text {
    id: textoNoDisponible
    visible: !campoRelacion.disponible
    width: parent.width
    text: {
      var base = campoRelacion.esNulo ? qsTr("Sin datos") : String(campoRelacion.valor)
      if (campoRelacion.habilitado)
        base += "\n" + qsTr("(no encontre la capa de opciones: %1)")
          .arg(campoRelacion.config && campoRelacion.config["LayerName"] ? campoRelacion.config["LayerName"] : "?")
      return base
    }
    font.pixelSize: 15
    font.weight: Font.DemiBold
    color: campoRelacion.esNulo
      ? (campoRelacion.estilo ? campoRelacion.estilo.textoDeshabilitado : "#8B94A6")
      : (campoRelacion.estilo ? campoRelacion.estilo.textoOscuro : "#1A2332")
    wrapMode: Text.WordWrap
  }

  // ================= SINGLE: lectura =================
  Text {
    id: textoLecturaSingle
    visible: campoRelacion.disponible && !campoRelacion.esMulti && !campoRelacion.habilitado
    width: parent.width
    text: campoRelacion.esNulo
      ? qsTr("Sin datos")
      : (campoRelacion.displayActual !== "" ? campoRelacion.displayActual : String(campoRelacion.valor))
    font.pixelSize: 17
    font.weight: Font.DemiBold
    color: campoRelacion.esNulo
      ? (campoRelacion.estilo ? campoRelacion.estilo.textoDeshabilitado : "#8B94A6")
      : (campoRelacion.estilo ? campoRelacion.estilo.textoOscuro : "#1A2332")
    wrapMode: Text.WordWrap
  }

  // ================= SINGLE: edicion (dropdown) =================
  Rectangle {
    visible: campoRelacion.disponible && !campoRelacion.esMulti && campoRelacion.habilitado
    width: parent.width
    height: 48
    radius: campoRelacion.estilo ? campoRelacion.estilo.radioInput : 12
    color: campoRelacion.estilo ? campoRelacion.estilo.inputFondo : "#ffffff"
    border.width: !campoRelacion.validoHard ? 2 : 1.5
    border.color: {
      if (!campoRelacion.estilo) return "#C2C9D6"
      if (!campoRelacion.validoHard) return campoRelacion.estilo.colorError
      if (!campoRelacion.validoSoft) return campoRelacion.estilo.colorWarning
      return campoRelacion.estilo.inputBorde
    }

    Text {
      anchors.left: parent.left
      anchors.leftMargin: 16
      anchors.right: caretRelacion.left
      anchors.rightMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      text: campoRelacion.esNulo
        ? qsTr("Sin datos")
        : (campoRelacion.displayActual !== "" ? campoRelacion.displayActual : String(campoRelacion.valor))
      font.pixelSize: 16
      font.weight: Font.DemiBold
      elide: Text.ElideRight
      color: campoRelacion.esNulo
        ? (campoRelacion.estilo ? campoRelacion.estilo.textoDeshabilitado : "#8B94A6")
        : (campoRelacion.estilo ? campoRelacion.estilo.textoOscuro : "#1A2332")
    }

    Canvas {
      id: caretRelacion
      width: 14
      height: 8
      anchors.right: parent.right
      anchors.rightMargin: 16
      anchors.verticalCenter: parent.verticalCenter
      onPaint: {
        var ctx = getContext("2d")
        ctx.reset()
        ctx.strokeStyle = campoRelacion.estilo ? String(campoRelacion.estilo.azul) : "#1C45AB"
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
        campoRelacion.filtro = ""
        panelRelacion.open()
      }
    }
  }

  Popup {
    id: panelRelacion
    parent: Overlay.overlay
    x: Math.round((parent.width - width) / 2)
    y: Math.round((parent.height - height) / 2)
    width: Math.min(parent ? parent.width - 40 : 360, 420)
    height: Math.min(contenidoRelacion.implicitHeight + 32, parent ? parent.height * 0.7 : 500)
    modal: true
    padding: 16

    background: Rectangle {
      radius: 16
      color: campoRelacion.estilo ? campoRelacion.estilo.hojaFondo : "#ffffff"
      border.width: 1.5
      border.color: campoRelacion.estilo ? campoRelacion.estilo.cardBorde : "#E3E6EC"
    }

    contentItem: Column {
      id: contenidoRelacion
      spacing: 10

      Rectangle {
        width: parent.width
        height: 44
        radius: campoRelacion.estilo ? campoRelacion.estilo.radioInput : 12
        color: campoRelacion.estilo ? campoRelacion.estilo.card : "#F7F8FA"
        border.width: 1.5
        border.color: campoRelacion.estilo ? campoRelacion.estilo.inputBorde : "#C2C9D6"

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
          color: campoRelacion.estilo ? campoRelacion.estilo.textoOscuro : "#1A2332"
          clip: true
          text: campoRelacion.filtro
          onTextChanged: campoRelacion.filtro = text

          Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: parent.text === ""
            text: qsTr("Buscar")
            font.pixelSize: 15
            color: campoRelacion.estilo ? campoRelacion.estilo.textoDeshabilitado : "#8B94A6"
          }
        }
      }

      Flickable {
        width: parent.width
        height: Math.min(columnaListadoRelacion.height,
          (panelRelacion.parent ? panelRelacion.parent.height * 0.7 : 500) - 120)
        contentHeight: columnaListadoRelacion.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
          id: columnaListadoRelacion
          width: parent.width

          FilaOpcion {
            estilo: campoRelacion.estilo
            width: parent.width
            texto: qsTr("Sin dato")
            exclusiva: true
            habilitado: true
            marcada: campoRelacion.esNulo
            onAlternada: {
              campoRelacion.cambioSolicitado("", true)
              panelRelacion.close()
            }
          }

          Repeater {
            model: listaOpciones
            delegate: FilaOpcion {
              estilo: campoRelacion.estilo
              width: columnaListadoRelacion.width
              texto: model.displayString !== undefined ? String(model.displayString) : ""
              exclusiva: true
              habilitado: true
              marcada: model.checked === true
              visible: campoRelacion.filtro === ""
                || String(model.displayString).toLowerCase().indexOf(campoRelacion.filtro.toLowerCase()) !== -1
              // captura el display del valor actual (para el input y la lectura)
              Component.onCompleted: {
                if (marcada)
                  campoRelacion.displayActual = texto
              }
              onMarcadaChanged: {
                if (marcada)
                  campoRelacion.displayActual = texto
              }
              onAlternada: {
                model.checked = true
                panelRelacion.close()
              }
            }
          }
        }
      }
    }
  }

  // ================= MULTI: grilla estilo QField =================
  Column {
    id: columnaMulti
    visible: campoRelacion.disponible && campoRelacion.esMulti
    width: parent.width
    spacing: 10

    // buscador (solo en edicion, como el widget nativo)
    Rectangle {
      visible: campoRelacion.habilitado
      width: parent.width
      height: 44
      radius: campoRelacion.estilo ? campoRelacion.estilo.radioInput : 12
      color: campoRelacion.estilo ? campoRelacion.estilo.inputFondo : "#ffffff"
      border.width: 1.5
      border.color: campoRelacion.estilo ? campoRelacion.estilo.inputBorde : "#C2C9D6"

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
        color: campoRelacion.estilo ? campoRelacion.estilo.textoOscuro : "#1A2332"
        clip: true
        onTextChanged: campoRelacion.filtro = text

        Text {
          anchors.verticalCenter: parent.verticalCenter
          visible: parent.text === ""
          text: qsTr("Buscar")
          font.pixelSize: 15
          color: campoRelacion.estilo ? campoRelacion.estilo.textoDeshabilitado : "#8B94A6"
        }
      }
    }

    Rectangle {
      width: parent.width
      height: grillaRelacion.height + 12
      radius: campoRelacion.estilo ? campoRelacion.estilo.radioInput : 12
      color: campoRelacion.habilitado
        ? (campoRelacion.estilo ? campoRelacion.estilo.inputFondo : "#ffffff")
        : "transparent"
      border.width: campoRelacion.habilitado ? 1.5 : 0
      border.color: campoRelacion.estilo ? campoRelacion.estilo.inputBorde : "#C2C9D6"

      Grid {
        id: grillaRelacion
        x: 10
        y: 6
        width: parent.width - 20
        columns: campoRelacion.columnas
        columnSpacing: 16

        Repeater {
          model: campoRelacion.esMulti ? listaOpciones : null
          delegate: FilaOpcion {
            estilo: campoRelacion.estilo
            width: (grillaRelacion.width - (campoRelacion.columnas - 1) * grillaRelacion.columnSpacing) / campoRelacion.columnas
            texto: model.displayString !== undefined ? String(model.displayString) : ""
            exclusiva: false
            habilitado: campoRelacion.habilitado
            marcada: model.checked === true
            visible: campoRelacion.filtro === ""
              || String(model.displayString).toLowerCase().indexOf(campoRelacion.filtro.toLowerCase()) !== -1
            onAlternada: model.checked = !(model.checked === true)
          }
        }
      }
    }
  }
}
