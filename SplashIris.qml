import QtQuick
import QtQuick.Shapes

// Isotipo SFN Iris animado para el splash. Cuenta la historia de la red:
//   1. La pupila: aparece el nodo central (el ojo/centro de la red).
//   2. Dilatacion: el cubo y los nodos externos se abren desde el centro (iris).
//   3. Los enlaces se tejen: las fibras (lineas del hexagono) se DIBUJAN de a poco
//      con trazo real (dashOffset animado sobre ShapePath).
//   4. Latido: la red queda viva, late en loop hasta que el splash se va.
//
// Todo vectorial (QtQuick.Shapes, GPU) con los paths exactos del SVG del Figma,
// en el lienzo 440x956 escalado tipo PreserveAspectFit (igual que el splash
// estatico, asi el wordmark de al lado queda alineado). Los transform de escala
// usan como origen el centro del isotipo (218.18, 374.907) para que todo se
// expanda/late desde la pupila.
Item {
  id: iris

  readonly property real vbW: 440
  readonly property real vbH: 956
  readonly property real cx: 218.18   // centro del isotipo (pupila)
  readonly property real cy: 374.907
  readonly property color azul: "#1C45AB"
  readonly property color blanco: "#ffffff"
  readonly property real grosor: 4

  // arranca la secuencia de entrada; al integrarse queda siempre true durante
  // la vida del splash (el componente se destruye cuando el splash se va)
  property bool playing: true

  // --- estado animado (0 = oculto) ---
  property real pupilaOp: 0
  property real pupilaScale: 0.3
  property real cuboOp: 0
  property real cuboScale: 0
  property real nodosOp: 0
  property real nodosScale: 0
  property real revelarFibras: 0   // 0 = fibras invisibles, 1 = dibujadas
  property real latidoScale: 1     // pulso del latido sobre la pupila
  property real haloOp: 0
  property real haloScale: 1
  property real pulsoFibras: 0     // 0..1: blip de luz que viaja por las fibras
  property real pulsoOp: 0

  // largo de las fibras en unidades de grosor (para el dash del trazo). Un dash
  // "encendido" de este largo cubre toda la fibra; animando dashOffset de este
  // valor a 0 la fibra se dibuja progresivamente.
  readonly property real dashFibra: 36

  // lienzo logico 440x956 escalado y centrado (PreserveAspectFit)
  Item {
    id: lienzo
    width: iris.vbW
    height: iris.vbH
    anchors.centerIn: parent
    transformOrigin: Item.Center
    scale: Math.min(iris.width / iris.vbW, iris.height / iris.vbH)

    // ---------- halos (glow falso, nucleo puro) detras de los nodos ----------
    Repeater {
      model: [
        { x: 137.95, y: 421.24 },   // nodo inferior izq
        { x: 217.803, y: 275.044 }, // nodo superior
        { x: 302.05, y: 424.013 },  // nodo inferior der
        { x: 218.18, y: 374.907 }   // pupila
      ]
      Rectangle {
        width: 46
        height: 46
        radius: 23
        color: iris.blanco
        x: modelData.x - width / 2
        y: modelData.y - height / 2
        opacity: iris.haloOp
        scale: iris.haloScale
        transformOrigin: Item.Center
      }
    }

    // ---------- nodos externos (3 circulos) ----------
    Item {
      anchors.fill: parent
      opacity: iris.nodosOp
      transform: Scale {
        origin.x: iris.cx; origin.y: iris.cy
        xScale: iris.nodosScale; yScale: iris.nodosScale
      }
      Shape {
        anchors.fill: parent
        ShapePath {
          fillColor: iris.azul; strokeColor: iris.blanco; strokeWidth: iris.grosor
          PathSvg { path: "M137.95 435.127C145.577 435.127 151.761 428.91 151.761 421.24C151.761 413.57 145.577 407.353 137.95 407.353C130.322 407.353 124.139 413.57 124.139 421.24C124.139 428.91 130.322 435.127 137.95 435.127Z" }
        }
        ShapePath {
          fillColor: iris.azul; strokeColor: iris.blanco; strokeWidth: iris.grosor
          PathSvg { path: "M217.803 288.931C225.43 288.931 231.614 282.713 231.614 275.044C231.614 267.374 225.43 261.156 217.803 261.156C210.175 261.156 203.991 267.374 203.991 275.044C203.991 282.713 210.175 288.931 217.803 288.931Z" }
        }
        ShapePath {
          fillColor: iris.azul; strokeColor: iris.blanco; strokeWidth: iris.grosor
          PathSvg { path: "M302.05 437.9C309.678 437.9 315.861 431.683 315.861 424.013C315.861 416.343 309.678 410.126 302.05 410.126C294.422 410.126 288.239 416.343 288.239 424.013C288.239 431.683 294.422 437.9 302.05 437.9Z" }
        }
      }
    }

    // ---------- fibras (3 lineas del hexagono) con trazo real ----------
    // strokeStyle DashLine + dashOffset animado = el enlace se dibuja.
    Item {
      anchors.fill: parent
      Shape {
        anchors.fill: parent
        ShapePath {
          fillColor: "transparent"; strokeColor: iris.blanco; strokeWidth: iris.grosor
          capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
          strokeStyle: ShapePath.DashLine
          dashPattern: [iris.dashFibra, iris.dashFibra]
          dashOffset: iris.dashFibra * (1 - iris.revelarFibras)
          PathSvg { path: "M134.309 373.14V323.146L204.87 281.863" }
        }
        ShapePath {
          fillColor: "transparent"; strokeColor: iris.blanco; strokeWidth: iris.grosor
          capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
          strokeStyle: ShapePath.DashLine
          dashPattern: [iris.dashFibra, iris.dashFibra]
          dashOffset: iris.dashFibra * (1 - iris.revelarFibras)
          PathSvg { path: "M302.803 406.844V323.774L258.608 297.009" }
        }
        ShapePath {
          fillColor: "transparent"; strokeColor: iris.blanco; strokeWidth: iris.grosor
          capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
          strokeStyle: ShapePath.DashLine
          dashPattern: [iris.dashFibra, iris.dashFibra]
          dashOffset: iris.dashFibra * (1 - iris.revelarFibras)
          PathSvg { path: "M150.38 429.95L218.933 469.718L260.868 444.09" }
        }
      }
    }

    // ---------- pulso de senal viajando por las fibras (latido) ----------
    // un blip corto (dash [4,92]) que se desplaza sobre cada fibra = la senal
    // recorriendo la red de fibra. Se enciende con cada latido.
    Item {
      anchors.fill: parent
      opacity: iris.pulsoOp
      Shape {
        anchors.fill: parent
        ShapePath {
          fillColor: "transparent"; strokeColor: "#eaf1ff"; strokeWidth: iris.grosor + 1.5
          capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
          strokeStyle: ShapePath.DashLine
          dashPattern: [4, 92]; dashOffset: 96 * iris.pulsoFibras
          PathSvg { path: "M134.309 373.14V323.146L204.87 281.863" }
        }
        ShapePath {
          fillColor: "transparent"; strokeColor: "#eaf1ff"; strokeWidth: iris.grosor + 1.5
          capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
          strokeStyle: ShapePath.DashLine
          dashPattern: [4, 92]; dashOffset: 96 * iris.pulsoFibras
          PathSvg { path: "M302.803 406.844V323.774L258.608 297.009" }
        }
        ShapePath {
          fillColor: "transparent"; strokeColor: "#eaf1ff"; strokeWidth: iris.grosor + 1.5
          capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
          strokeStyle: ShapePath.DashLine
          dashPattern: [4, 92]; dashOffset: 96 * iris.pulsoFibras
          PathSvg { path: "M150.38 429.95L218.933 469.718L260.868 444.09" }
        }
      }
    }

    // ---------- cubo central (3 caras) ----------
    Item {
      anchors.fill: parent
      opacity: iris.cuboOp
      transform: Scale {
        origin.x: iris.cx; origin.y: iris.cy
        xScale: iris.cuboScale; yScale: iris.cuboScale
      }
      Shape {
        anchors.fill: parent
        ShapePath {
          fillColor: iris.azul; strokeColor: iris.blanco; strokeWidth: iris.grosor
          capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
          PathSvg { path: "M177.751 352.309L218.681 326.807L257.478 350.036L221.569 374.907L177.751 352.309Z" }
        }
        ShapePath {
          fillColor: iris.azul; strokeColor: iris.blanco; strokeWidth: iris.grosor
          capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
          PathSvg { path: "M177.5 394.349L177.751 352.308L221.57 374.906L220.691 418.461L177.5 394.349Z" }
        }
        ShapePath {
          fillColor: iris.azul; strokeColor: iris.blanco; strokeWidth: iris.grosor
          capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
          PathSvg { path: "M220.691 418.461L256.85 396.873L257.478 350.035L221.569 374.906L220.691 418.461Z" }
        }
      }
    }

    // ---------- pupila (nodo central) ----------
    Item {
      anchors.fill: parent
      opacity: iris.pupilaOp
      transform: Scale {
        origin.x: iris.cx; origin.y: iris.cy
        xScale: iris.pupilaScale * iris.latidoScale
        yScale: iris.pupilaScale * iris.latidoScale
      }
      Shape {
        anchors.fill: parent
        ShapePath {
          fillColor: iris.azul; strokeColor: iris.blanco; strokeWidth: iris.grosor
          PathSvg { path: "M218.18 388.794C225.808 388.794 231.991 382.577 231.991 374.907C231.991 367.237 225.808 361.02 218.18 361.02C210.552 361.02 204.369 367.237 204.369 374.907C204.369 382.577 210.552 388.794 218.18 388.794Z" }
        }
      }
    }
  }

  // ======================= ANIMACIONES =======================

  // Entrada: pupila -> dilatacion (cubo + nodos) -> se tejen las fibras -> latido.
  SequentialAnimation {
    id: entrada
    running: iris.playing

    // 1. la pupila aparece con un pop
    ParallelAnimation {
      NumberAnimation { target: iris; property: "pupilaOp"; from: 0; to: 1; duration: 320; easing.type: Easing.OutCubic }
      NumberAnimation { target: iris; property: "pupilaScale"; from: 0.3; to: 1; duration: 460; easing.type: Easing.OutBack }
    }

    // 2. dilatacion: el cubo y los nodos se abren desde el centro
    ParallelAnimation {
      NumberAnimation { target: iris; property: "cuboOp"; from: 0; to: 1; duration: 380; easing.type: Easing.OutCubic }
      NumberAnimation { target: iris; property: "cuboScale"; from: 0; to: 1; duration: 520; easing.type: Easing.OutCubic }
      SequentialAnimation {
        PauseAnimation { duration: 120 }
        ParallelAnimation {
          NumberAnimation { target: iris; property: "nodosOp"; from: 0; to: 1; duration: 360; easing.type: Easing.OutCubic }
          NumberAnimation { target: iris; property: "nodosScale"; from: 0; to: 1; duration: 480; easing.type: Easing.OutBack }
        }
      }
    }

    // 3. los enlaces se tejen (trazo real)
    NumberAnimation { target: iris; property: "revelarFibras"; from: 0; to: 1; duration: 560; easing.type: Easing.InOutQuad }

    // 4. arranca el latido
    ScriptAction { script: latido.start() }
  }

  // Latido en loop: la red viva. Con cada latido la pupila pulsa, los nodos
  // destellan (halos) y un pulso de senal recorre las fibras. Corre hasta que
  // el componente se destruye (splash se va).
  SequentialAnimation {
    id: latido
    loops: Animation.Infinite

    // arranque del latido: pupila + halos + el pulso empieza a viajar
    ParallelAnimation {
      // heartbeat de la pupila
      SequentialAnimation {
        NumberAnimation { target: iris; property: "latidoScale"; from: 1.0; to: 1.13; duration: 200; easing.type: Easing.OutQuad }
        NumberAnimation { target: iris; property: "latidoScale"; from: 1.13; to: 1.0; duration: 440; easing.type: Easing.InQuad }
      }
      // destello de los nodos
      SequentialAnimation {
        NumberAnimation { target: iris; property: "haloOp"; from: 0; to: 0.4; duration: 200; easing.type: Easing.OutQuad }
        NumberAnimation { target: iris; property: "haloOp"; from: 0.4; to: 0; duration: 420; easing.type: Easing.InQuad }
      }
      NumberAnimation { target: iris; property: "haloScale"; from: 1.0; to: 1.7; duration: 620; easing.type: Easing.OutQuad }
      // la senal viaja por las fibras
      SequentialAnimation {
        NumberAnimation { target: iris; property: "pulsoOp"; from: 0; to: 0.95; duration: 130; easing.type: Easing.OutQuad }
        PauseAnimation { duration: 380 }
        NumberAnimation { target: iris; property: "pulsoOp"; from: 0.95; to: 0; duration: 170; easing.type: Easing.InQuad }
      }
      NumberAnimation { target: iris; property: "pulsoFibras"; from: 0; to: 1; duration: 680; easing.type: Easing.InOutQuad }
    }
    // resetear para el proximo latido
    ScriptAction { script: { iris.haloScale = 1.0; iris.pulsoFibras = 0 } }
    PauseAnimation { duration: 1050 }
  }
}
