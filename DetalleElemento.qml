import QtQuick
import QtQuick.Controls
import org.qfield
import Theme

// Hoja "Detalle de elemento" del plugin SFN Iris.
//
// Replica el ciclo de edicion del formulario nativo de QField con estilo SFN:
// abre en modo LECTURA (valores presentados); el lapiz pasa a modo EDICION
// (controles editables); el check verde guarda; la ✕ en edicion cancela (con
// dialogo si hay cambios) y en lectura cierra todo.
//
// La edicion y el guardado van por la MISMA cadena de modelos que el form
// nativo (FeatureModel + AttributeFormModel de org.qfield): constraints,
// defaults dependientes, visibilidad condicional y commit son 100% QGIS.
// Este componente solo pone la piel. Detalle en docs/03-formulario-editable.md.
Rectangle {
  id: detalle

  property var estilo
  property var formNativo        // FeatureListForm nativo (objectName "featureForm")
  property var ventana
  property int indice: -1
  property int cantidad: 0
  property bool enEdicion: false
  property bool hayCambios: false
  property string tituloElemento: ""
  property string nombreCapa: ""

  signal pedirCerrarTodo()
  signal pedirNavegar(int delta)

  // expuesto para CardGrupo (SubModel necesita el modelo y sus indices)
  readonly property var modeloFormulario: modeloForm
  // expuesto para CampoFoto (capa y feature para la expresion de nombre)
  readonly property var modeloFeatureActual: modeloFeature

  // Si el detalle se oculta por afuera con el dialogo abierto, no dejar el
  // overlay modal huerfano sobre la app (esta reparentado a la ventana).
  onVisibleChanged: {
    if (!visible) {
      dialogoCancelar.visible = false
      expandida = false
    }
  }

  readonly property bool bloqueadoPorCapa: modeloFeature.attributeEditingLocked === true
  readonly property bool puedeEditar: {
    if (!formNativo || bloqueadoPorCapa)
      return false
    if (estilo && estilo.exigirModoEdicionQField)
      return formNativo.allowEdit === true   // CONFIRMAR-EN-BUILD: property del FeatureListForm
    return true
  }

  // ============ cadena de modelos nativa ============
  // CONFIRMAR-EN-BUILD: FeatureModel y AttributeFormModel instanciables desde
  // un plugin. Si no lo son, este archivo falla al cargar y main.qml degrada
  // al form nativo (Loader con fallback).
  FeatureModel {
    id: modeloFeature
  }

  AttributeFormModel {
    id: modeloForm
    featureModel: modeloFeature
  }

  // Carga imperativa con orden estricto (no usar bindings sobre feature ni
  // currentLayer: el orden de reevaluacion no esta garantizado).
  function cargar() {
    enEdicion = false
    hayCambios = false
    dialogoCancelar.visible = false
    if (!formNativo || !formNativo.selection)
      return
    var capa = formNativo.selection.focusedLayer
    var elemento = formNativo.selection.focusedFeature
    modeloFeature.project = qgisProject   // CONFIRMAR-EN-BUILD: global visible desde hermanos
    modeloFeature.currentLayer = capa
    modeloFeature.feature = elemento
    modeloForm.applyFeatureModel()
    nombreCapa = capa && capa.name !== undefined ? String(capa.name) : ""
    try {
      tituloElemento = FeatureUtils.displayName(capa, elemento)
    } catch (err) {
      tituloElemento = ""
    }
    flick.contentY = 0
  }

  // Componente por tipo de widget QGIS. ValueMap, ValueRelation y
  // ExternalResource usan el suyo tambien en lectura (resuelven etiquetas,
  // chips o miniatura); el resto solo en edicion.
  function urlComponente(widget) {
    switch (widget) {
    case "ValueMap":
      return "CampoOpciones.qml"
    case "ValueRelation":
      return "CampoRelacion.qml"
    case "ExternalResource":
      return "CampoFoto.qml"
    case "TextEdit":
      return enEdicion ? "CampoTexto.qml" : "CampoSoloLectura.qml"
    case "Range":
      return enEdicion ? "CampoRango.qml" : "CampoSoloLectura.qml"
    case "CheckBox":
      return enEdicion ? "CampoInterruptor.qml" : "CampoSoloLectura.qml"
    case "DateTime":
      return enEdicion ? "CampoFechaHora.qml" : "CampoSoloLectura.qml"
    default:
      // RelationEditor, UuidGenerator, etc: solo lectura
      return "CampoSoloLectura.qml"
    }
  }

  function mismoValor(a, b) {
    var aNulo = (a === undefined || a === null || a === "")
    var bNulo = (b === undefined || b === null || b === "")
    if (aNulo && bNulo)
      return true
    if (aNulo !== bNulo)
      return false
    return String(a) === String(b)
  }

  function aplicarCambio(gadgetCampo, alias, valorActual, valorNuevo, esNull) {
    var nuevo = esNull ? undefined : valorNuevo
    if (mismoValor(valorActual, nuevo))
      return
    // changeAttribute espera el NOMBRE REAL del campo (fields().indexOf), no el alias
    var nombre = (gadgetCampo && gadgetCampo.name !== undefined) ? gadgetCampo.name : alias
    if (modeloForm.changeAttribute(nombre, nuevo))
      hayCambios = true
  }

  function intentarGuardar() {
    if (!modeloForm.constraintsHardValid) {
      iface.mainWindow().displayToast(qsTr("Hay campos con valores invalidos"))
      return false
    }
    if (modeloForm.save()) {
      iface.mainWindow().displayToast(qsTr("Cambios guardados"))
      // No recargar desde la selection nativa: su snapshot quedo pre-commit y
      // pisaria lo guardado. El FeatureModel ya releyo el feature comiteado.
      hayCambios = false
      enEdicion = false
      modeloForm.applyFeatureModel()
      try {
        tituloElemento = FeatureUtils.displayName(modeloFeature.currentLayer, modeloFeature.feature)
      } catch (err) {}
      return true
    }
    iface.mainWindow().displayToast(qsTr("No se pudo guardar: revisa los permisos de la capa"))
    return false
  }

  function salirDeEdicion() {
    if (!hayCambios) {
      enEdicion = false
      return
    }
    dialogoCancelar.abrir()
  }

  // ✕ y tap fuera de la hoja pasan por aca
  function manejarCierre() {
    if (enEdicion)
      salirDeEdicion()
    else
      pedirCerrarTodo()
  }

  // ============ presentacion ============

  // Altura minima fija: 55% de pantalla, siempre >= que el panel nativo de
  // QField (que en vertical no supera el 50%), asi nunca se asoma por detras.
  // Arrastrando el handle hacia arriba la hoja pasa a pantalla completa;
  // hacia abajo vuelve al minimo. El contenido que no entra se scrollea.
  readonly property real alturaMinima: ventana ? Math.max(ventana.height * 0.55, 420) : 500
  readonly property real alturaCompleta: ventana ? ventana.height - 8 : 800
  property bool expandida: false

  width: parent ? parent.width : 400
  height: expandida ? alturaCompleta : alturaMinima
  radius: estilo ? estilo.radioHoja : 24
  color: estilo ? estilo.hojaFondo : "#ffffff"

  Behavior on height {
    NumberAnimation {
      duration: 200
      easing.type: Easing.OutCubic
    }
  }

  Rectangle {
    width: 158
    height: 6
    radius: 3
    color: detalle.estilo ? detalle.estilo.manija : "#C2C9D6"
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    anchors.topMargin: 12
  }

  // zona de arrastre del handle: swipe arriba = pantalla completa,
  // swipe abajo = altura minima. Sobresale 24px por encima del borde de la
  // hoja porque el pulgar suele apoyar un poco mas arriba del handle.
  MouseArea {
    anchors.top: parent.top
    anchors.topMargin: -24
    anchors.left: parent.left
    anchors.right: parent.right
    height: 54
    preventStealing: true
    property real yInicial: 0
    onPressed: function (mouse) {
      yInicial = mouse.y
    }
    onReleased: function (mouse) {
      var delta = mouse.y - yInicial
      if (delta < -40)
        detalle.expandida = true
      else if (delta > 40)
        detalle.expandida = false
    }
  }

  Item {
    id: cabecera
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.leftMargin: 20
    anchors.rightMargin: 20
    height: 148

    // --- fila de botones ---
    Row {
      id: botonesIzquierda
      anchors.top: parent.top
      anchors.topMargin: 30
      anchors.left: parent.left
      spacing: 12

      // lectura: navegacion entre elementos
      Rectangle {
        visible: !detalle.enEdicion
        width: 44
        height: 44
        radius: 12
        color: detalle.estilo ? detalle.estilo.azulBoton : "#E3E9F8"
        opacity: detalle.indice > 0 ? 1 : 0.35

        Image {
          anchors.centerIn: parent
          width: 20
          height: 20
          sourceSize.width: 60
          sourceSize.height: 60
          source: Qt.resolvedUrl("icono_chevron_izq.svg")
        }
        MouseArea {
          anchors.fill: parent
          enabled: detalle.indice > 0
          onClicked: detalle.pedirNavegar(-1)
        }
      }

      Rectangle {
        visible: !detalle.enEdicion
        width: 44
        height: 44
        radius: 12
        color: detalle.estilo ? detalle.estilo.azulBoton : "#E3E9F8"
        opacity: detalle.indice < detalle.cantidad - 1 ? 1 : 0.35

        Image {
          anchors.centerIn: parent
          width: 20
          height: 20
          sourceSize.width: 60
          sourceSize.height: 60
          source: Qt.resolvedUrl("icono_chevron_der.svg")
        }
        MouseArea {
          anchors.fill: parent
          enabled: detalle.indice < detalle.cantidad - 1
          onClicked: detalle.pedirNavegar(1)
        }
      }

      // edicion: guardar
      Rectangle {
        visible: detalle.enEdicion
        width: 44
        height: 44
        radius: 12
        color: modeloForm.constraintsHardValid
          ? (detalle.estilo ? detalle.estilo.colorGuardar : "#10B981")
          : (detalle.estilo ? detalle.estilo.cardGris : "#EDEFF3")
        opacity: modeloForm.constraintsHardValid ? 1 : 0.7

        Image {
          anchors.centerIn: parent
          width: 22
          height: 22
          sourceSize.width: 66
          sourceSize.height: 66
          source: Qt.resolvedUrl("icono_check_guardar.svg")
          opacity: modeloForm.constraintsHardValid ? 1 : 0.5
        }
        MouseArea {
          anchors.fill: parent
          onClicked: detalle.intentarGuardar()
        }
      }
    }

    Row {
      id: botonesDerecha
      anchors.top: parent.top
      anchors.topMargin: 30
      anchors.right: parent.right
      spacing: 12

      // lectura: lapiz para pasar a edicion
      Rectangle {
        visible: !detalle.enEdicion && detalle.puedeEditar
        width: 44
        height: 44
        radius: 12
        color: detalle.estilo ? detalle.estilo.azulPalido : "#E8EEF9"

        Image {
          anchors.centerIn: parent
          width: 20
          height: 20
          sourceSize.width: 60
          sourceSize.height: 60
          source: Qt.resolvedUrl("icono_lapiz.svg")
        }
        MouseArea {
          anchors.fill: parent
          onClicked: detalle.enEdicion = true
        }
      }

      Rectangle {
        width: 44
        height: 44
        radius: 12
        color: detalle.estilo ? detalle.estilo.cardGris : "#EDEFF3"

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
          onClicked: detalle.manejarCierre()
        }
      }
    }

    // --- fila de titulo ---
    Row {
      id: filaTitulo
      anchors.top: botonesIzquierda.bottom
      anchors.topMargin: 18
      anchors.left: parent.left
      anchors.right: parent.right
      spacing: 12

      Rectangle {
        visible: detalle.nombreCapa !== ""
        width: chipCapaTexto.width + 24
        height: 30
        radius: 8
        color: detalle.estilo ? detalle.estilo.azulPalido : "#E8EEF9"
        anchors.verticalCenter: parent.verticalCenter

        Text {
          id: chipCapaTexto
          anchors.centerIn: parent
          text: detalle.nombreCapa.toUpperCase()
          font.pixelSize: 12
          font.bold: true
          color: detalle.estilo ? detalle.estilo.azul : "#1C45AB"
        }
      }

      Text {
        width: Math.min(implicitWidth, filaTitulo.width - 130)
        anchors.verticalCenter: parent.verticalCenter
        text: detalle.tituloElemento
        font.pixelSize: 23
        font.bold: true
        color: detalle.estilo ? detalle.estilo.textoOscuro : "#1A2332"
        elide: Text.ElideRight
      }

      // badge de capa bloqueada
      Rectangle {
        visible: detalle.bloqueadoPorCapa
        width: textoBloqueado.width + 20
        height: 26
        radius: 13
        color: detalle.estilo ? detalle.estilo.cardGris : "#EDEFF3"
        anchors.verticalCenter: parent.verticalCenter

        Text {
          id: textoBloqueado
          anchors.centerIn: parent
          text: qsTr("Solo lectura")
          font.pixelSize: 11
          font.bold: true
          color: detalle.estilo ? detalle.estilo.textoSecundario : "#6D717F"
        }
      }
    }

    Text {
      anchors.top: filaTitulo.bottom
      anchors.topMargin: 6
      anchors.left: parent.left
      text: detalle.enEdicion
        ? qsTr("Editando elemento")
        : qsTr("Elemento %1 de %2").arg(detalle.indice + 1).arg(detalle.cantidad)
      font.pixelSize: 13
      color: detalle.estilo ? detalle.estilo.textoSecundario : "#6D717F"
    }
  }

  // ============ contenido: cards de campos ============

  Flickable {
    id: flick
    anchors.top: cabecera.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.leftMargin: 20
    anchors.rightMargin: 20
    anchors.bottomMargin: (detalle.estilo ? detalle.estilo.radioHoja : 24) + 16
    contentHeight: columnaContenido.height
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    Column {
      id: columnaContenido
      width: flick.width
      spacing: 14

      // card principal: campos de primer nivel (sin grupo)
      Rectangle {
        width: parent.width
        radius: detalle.estilo ? detalle.estilo.radioCard : 16
        color: detalle.estilo ? detalle.estilo.card : "#F7F8FA"
        border.width: 1.5
        border.color: detalle.estilo ? detalle.estilo.cardBorde : "#E3E6EC"
        height: visible ? columnaSueltos.height + 40 : 0
        visible: columnaSueltos.height > 0

        Column {
          id: columnaSueltos
          x: 20
          y: 20
          width: parent.width - 40
          spacing: 16

          Repeater {
            model: modeloForm
            // Los roles del modelo SOLO resuelven en el contexto del delegate:
            // se inyectan por properties (nunca usar Components inline que los
            // referencien adentro; se instancian en el contexto raiz).
            delegate: Loader {
              width: columnaSueltos.width
              active: model.Type === "field" && model.EditorWidget !== "Hidden"
              visible: active
              source: Qt.resolvedUrl("FilaCampo.qml")
              onLoaded: {
                item.controlador = detalle
                item.etiqueta = Qt.binding(function () {
                  return model.Name !== undefined ? String(model.Name) : ""
                })
                item.gadgetCampo = Qt.binding(function () {
                  return model.Field
                })
                item.config = Qt.binding(function () {
                  return model.EditorWidgetConfig ? model.EditorWidgetConfig : {}
                })
                item.tipoWidget = Qt.binding(function () {
                  return model.EditorWidget !== undefined ? String(model.EditorWidget) : ""
                })
                item.valorActual = Qt.binding(function () {
                  return model.AttributeValue
                })
                item.editable = Qt.binding(function () {
                  return model.AttributeEditable === true && model.AttributeAllowEdit !== false
                })
                item.validoHard = Qt.binding(function () {
                  return model.ConstraintHardValid === undefined ? true : model.ConstraintHardValid === true
                })
                item.validoSoft = Qt.binding(function () {
                  return model.ConstraintSoftValid === undefined ? true : model.ConstraintSoftValid === true
                })
                item.descripcionConstraint = Qt.binding(function () {
                  return model.ConstraintDescription !== undefined && model.ConstraintDescription !== null
                    ? String(model.ConstraintDescription) : ""
                })
              }
            }
          }
        }
      }

      // una card por grupo (group box o tab del designer de QGIS)
      Repeater {
        model: modeloForm
        delegate: Loader {
          width: columnaContenido.width
          active: model.Type === "container"
          visible: active
          source: Qt.resolvedUrl("CardGrupo.qml")
          onLoaded: {
            item.controlador = detalle
            item.indiceFila = index
            item.tituloGrupo = Qt.binding(function () {
              return model.Name !== undefined ? String(model.Name) : ""
            })
          }
        }
      }
    }
  }

  DialogoCancelarEdicion {
    id: dialogoCancelar
    estilo: detalle.estilo
    // cubrir la ventana entera, no solo la hoja
    parent: detalle.ventana && detalle.ventana.contentItem ? detalle.ventana.contentItem : detalle
    anchors.fill: parent
    z: 200
    onDescartar: {
      detalle.cargar()   // recarga el feature original: descarta el buffer propio
    }
  }
}
