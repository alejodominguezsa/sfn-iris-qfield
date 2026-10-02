import QtQuick

// Una fila de campo del formulario de detalle: etiqueta + control (elegido por
// tipo de widget y modo). Todos los datos llegan por properties inyectadas
// desde el delegate (los roles del modelo solo resuelven en el contexto del
// delegate, nunca dentro de un Component inline: leccion de la review v0.3.0).
EnvoltorioCampo {
  id: fila

  property var controlador      // DetalleElemento (funciones y estado)
  property var gadgetCampo      // QgsField
  property var config: ({})
  property string tipoWidget: ""
  property var valorActual
  property bool editable: false

  estilo: controlador ? controlador.estilo : null

  Loader {
    width: parent.width
    source: {
      // leer enEdicion aca registra la dependencia del binding aunque
      // urlComponente tambien la lea internamente
      var enEd = fila.controlador ? fila.controlador.enEdicion : false
      return Qt.resolvedUrl(fila.controlador
        ? fila.controlador.urlComponente(fila.tipoWidget)
        : "CampoSoloLectura.qml")
    }
    onLoaded: {
      // TODO por binding: este onLoaded puede correr antes de que el delegate
      // haya inyectado las props de la fila (orden de creacion QML); con
      // bindings los valores fluyen aunque lleguen despues
      item.estilo = Qt.binding(function () {
        return fila.controlador ? fila.controlador.estilo : null
      })
      item.campo = Qt.binding(function () {
        return fila.gadgetCampo
      })
      item.config = Qt.binding(function () {
        return fila.config ? fila.config : {}
      })
      item.tipoWidget = Qt.binding(function () {
        return fila.tipoWidget
      })
      item.valor = Qt.binding(function () {
        return fila.valorActual
      })
      item.habilitado = Qt.binding(function () {
        return fila.controlador && fila.controlador.enEdicion && fila.editable
      })
      item.validoHard = Qt.binding(function () {
        return fila.validoHard
      })
      item.validoSoft = Qt.binding(function () {
        return fila.validoSoft
      })
      // diagnostico visible: si el fallback renderiza en modo edicion, mostrar
      // que tipo de widget quedo sin editor
      if (item.tipoNoEditable !== undefined) {
        item.tipoNoEditable = Qt.binding(function () {
          if (!fila.controlador || !fila.controlador.enEdicion || fila.tipoWidget === "")
            return ""
          return fila.controlador.urlComponente(fila.tipoWidget) === "CampoSoloLectura.qml"
            ? fila.tipoWidget : ""
        })
      }
      // CampoFoto necesita capa y feature para la expresion de nombre
      if (item.capa !== undefined) {
        item.capa = Qt.binding(function () {
          return fila.controlador ? fila.controlador.modeloFeatureActual.currentLayer : null
        })
        item.feature = Qt.binding(function () {
          return fila.controlador ? fila.controlador.modeloFeatureActual.feature : null
        })
      }
      item.cambioSolicitado.connect(function (v, esNull) {
        if (fila.controlador)
          fila.controlador.aplicarCambio(fila.gadgetCampo, fila.etiqueta, fila.valorActual, v, esNull)
      })
    }
  }
}
