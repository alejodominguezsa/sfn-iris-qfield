import QtQuick
import QtQuick.Controls
import org.qfield
import Theme

// SFN Iris: plugin app-wide de branding para QField.
// Aplica la paleta corporativa SFN Iris sobre el singleton Theme y cambia el
// logo de QField por el isotipo SFN Iris donde puede encontrarlo.
// Todo es en runtime: no toca el APK, el icono del launcher ni el nombre de la app.

Item {
  id: plugin

  // =====================================================================
  // CONFIGURACION
  //
  // Paleta SFN Iris. Fuente: Manual de Marca SFN Iris 2026, pag. 12.
  //   Azules de marca:     #1C45AB  #2D5FD0  #4A7AE8  #E8EEF9
  //   Acentos funcionales: #10B981  #F59E0B  #EF4444  #00B4D8  #A0ABC0  #1A2332
  //   Grises de UI (Figma): borde #C2C9D6, texto secundario #6D717F
  //
  // Las claves son propiedades del singleton Theme de QField. Las que no
  // existan en la version instalada se ignoran solas (applyColors saltea
  // claves desconocidas; el fallback chequea antes de asignar).
  // Mapeo completo documentado en docs/01-brand-y-theme.md.
  // =====================================================================

  readonly property var paletaClara: ({
    "mainColor": "#1C45AB",
    "mainOverlayColor": "#ffffff",
    "mainBackgroundColor": "#fbfcfe",
    "mainBackgroundColorSemiOpaque": "#bbfbfcfe",
    "mainTextColor": "#1A2332",
    "mainTextDisabledColor": "#731A2332",
    "secondaryTextColor": "#6D717F",
    "controlBackgroundColor": "#ffffff",
    "controlBackgroundAlternateColor": "#E8EEF9",
    "controlBackgroundDisabledColor": "#33A0ABC0",
    // Ojo: ademas de bordes, QField pinta con esto los headers de seccion
    // del identify (FeatureListForm). #E8EEF9 los deja como las cards del
    // Figma; el borde de controles queda mas sutil, trade-off aceptado.
    "controlBorderColor": "#E8EEF9",
    "buttonColor": "#ffffff",
    "buttonBackgroundColor": "#1C45AB",
    "toolButtonColor": "#ffffff",
    "toolButtonBackgroundColor": "#1A2332",
    "toolButtonBackgroundSemiOpaqueColor": "#4d1A2332",
    "scrollBarBackgroundColor": "#aafbfcfe",
    "groupBoxBackgroundColor": "#EFF3FA",
    "groupBoxSurfaceColor": "#E8EEF9",
    "goodColor": "#10B981",
    "warningColor": "#F59E0B",
    "errorColor": "#EF4444"
  })

  readonly property var paletaOscura: ({
    "mainColor": "#4A7AE8",
    "mainOverlayColor": "#ffffff",
    "mainBackgroundColor": "#141B26",
    "mainBackgroundColorSemiOpaque": "#bb141B26",
    "mainTextColor": "#E8EEF9",
    "mainTextDisabledColor": "#73E8EEF9",
    "secondaryTextColor": "#A0ABC0",
    "controlBackgroundColor": "#1A2332",
    "controlBackgroundAlternateColor": "#232E40",
    "controlBackgroundDisabledColor": "#33555555",
    "controlBorderColor": "#2E3A4F",
    "buttonColor": "#1A2332",
    "buttonBackgroundColor": "#2D5FD0",
    "toolButtonColor": "#ffffff",
    "toolButtonBackgroundColor": "#232E40",
    "toolButtonBackgroundSemiOpaqueColor": "#4d232E40",
    "scrollBarBackgroundColor": "#bb141B26",
    "groupBoxBackgroundColor": "#1E2735",
    "groupBoxSurfaceColor": "#243043",
    "goodColor": "#10B981",
    "warningColor": "#F59E0B",
    "errorColor": "#EF4444"
  })

  // Arranque rapido: se intenta el swap apenas carga el plugin y se reintenta
  // corto hasta pescar el logo de la Welcome, para achicar la ventana en que
  // se ve el logo de QField (antes habia una espera fija de 800 ms).
  readonly property int intervaloArranqueMs: 120
  readonly property int topeTicksArranque: 40

  // Splash SFN: overlay que tapa el arranque de QField hasta que el branding
  // esta aplicado. Mismo navy que el splash nativo del APK (fondo del
  // "Splash Screen v0.2" del Figma) para que la transicion sea invisible.
  // Se va cuando el swap del logo ya ocurrio Y paso el minimo de exhibicion;
  // el tope duro garantiza que jamas quede la pantalla tapada aunque QField
  // cambie internals. Con PluginReloader el splash reaparece en cada recarga:
  // es esperable, confirma la recarga.
  readonly property int splashMinimoMs: 2500
  readonly property int splashTopeMs: 4500
  readonly property int splashFadeMs: 450
  readonly property color splashFondo: "#08165F"
  // El reemplazo de logos se reintenta porque hay pantallas (Acerca de) que
  // se instancian tarde.
  readonly property int reintentosLogo: 5
  readonly property int intervaloReintentoMs: 2000
  // Tope de profundidad al recorrer el arbol visual buscando logos.
  readonly property int profundidadMaxima: 30

  // Reglas de texto de la Welcome (best effort, igual que el swap de logos).
  // Dos formas: {exactos: [..], texto} pisa el texto completo SOLO si el
  // texto actual es identico a alguno de la lista (asi el boton del cloud se
  // renombra sin tocar el titulo "QFieldCloud" del login ni un proyecto que
  // se llame parecido); {contiene, buscar, reemplazar} sustituye solo la
  // sub-cadena. Strings exactos verificados contra i18n/qfield_es.ts de
  // QField v4.2.6. La whitelist por frase protege los titulos de proyectos
  // recientes (datos del modelo, ej. "Live QField Users Survey"): un titulo
  // no matchea ninguna regla.
  // Ojo: asignar .text rompe el binding nativo (el saludo queda fijo en
  // "Bienvenido" aunque QField quiera pasar a "Bienvenido de nuevo").
  // Cosmetico, trade-off aceptado.
  readonly property var reglasTexto: [
    { exactos: ["QFieldCloud\nproyectos", "QFieldCloud\nprojects"],
      texto: "Proyectos en\nla nube" },
    { contiene: "Bienvenido",      buscar: "QField", reemplazar: "SFN Iris" },
    { contiene: "Welcome",         buscar: "QField", reemplazar: "SFN Iris" },
    { contiene: "experiencia con", buscar: "QField", reemplazar: "SFN Iris" },
    { contiene: "experience with", buscar: "QField", reemplazar: "SFN Iris" }
  ]

  // --- Selector de elementos (hoja "Elementos" estilo SFN Iris) ---
  // Colores tomados del mock del Figma; no salen del Theme a proposito,
  // la hoja se ve igual en tema claro y oscuro (fondo blanco del mock).
  readonly property color hojaFondo: "#ffffff"
  readonly property color hojaTexto: "#373F52"
  readonly property color hojaCard: "#EDEFF3"
  readonly property color hojaChevron: "#6D717F"
  readonly property color hojaManija: "#C2C9D6"
  readonly property int radioHoja: 24
  readonly property int radioCard: 8

  // --- Formulario de detalle (mockup formulario editable) ---
  // Se pasa por property a DetalleElemento y sus campos, cero dependencia de
  // contexto. Colores del Figma SFN Iris.
  property QtObject estiloDetalle: QtObject {
    readonly property color hojaFondo: "#ffffff"
    readonly property color texto: "#373F52"
    readonly property color textoOscuro: "#1A2332"
    readonly property color textoSecundario: "#6D717F"
    readonly property color textoDeshabilitado: "#8B94A6"
    readonly property color card: "#F7F8FA"
    readonly property color cardBorde: "#E3E6EC"
    readonly property color cardGris: "#EDEFF3"
    readonly property color inputFondo: "#ffffff"
    readonly property color inputBorde: "#C2C9D6"
    readonly property color inputBordeActivo: "#1C45AB"
    readonly property color azul: "#1C45AB"
    readonly property color azulPalido: "#E8EEF9"
    readonly property color azulBoton: "#E3E9F8"
    readonly property color chipActivo: "#1C45AB"
    readonly property color colorError: "#EF4444"
    readonly property color colorWarning: "#F59E0B"
    readonly property color colorGuardar: "#10B981"
    readonly property color manija: "#C2C9D6"
    readonly property int radioHoja: 24
    readonly property int radioInput: 12
    readonly property int radioCard: 16
    // Igual que QField nativo: el lapiz de edicion aparece solo en modo
    // edicion (digitize). Poner false para editar siempre que la capa deje.
    readonly property bool exigirModoEdicionQField: true
  }

  // =====================================================================

  property var ventana: iface.mainWindow()

  function aplicarColores() {
    var colores = Theme.darkTheme ? paletaOscura : paletaClara
    if (typeof Theme.applyColors === "function") {
      // QField con Theme en C++ (2026 en adelante): pisa solo propiedades
      // escribibles e ignora claves desconocidas.
      Theme.applyColors(colores)
    } else {
      // Fallback para versiones anteriores con Theme en QML puro.
      for (var clave in colores) {
        try {
          if (Theme[clave] !== undefined)
            Theme[clave] = colores[clave]
        } catch (err) {
          // propiedad de solo lectura: seguir de largo
        }
      }
    }
  }

  // Recorre el arbol visual una sola vez haciendo dos sustituciones best
  // effort: (1) Image cuyo source sea el logo de QField (qrc:/images/
  // app_logo.svg, usado en WelcomeScreen y About) pasa al isotipo SFN Iris
  // segun tema; (2) Text de la Welcome que matchee reglasTexto (boton
  // QFieldCloud, saludo, encuesta) pasa al texto SFN. Depende de internals
  // no documentados de QField, si no encuentra nada no rompe.
  // Devuelve [logosCambiados, textosCambiados].
  function reemplazarLogosYTextos(raiz, profundidad) {
    if (!raiz || profundidad > profundidadMaxima)
      return [0, 0]
    var logos = 0
    var textos = 0
    if (raiz.source !== undefined) {
      var src = String(raiz.source)
      if (src.indexOf("app_logo") !== -1
          || src.indexOf("logo_sfn_claro") !== -1
          || src.indexOf("logo_sfn_oscuro") !== -1) {
        var destino = Qt.resolvedUrl(Theme.darkTheme ? "logo_sfn_oscuro.svg" : "logo_sfn_claro.svg")
        if (src !== String(destino)) {
          try {
            raiz.source = destino
            logos++
          } catch (err) {}
        } else {
          // ya swapeado (recarga del plugin): cuenta como exito para que
          // arranqueRapido frene al toque y el splash no espere el tope
          logos++
        }
      }
    }
    // La guarda de "QField" hace el swap idempotente: el texto ya reemplazado
    // ("Proyectos en la nube", "SFN Iris") no contiene "QField" y no se
    // vuelve a tocar en los reintentos. La guarda de readOnly esquiva los
    // campos editables (TextField/TextArea la tienen, Text/Label no): jamas
    // pisar texto que el usuario puede estar cargando como dato.
    if (typeof raiz.text === "string" && raiz.readOnly === undefined
        && raiz.text.indexOf("QField") !== -1) {
      for (var r = 0; r < reglasTexto.length; r++) {
        var regla = reglasTexto[r]
        var matchea = regla.exactos !== undefined
          ? regla.exactos.indexOf(raiz.text) !== -1
          : raiz.text.indexOf(regla.contiene) !== -1
        if (!matchea)
          continue
        try {
          if (regla.texto !== undefined)
            raiz.text = regla.texto
          else
            raiz.text = raiz.text.split(regla.buscar).join(regla.reemplazar)
          textos++
        } catch (err) {}
        break
      }
    }
    var hijos = raiz.children
    if (hijos) {
      for (var i = 0; i < hijos.length; i++) {
        var sub = reemplazarLogosYTextos(hijos[i], profundidad + 1)
        logos += sub[0]
        textos += sub[1]
      }
    }
    return [logos, textos]
  }

  // Devuelve la cantidad de logos swapeados en esta pasada (criterio de
  // exito del arranque rapido: el logo vive en la Welcome, igual que los
  // textos, asi que encontrarlo implica que la pantalla ya esta arriba).
  function aplicarMarca() {
    aplicarColores()
    if (ventana && ventana.contentItem)
      return reemplazarLogosYTextos(ventana.contentItem, 0)[0]
    return 0
  }

  // Cuando el usuario cambia claro/oscuro o la apariencia, QField recarga su
  // paleta default y pisa la nuestra: reaplicar. Qt.callLater corre despues
  // de que QField termino su applyAppearance.
  Connections {
    target: Theme
    function onDarkThemeChanged() {
      Qt.callLater(plugin.aplicarMarca)
    }
    function onAppearanceChanged() {
      Qt.callLater(plugin.aplicarColores)
    }
  }

  // Arranque rapido: reintento corto hasta pescar el logo de la Welcome (que
  // QField instancia en algun momento despues de cargar los plugins). Apenas
  // hay swap se muestra el toast y se pasa a los reintentos lentos, que
  // cubren pantallas tardias (Acerca de). Si en topeTicksArranque no
  // aparecio nada (internals cambiados), degrada igual a los reintentos
  // lentos sin dejar un timer vivo.
  Timer {
    id: arranqueRapido
    property int ticks: 0
    interval: plugin.intervaloArranqueMs
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      ticks++
      var logos = plugin.aplicarMarca()
      if (logos > 0 || ticks >= plugin.topeTicksArranque) {
        stop()
        // marcaLista libera el splash SFN; el toast se muestra recien cuando
        // el splash se va (si no, quedaria tapado)
        plugin.marcaLista = true
        plugin.conectarFormNativo()
        reintentos.start()
      }
    }
  }

  Timer {
    id: reintentos
    property int restantes: plugin.reintentosLogo
    interval: plugin.intervaloReintentoMs
    repeat: true
    onTriggered: {
      plugin.aplicarMarca()
      restantes--
      if (restantes <= 0)
        stop()
    }
  }

  // =====================================================================
  // SPLASH SFN
  //
  // Overlay a pantalla completa que aparece apenas QField instancia el
  // plugin (antes de que se vea la Welcome con el logo de QField) y se
  // desvanece cuando el branding ya esta aplicado. Los SVG (isotipo y
  // wordmark) son derivados del "Splash Screen v0.2" del Figma con el mismo
  // lienzo 440x956: mostrados a pantalla completa reproducen exactamente la
  // composicion del splash nativo del APK.
  // =====================================================================

  // marcaLista la prende el arranque rapido (swap del logo hecho o tope de
  // intentos agotado). El splash se va cuando ademas paso el minimo de
  // exhibicion; splashTope es el cinturon: pase lo que pase, se destapa.
  property bool marcaLista: false
  property bool splashMinimoCumplido: false
  property bool splashActivo: true
  readonly property bool splashPuedeIrse: marcaLista && splashMinimoCumplido

  onSplashPuedeIrseChanged: {
    if (splashPuedeIrse) {
      splashLimpieza.start()
      // sin toast: el splash ya es la confirmacion visual de que el branding
      // cargo. Queda el log para debug con PluginReloader.
      console.log("[SFN Iris] branding aplicado")
    }
  }

  Timer {
    id: splashMinimo
    interval: plugin.splashMinimoMs
    running: true
    onTriggered: plugin.splashMinimoCumplido = true
  }

  Timer {
    id: splashTope
    interval: plugin.splashTopeMs
    running: true
    onTriggered: {
      plugin.marcaLista = true
      plugin.splashMinimoCumplido = true
    }
  }

  // Cuando el fade-out termino, el Loader se desactiva y libera los
  // rasterizados de los SVG (varios MB) y el MouseArea que come los taps.
  Timer {
    id: splashLimpieza
    interval: plugin.splashFadeMs + 250
    onTriggered: plugin.splashActivo = false
  }

  Loader {
    id: splashLoader
    parent: plugin.ventana ? plugin.ventana.contentItem : null
    anchors.fill: parent ? parent : undefined
    active: plugin.splashActivo
    z: 10000

    sourceComponent: Rectangle {
      color: plugin.splashFondo
      opacity: plugin.splashPuedeIrse ? 0 : 1
      // opacity 0 no desactiva el hit-testing en Qt Quick: sin esto el
      // MouseArea seguiria comiendo taps ya invisible hasta que el Loader
      // se desactive
      visible: opacity > 0

      // El splash tambien es modal para el teclado: sin esto el back de
      // Android atraviesa el overlay y opera QField tapado (cierra la
      // Welcome o dispara el "volver a presionar para salir" con el toast
      // invisible debajo). forceActiveFocus y no focus: true, porque Loader
      // es FocusScope. La Welcome puede robar el foco al aparecer:
      // re-agarrarlo mientras el splash tapa. Best effort: si el foco no se
      // consigue, degrada al comportamiento de siempre.
      Component.onCompleted: forceActiveFocus()
      onActiveFocusChanged: {
        if (!activeFocus && !plugin.splashPuedeIrse)
          forceActiveFocus()
      }
      Keys.onPressed: function (event) {
        if (!plugin.splashPuedeIrse)
          event.accepted = true
      }
      Keys.onReleased: function (event) {
        if (!plugin.splashPuedeIrse)
          event.accepted = true
      }

      Behavior on opacity {
        NumberAnimation {
          duration: plugin.splashFadeMs
          easing.type: Easing.InQuad
        }
      }

      // Isotipo ANIMADO (SplashIris): iris que se abre, se teje la red y late.
      // Va en un Loader con fallback: si el componente fallara (algun quirk de
      // la version de QField con Shapes/animaciones), degrada a la imagen
      // estatica en vez de romper el splash. Best effort, como el resto.
      Loader {
        id: isotipoLoader
        anchors.fill: parent
        source: Qt.resolvedUrl("SplashIris.qml")
        onStatusChanged: {
          if (status === Loader.Error) {
            console.log("[SFN Iris] SplashIris no cargo, uso isotipo estatico")
            isotipoFallback.visible = true
          }
        }
      }

      Image {
        id: isotipoFallback
        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
        source: Qt.resolvedUrl("splash_isotipo.svg")
        sourceSize.width: 1104
        sourceSize.height: 2400
        visible: false
      }

      // Wordmark "SFN IRIS": fade-in retardado respecto del isotipo.
      Image {
        id: splashWordmark
        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
        source: Qt.resolvedUrl("splash_wordmark.svg")
        sourceSize.width: 1104
        sourceSize.height: 2400
        opacity: 0

        SequentialAnimation {
          running: true
          PauseAnimation { duration: 550 }
          NumberAnimation {
            target: splashWordmark
            property: "opacity"
            from: 0
            to: 1
            duration: 550
            easing.type: Easing.OutCubic
          }
        }
      }

      // Es un splash: que nadie toque controles invisibles por debajo.
      MouseArea {
        anchors.fill: parent
      }
    }
  }

  // =====================================================================
  // SELECTOR DE ELEMENTOS
  //
  // Boton en la toolbar de plugins que activa el "modo seleccion SFN":
  // el identify de QField sigue funcionando igual (mismo tap, mismo radio,
  // mismo modelo de datos, paneo libre), pero cuando QField va a abrir su
  // lista nativa de objetos, la escondemos y mostramos la hoja "Elementos"
  // con el diseño SFN Iris, leyendo el mismo modelo. Al tocar una card se
  // abre el formulario nativo de QField: la entrada de datos no cambia.
  //
  // Depende de internals no documentados del FeatureListForm de QField
  // (objectName "featureForm", states "FeatureList"/"FeatureForm"/"Hidden",
  // selection.focusedItem). Si una version futura los cambia, desactivar
  // el modo deja todo nativo.
  // =====================================================================

  property bool modoSeleccionActivo: false
  property var formNativo: null

  // La hoja se muestra exactamente cuando el panel nativo esta logicamente
  // en su estado de lista. Una sola fuente de verdad (el state nativo), sin
  // handlers imperativos: al pasar a FeatureForm o Hidden la hoja se oculta
  // sola y el panel nativo se destapa solo.
  readonly property bool hojaActiva: modoSeleccionActivo
      && formNativo !== null
      && formNativo.state === "FeatureList"
      && !formNativo.multiSelection

  // --- hoja de detalle (v0.3.0) ---
  // El state nativo queda en "FeatureList" durante todo el detalle: la hoja
  // de lista se oculta con indiceDetalle y el Binding que tapa el panel
  // nativo sigue activo porque hojaActiva no cambia.
  property int indiceDetalle: -1
  readonly property bool detalleActivo: hojaActiva && indiceDetalle >= 0
  readonly property bool detalleDisponible: loaderDetalle.status === Loader.Ready

  function abrirDetalle(indice) {
    if (!formNativo || !loaderDetalle.item)
      return
    // CONFIRMAR-EN-BUILD: asignar focusedItem con state "FeatureList" no
    // dispara transiciones nativas (solo el highlight del feature en el mapa)
    formNativo.selection.focusedItem = indice
    indiceDetalle = indice
    loaderDetalle.item.indice = indice
    loaderDetalle.item.cantidad = formNativo.model && formNativo.model.count !== undefined
      ? formNativo.model.count : 0
    loaderDetalle.item.cargar()
  }

  function navegarDetalle(delta) {
    var destino = indiceDetalle + delta
    var total = (formNativo && formNativo.model && formNativo.model.count !== undefined)
      ? formNativo.model.count : 0
    if (destino >= 0 && destino < total)
      abrirDetalle(destino)
  }

  function cerrarTodo() {
    indiceDetalle = -1
    cerrarHoja()
  }

  // Si la lista nativa se cierra por afuera (multiseleccion, cambio de estado,
  // cierre de proyecto), soltar el detalle. El buffer de edicion del detalle
  // no toca la capa hasta save(), asi que descartar en silencio no corrompe.
  onHojaActivaChanged: {
    if (!hojaActiva && indiceDetalle >= 0)
      indiceDetalle = -1
  }

  function conectarFormNativo() {
    if (!formNativo) {
      formNativo = iface.findItemByObjectName("featureForm")
    }
    return formNativo !== null
  }

  function alternarModoSeleccion() {
    if (!conectarFormNativo()) {
      iface.mainWindow().displayToast(qsTr("No encontre el panel de objetos de QField"))
      return
    }
    // no apagar el modo por un tap accidental con una edicion a medias:
    // rutear por el mismo dialogo de cancelacion del detalle
    if (modoSeleccionActivo && detalleActivo && loaderDetalle.item
        && loaderDetalle.item.enEdicion && loaderDetalle.item.hayCambios) {
      loaderDetalle.item.manejarCierre()
      return
    }
    modoSeleccionActivo = !modoSeleccionActivo
    if (!modoSeleccionActivo && formNativo.state === "FeatureList") {
      // cerrar limpio, como el boton de volver nativo (limpia modelo y seleccion)
      formNativo.state = "Hidden"
    }
    iface.mainWindow().displayToast(modoSeleccionActivo
      ? qsTr("Seleccion SFN activada: toca un elemento en el mapa")
      : qsTr("Seleccion SFN desactivada"))
  }

  function abrirFormularioNativo(indice) {
    if (!formNativo)
      return
    formNativo.selection.focusedItem = indice
    formNativo.state = "FeatureForm"
  }

  function cerrarHoja() {
    if (formNativo && formNativo.state === "FeatureList") {
      formNativo.state = "Hidden"
    }
  }

  // Tapa el panel nativo mientras la hoja SFN esta visible. Se pisa solo
  // "visible" y NO se manda el state a "Hidden" para esconderlo: el hide()
  // nativo hace model.clear() y la hoja se quedaria sin datos.
  Binding {
    target: plugin.formNativo
    property: "visible"
    value: false
    when: plugin.hojaActiva
    restoreMode: Binding.RestoreBindingOrValue
  }

  // QField dibuja la sombra del panel nativo con un efecto aparte que renderiza
  // una COPIA del panel (y los efectos renderizan el source aunque este
  // invisible): con opacity 0 esa copia sale transparente y no se asoma nada.
  Binding {
    target: plugin.formNativo
    property: "opacity"
    value: 0
    when: plugin.hojaActiva
    restoreMode: Binding.RestoreBindingOrValue
  }

  QfToolButton {
    id: botonSeleccion
    iconSource: Qt.resolvedUrl("icono_seleccion.svg")
    iconColor: "white"
    bgcolor: plugin.modoSeleccionActivo ? Theme.mainColor : Theme.darkGraySemiOpaque
    round: true
    onClicked: plugin.alternarModoSeleccion()
  }

  // Hoja "Elementos": handle, titulo, boton cerrar y cards por capa.
  Rectangle {
    id: hojaElementos
    parent: plugin.ventana ? plugin.ventana.contentItem : null
    visible: plugin.hojaActiva && plugin.indiceDetalle < 0
    z: 99

    anchors.left: parent ? parent.left : undefined
    anchors.right: parent ? parent.right : undefined
    anchors.bottom: parent ? parent.bottom : undefined
    // esconde las esquinas redondeadas de abajo fuera de la pantalla
    anchors.bottomMargin: -plugin.radioHoja

    radius: plugin.radioHoja
    color: plugin.hojaFondo
    height: cabeceraHoja.height + listaElementos.height + plugin.radioHoja + 56

    Rectangle {
      width: 158
      height: 6
      radius: 3
      color: plugin.hojaManija
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: parent.top
      anchors.topMargin: 12
    }

    Item {
      id: cabeceraHoja
      anchors.top: parent.top
      anchors.topMargin: 32
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.leftMargin: 20
      anchors.rightMargin: 20
      height: 48

      Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: qsTr("Elementos")
        font.bold: true
        font.pointSize: Theme.titleFont.pointSize
        color: plugin.hojaTexto
      }

      Rectangle {
        width: 44
        height: 44
        radius: 12
        color: plugin.hojaCard
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        // Image en vez de Text: los caracteres tipo "✕" no existen en la
        // fuente de Android y se ven como glifo roto (tofu).
        Image {
          anchors.centerIn: parent
          width: 14
          height: 14
          sourceSize.width: 56
          sourceSize.height: 56
          fillMode: Image.PreserveAspectFit
          source: Qt.resolvedUrl("icono_cerrar.svg")
        }

        MouseArea {
          anchors.fill: parent
          onClicked: plugin.cerrarHoja()
        }
      }
    }

    ListView {
      id: listaElementos
      anchors.top: cabeceraHoja.bottom
      anchors.topMargin: 8
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.leftMargin: 20
      anchors.rightMargin: 20
      height: plugin.ventana ? Math.min(contentHeight, plugin.ventana.height * 0.45) : 0
      clip: true
      spacing: 8

      model: plugin.formNativo ? plugin.formNativo.model : null

      // agrupa por capa, igual que la lista nativa
      section.property: "layerName"
      section.delegate: Component {
        Text {
          width: listaElementos.width
          topPadding: 14
          bottomPadding: 6
          text: section
          font.bold: true
          font.pointSize: Theme.strongFont.pointSize
          color: plugin.hojaTexto
        }
      }

      delegate: Rectangle {
        width: listaElementos.width
        height: 52
        radius: plugin.radioCard
        color: plugin.hojaCard

        Text {
          anchors.left: parent.left
          anchors.leftMargin: 16
          anchors.right: chevron.left
          anchors.rightMargin: 10
          anchors.verticalCenter: parent.verticalCenter
          text: display
          elide: Text.ElideRight
          font.bold: true
          font.pointSize: Theme.strongFont.pointSize
          color: plugin.hojaTexto
        }

        Image {
          id: chevron
          anchors.right: parent.right
          anchors.rightMargin: 16
          anchors.verticalCenter: parent.verticalCenter
          width: 9
          height: 15
          sourceSize.width: 36
          sourceSize.height: 60
          fillMode: Image.PreserveAspectFit
          source: Qt.resolvedUrl("icono_chevron.svg")
        }

        MouseArea {
          anchors.fill: parent
          // si DetalleElemento no cargo (tipos org.qfield ausentes), degradar
          // al formulario nativo como en v0.2.x
          onClicked: plugin.detalleDisponible
            ? plugin.abrirDetalle(index)
            : plugin.abrirFormularioNativo(index)
        }
      }
    }
  }

  // Hoja de detalle: cargada con Loader para degradar al form nativo si los
  // tipos org.qfield que necesita (FeatureModel, AttributeFormModel, SubModel)
  // no existieran en la version de QField instalada.
  Loader {
    id: loaderDetalle
    parent: plugin.ventana ? plugin.ventana.contentItem : null
    active: plugin.modoSeleccionActivo
    visible: plugin.detalleActivo
    z: 99
    anchors.left: parent ? parent.left : undefined
    anchors.right: parent ? parent.right : undefined
    anchors.bottom: parent ? parent.bottom : undefined
    anchors.bottomMargin: -plugin.radioHoja
    source: Qt.resolvedUrl("DetalleElemento.qml")
    onLoaded: {
      item.estilo = plugin.estiloDetalle
      item.ventana = plugin.ventana
      item.formNativo = Qt.binding(function () {
        return plugin.formNativo
      })
      item.pedirCerrarTodo.connect(plugin.cerrarTodo)
      item.pedirNavegar.connect(plugin.navegarDetalle)
    }
    onStatusChanged: {
      if (status === Loader.Error)
        console.log("[SFN Iris] DetalleElemento no disponible, se usa el formulario nativo")
    }
  }

  // Mientras el detalle esta abierto, el resto de la pantalla es modal: un tap
  // afuera pasa por el mismo camino que la ✕ y evita que un nuevo identify
  // repueble el modelo por debajo del detalle. Distingue taps de gestos: un
  // swipe hacia arriba (dedo que apunto al handle pero apoyo sobre el mapa)
  // expande la hoja en vez de cerrarla; otros gestos no hacen nada.
  MouseArea {
    parent: plugin.ventana ? plugin.ventana.contentItem : null
    anchors.fill: parent
    visible: plugin.detalleActivo
    z: 98
    property real xPress: 0
    property real yPress: 0
    onPressed: function (mouse) {
      xPress = mouse.x
      yPress = mouse.y
    }
    onReleased: function (mouse) {
      if (!loaderDetalle.item)
        return
      var dx = mouse.x - xPress
      var dy = mouse.y - yPress
      if (dy < -40 && Math.abs(dx) < 120) {
        loaderDetalle.item.expandida = true
        return
      }
      if (Math.abs(dx) > 20 || Math.abs(dy) > 20)
        return   // fue un gesto, no un tap: no cerrar
      loaderDetalle.item.manejarCierre()
    }
  }

  // Cinturon: si el modelo nativo se resetea con el detalle abierto (identify
  // externo, cierre de proyecto), cerrar el detalle avisando.
  Connections {
    target: plugin.formNativo ? plugin.formNativo.model : null
    enabled: plugin.detalleActivo
    function onModelReset() {
      plugin.indiceDetalle = -1
      iface.mainWindow().displayToast(qsTr("La seleccion cambio: se cerro el detalle"))
    }
  }

  // Los colores se pueden pisar bien temprano, sin esperar la UI.
  Component.onCompleted: {
    aplicarColores()
    iface.addItemToPluginsToolbar(botonSeleccion)
    conectarFormNativo()
  }
}
