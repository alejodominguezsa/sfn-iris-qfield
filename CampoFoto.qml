import QtQuick
import org.qfield

// Widget ExternalResource de QGIS (adjunto/foto). En lectura muestra la
// miniatura; tocarla abre la foto en el visor del sistema. En edicion suma
// los botones de camara y quitar. La foto capturada entra al buffer del
// AttributeFormModel como cualquier otro cambio: se guarda con el check y se
// descarta con la ✕.
//
// Replica el widget nativo de QField (QfEditorWidgetExternalResource.qml en
// 4.x, ExternalResource.qml en 3.x): mismo prefijo de ruta, misma expresion de
// nombre de QFieldSync y misma llamada a la camara nativa. Limitacion: siempre
// usa la camara nativa del celular, no la camara interna de QField (no es
// importable desde un plugin en 3.x).
Item {
  id: campoFoto

  property var valor
  property var config: ({})
  property var campo
  property bool habilitado: false
  property var estilo
  property string tipoWidget: ""
  property bool validoHard: true
  property bool validoSoft: true
  // capa y feature actuales, para evaluar la expresion de nombre de archivo
  // (null y no undefined: FilaCampo detecta las props con `!== undefined`)
  property var capa: null
  property var feature: null

  signal cambioSolicitado(var valor, bool esNull)

  // ResourceSource devuelto por getCameraPicture (emite resourceReceived)
  property var fuente: null

  readonly property bool esNulo: valor === undefined || valor === null || String(valor) === ""
  readonly property string textoValor: esNulo ? "" : String(valor)
  readonly property bool esUrl: /^https?:\/\//i.test(textoValor)

  // QField trata "sin tipo de visor" como imagen (DocumentViewer 1 = imagen)
  readonly property bool visorImagen: !config || config["DocumentViewer"] === undefined
    || config["DocumentViewer"] === null || Number(config["DocumentViewer"]) === 1
  readonly property bool pareceImagen: /\.(jpe?g|png|webp|gif|bmp|heic|heif|tiff?)$/i.test(textoValor)
  readonly property bool mostrarMiniatura: !esNulo && !esUrl && (pareceImagen || visorImagen)
  readonly property bool miniaturaOk: mostrarMiniatura && miniatura.status !== Image.Error

  // Prefijo de ruta igual al prefixToRelativePath nativo
  readonly property string prefijo: {
    var ruta = ""
    if (config && Number(config["RelativeStorage"]) === 2 && config["DefaultRoot"])
      ruta = String(config["DefaultRoot"])
    else if (typeof qgisProject !== "undefined" && qgisProject)
      ruta = String(qgisProject.homePath)
    if (ruta !== "" && !ruta.endsWith("/"))
      ruta += "/"
    return ruta
  }

  // rutas ya absolutas (RelativeStorage 0) no llevan prefijo
  readonly property bool esAbsoluta: /^(\/|[A-Za-z]:[\\\/])/.test(textoValor)
  readonly property string rutaCompleta: esNulo ? ""
    : (esUrl || esAbsoluta ? textoValor : prefijo + textoValor)

  function nombreArchivo(ruta) {
    var partes = String(ruta).replace(/\\/g, "/").split("/")
    return partes[partes.length - 1]
  }

  // Expresion de nombre configurada en QFieldSync para este campo (o "")
  function expresionNombre() {
    if (!capa || !campo || campo.name === undefined)
      return ""
    try {
      var claves = ["QFieldSync/attachment_naming", "QFieldSync/photo_naming"]
      for (var i = 0; i < claves.length; i++) {
        var crudo = capa.customProperty(claves[i])
        if (crudo !== undefined && crudo !== null && String(crudo) !== "") {
          var valorExpr = JSON.parse(crudo)[campo.name]
          return valorExpr !== undefined ? String(valorExpr) : ""
        }
      }
    } catch (err) {}
    return ""
  }

  // CONFIRMAR-EN-BUILD: ExpressionEvaluator se llama asi en org.qfield (3.x) y
  // QfExpressionEvaluator en org.qfield.core (4.x). Se crea dinamico para que
  // un nombre ausente no rompa la carga del componente.
  function evaluarExpresion(texto) {
    var variantes = [
      "import org.qfield.core; QfExpressionEvaluator {}",
      "import org.qfield; ExpressionEvaluator {}"
    ]
    for (var i = 0; i < variantes.length; i++) {
      var evaluador = null
      try {
        evaluador = Qt.createQmlObject(variantes[i], campoFoto)
        evaluador.project = qgisProject
        evaluador.layer = capa
        evaluador.feature = feature
        evaluador.expressionText = texto
        var resultado = evaluador.evaluate()
        evaluador.destroy()
        return resultado !== undefined && resultado !== null ? String(resultado) : ""
      } catch (err) {
        if (evaluador)
          evaluador.destroy()
      }
    }
    return ""
  }

  // Ruta relativa del archivo nuevo (misma regla que getAttachmentFilePath)
  function rutaNueva() {
    var ruta = ""
    var expr = expresionNombre()
    if (expr !== "")
      ruta = evaluarExpresion(expr).replace(/\\/g, "/")
    var tieneSufijo = /\.[A-Za-z0-9{}]+$/.test(nombreArchivo(ruta))
    if (ruta === "" || !tieneSufijo) {
      var ahora = (new Date()).toISOString().replace(/[^0-9]/g, "")
      ruta = "DCIM/JPEG_" + ahora + ".{extension}"
    }
    // las fotos de camara siempre son JPG
    return ruta.replace("{extension}", "JPG")
  }

  function capturar() {
    Qt.inputMethod.hide()
    if (typeof platformUtilities === "undefined" || !qgisProject) {
      iface.mainWindow().displayToast(qsTr("La camara no esta disponible"))
      return
    }
    var ruta = rutaNueva()
    var sufijo = ruta.substring(ruta.lastIndexOf(".") + 1)
    try {
      // CONFIRMAR-EN-BUILD: firma igual en QField 3.7, 4.0 y 4.3
      fuente = platformUtilities.getCameraPicture(qgisProject.homePath + "/", ruta, sufijo, campoFoto)
    } catch (err) {
      fuente = null
    }
    if (!fuente)
      iface.mainWindow().displayToast(qsTr("Este dispositivo no tiene camara nativa disponible"))
  }

  function abrir() {
    if (esNulo)
      return
    if (esUrl) {
      Qt.openUrlExternally(textoValor)
      return
    }
    try {
      platformUtilities.requestStoragePermission()
    } catch (err) {}
    try {
      platformUtilities.open(rutaCompleta, false, campoFoto)
    } catch (err) {
      iface.mainWindow().displayToast(qsTr("No se pudo abrir el archivo"))
    }
  }

  Connections {
    target: campoFoto.fuente
    ignoreUnknownSignals: true
    function onResourceReceived(path) {
      if (!path)
        return
      // respetar el tamaño maximo de imagen del proyecto (QFieldSync)
      try {
        var maximo = iface.readProjectNumEntry("qfieldsync", "maximumImageWidthHeight", 0)
        if (maximo > 0)
          FileUtils.restrictImageSize(qgisProject.homePath + "/" + path, maximo)   // CONFIRMAR-EN-BUILD
      } catch (err) {}
      campoFoto.cambioSolicitado(path, false)
    }
  }

  width: parent ? parent.width : 200
  height: Math.max(marco.height, botones.visible ? botones.height : 0)

  Rectangle {
    id: marco
    anchors.left: parent.left
    anchors.right: botones.visible ? botones.left : parent.right
    anchors.rightMargin: botones.visible ? 12 : 0
    height: campoFoto.miniaturaOk ? 200 : 48
    radius: campoFoto.estilo ? campoFoto.estilo.radioInput : 12
    clip: true
    color: campoFoto.miniaturaOk
      ? (campoFoto.estilo ? campoFoto.estilo.cardGris : "#EDEFF3")
      : "transparent"
    border.width: campoFoto.miniaturaOk || !campoFoto.validoHard || !campoFoto.validoSoft ? 1.5 : 0
    border.color: {
      if (!campoFoto.estilo) return "#C2C9D6"
      if (!campoFoto.validoHard) return campoFoto.estilo.colorError
      if (!campoFoto.validoSoft) return campoFoto.estilo.colorWarning
      return campoFoto.estilo.inputBorde
    }

    Image {
      id: miniatura
      anchors.fill: parent
      anchors.margins: 1.5
      visible: campoFoto.miniaturaOk
      source: campoFoto.mostrarMiniatura ? "file://" + campoFoto.rutaCompleta : ""
      fillMode: Image.PreserveAspectFit
      autoTransform: true
      asynchronous: true
      cache: false
      // limitar la decodificacion: la miniatura no necesita la foto completa
      sourceSize.width: 800
      sourceSize.height: 800
    }

    // sin foto, URL, archivo no imagen o archivo ausente en el celular
    Text {
      visible: !campoFoto.miniaturaOk
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.leftMargin: marco.border.width > 0 ? 16 : 0
      anchors.rightMargin: marco.border.width > 0 ? 16 : 0
      anchors.verticalCenter: parent.verticalCenter
      text: campoFoto.esNulo
        ? qsTr("Sin foto")
        : (campoFoto.esUrl ? campoFoto.textoValor : campoFoto.nombreArchivo(campoFoto.textoValor))
      font.pixelSize: 17
      font.weight: Font.DemiBold
      font.underline: campoFoto.esUrl
      elide: Text.ElideMiddle
      color: campoFoto.esNulo || (!campoFoto.esUrl && miniatura.status === Image.Error)
        ? (campoFoto.estilo ? campoFoto.estilo.textoDeshabilitado : "#8B94A6")
        : (campoFoto.estilo ? campoFoto.estilo.textoOscuro : "#1A2332")
    }

    MouseArea {
      anchors.fill: parent
      enabled: campoFoto.miniaturaOk || campoFoto.esUrl
      onClicked: campoFoto.abrir()
    }
  }

  // botones de edicion (mismo estilo que los de la cabecera del detalle)
  Column {
    id: botones
    visible: campoFoto.habilitado && (campoFoto.visorImagen || !campoFoto.esNulo)
    anchors.right: parent.right
    anchors.top: parent.top
    spacing: 12

    Rectangle {
      visible: campoFoto.visorImagen
      width: 44
      height: 44
      radius: 12
      color: campoFoto.estilo ? campoFoto.estilo.azulPalido : "#E8EEF9"

      Image {
        anchors.centerIn: parent
        width: 22
        height: 22
        sourceSize.width: 66
        sourceSize.height: 66
        source: Qt.resolvedUrl("icono_camara.svg")
      }
      MouseArea {
        anchors.fill: parent
        onClicked: campoFoto.capturar()
      }
    }

    Rectangle {
      visible: !campoFoto.esNulo
      width: 44
      height: 44
      radius: 12
      color: campoFoto.estilo ? campoFoto.estilo.cardGris : "#EDEFF3"

      Image {
        anchors.centerIn: parent
        width: 14
        height: 14
        sourceSize.width: 56
        sourceSize.height: 56
        source: Qt.resolvedUrl("icono_cerrar.svg")
      }
      MouseArea {
        anchors.fill: parent
        onClicked: campoFoto.cambioSolicitado("", true)
      }
    }
  }
}
