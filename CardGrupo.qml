import QtQuick
import org.qfield

// Card de un grupo del formulario (group box o tab del designer de QGIS):
// titulo + sus campos directos, iterados con SubModel sobre la fila container.
// Limitacion v0.3.0 documentada: containers anidados dentro del grupo no se
// recorren. Roles y datos llegan por properties inyectadas desde el delegate.
Rectangle {
  id: cardGrupo

  property var controlador      // DetalleElemento
  property string tituloGrupo: ""
  property int indiceFila: -1

  radius: controlador && controlador.estilo ? controlador.estilo.radioCard : 16
  color: controlador && controlador.estilo ? controlador.estilo.card : "#F7F8FA"
  border.width: 1.5
  border.color: controlador && controlador.estilo ? controlador.estilo.cardBorde : "#E3E6EC"
  height: columnaGrupo.height + 40

  Column {
    id: columnaGrupo
    x: 20
    y: 20
    width: parent.width - 40
    spacing: 16

    Text {
      width: parent.width
      text: cardGrupo.tituloGrupo
      font.pixelSize: 15
      font.bold: true
      color: cardGrupo.controlador && cardGrupo.controlador.estilo
        ? cardGrupo.controlador.estilo.azul : "#1C45AB"
      elide: Text.ElideRight
    }

    Repeater {
      // CONFIRMAR-EN-BUILD: SubModel instanciable + index(row, 0) desde QML
      model: SubModel {
        model: cardGrupo.controlador ? cardGrupo.controlador.modeloFormulario : null
        rootIndex: cardGrupo.controlador && cardGrupo.indiceFila >= 0
          ? cardGrupo.controlador.modeloFormulario.index(cardGrupo.indiceFila, 0)
          : undefined
      }
      delegate: Loader {
        width: columnaGrupo.width
        active: model.Type === "field" && model.EditorWidget !== "Hidden"
        visible: active
        source: Qt.resolvedUrl("FilaCampo.qml")
        onLoaded: {
          item.controlador = cardGrupo.controlador
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
