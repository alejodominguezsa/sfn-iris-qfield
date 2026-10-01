import QtQuick

// Envoltorio visual de un campo del formulario SFN: etiqueta (alias del campo),
// el control adentro, y el mensaje de constraint cuando corresponde.
// El color de borde por constraint lo maneja cada control (recibe validoHard/
// validoSoft); aca va la etiqueta y el texto descriptivo.
Column {
  id: envoltorio

  property var estilo
  property string etiqueta: ""
  property bool validoHard: true
  property bool validoSoft: true
  property string descripcionConstraint: ""

  default property alias contenido: zonaContenido.data

  spacing: 6

  Text {
    width: parent.width
    text: envoltorio.etiqueta
    font.pixelSize: 13
    font.weight: Font.DemiBold
    color: envoltorio.estilo ? envoltorio.estilo.textoSecundario : "#6D717F"
    elide: Text.ElideRight
  }

  Item {
    id: zonaContenido
    width: parent.width
    height: childrenRect.height
  }

  Text {
    width: parent.width
    visible: (!envoltorio.validoHard || !envoltorio.validoSoft) && envoltorio.descripcionConstraint !== ""
    text: envoltorio.descripcionConstraint
    font.pixelSize: 12
    color: !envoltorio.validoHard
      ? (envoltorio.estilo ? envoltorio.estilo.colorError : "#EF4444")
      : (envoltorio.estilo ? envoltorio.estilo.colorWarning : "#F59E0B")
    wrapMode: Text.WordWrap
  }
}
