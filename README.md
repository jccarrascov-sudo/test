# MisNotas ✏️📓

App de apuntes a mano para iPad, estilo GoodNotes, hecha en **Swift + SwiftUI + PencilKit** con el diseño **Liquid Glass** de iOS 26. Es gratis y funciona sin internet.

> **Requisitos:** iPad con **iPadOS 26** o más nuevo y la versión más reciente de Swift Playgrounds (o Xcode 26 en Mac). Liquid Glass solo existe desde iOS 26.

## Diseño Liquid Glass

- Barras de herramientas de vidrio que **flotan sobre la hoja**; al hacer scroll, la página pasa por debajo y se ve a través del vidrio.
- Botones agrupados en **cápsulas de vidrio** (páginas · navegación · deshacer/rehacer · lápiz/nueva hoja · más opciones).
- **Fondo con degradado en movimiento** (MeshGradient) que toma los colores de tus cuadernos.
- Tapas de cuaderno con brillo y el título sobre una **etiqueta de vidrio**.
- Botón flotante **“Nuevo cuaderno”** en vidrio, vista previa de la tapa al crear y miniaturas de páginas con número en vidrio.
- **Todo es vidrio**: la pantalla de nuevo cuaderno (campo de texto en cápsula, colores con aro de vidrio que se desliza, mini-hojas en baldosas de vidrio), el buscador, la pantalla vacía y las alertas.
- La paleta del Apple Pencil y las hojas emergentes usan el vidrio del sistema.

## Qué hace

- 📚 **Biblioteca de cuadernos**: los creas con nombre y color de tapa, les cambias el nombre y los eliminas (mantén presionado un cuaderno).
- ✏️ **Escritura con Apple Pencil** con presión e inclinación, usando la paleta de Apple: lapicero, lápiz, plumón, resaltador, borrador, lazo para seleccionar y mover, regla y todos los colores.
- 🖐️ **Modo "Solo Apple Pencil"**: con el dedo te mueves por la hoja y con el lápiz escribes. También puedes escribir con el dedo si no tienes lápiz.
- 📄 **Hojas en blanco, con líneas, cuadriculadas o punteadas**, a elección por página.
- 🔍 **Zoom** con dos dedos (hasta 4x) y las líneas se ven nítidas.
- 🗂️ **Páginas**: agregar, duplicar, eliminar y ver todas en miniatura.
- ↩️ **Deshacer / rehacer**.
- 📤 **Exportar a PDF** (A4) para guardarlo en Archivos o mandarlo por WhatsApp, correo o AirDrop.
- 💾 **Guardado automático** en el iPad.

## Cómo instalarla en tu iPad (gratis, sin Mac)

1. Descarga **Swift Playgrounds** de la App Store (es gratis y es de Apple).
2. En el iPad, abre este repositorio en Safari → botón verde **Code** → **Download ZIP**.
3. Abre la app **Archivos** → **Descargas** y toca el ZIP para descomprimirlo.
4. Toca la carpeta **`MisNotas.swiftpm`** y se abre en Swift Playgrounds (si no se abre, en Playgrounds usa **Ver todo → Abrir desde Archivos**, o muévela a la carpeta *Playgrounds* de iCloud Drive).
5. Presiona ▶️ **Ejecutar** y listo, ya tienes tu app corriendo. Tus cuadernos se quedan guardados.

> Con Swift Playgrounds la app se abre desde Playgrounds, no tiene su propio ícono suelto en la pantalla de inicio. Así es la única forma 100% gratis y que **no caduca**.

## Con Mac + Xcode (ícono propio en la pantalla de inicio)

1. Abre `MisNotas.swiftpm` con Xcode 26 o más nuevo.
2. En *Signing & Capabilities* elige tu Apple ID personal (gratis).
3. Conecta el iPad, elígelo como destino y dale ▶️.

Con un Apple ID gratis la app **caduca a los 7 días** y hay que volver a instalarla desde Xcode. Para que dure siempre o subirla a la App Store necesitas el Apple Developer Program (99 USD al año).

## Archivos del proyecto

| Archivo | Para qué sirve |
|---|---|
| `MisNotasApp.swift` | Punto de entrada de la app |
| `Models.swift` | Cuadernos, páginas y tipos de hoja |
| `NotebookStore.swift` | Guarda y carga los cuadernos (JSON en Documentos) |
| `LibraryView.swift` | Pantalla de cuadernos y creación de cuaderno nuevo |
| `NotebookView.swift` | Pantalla de escritura, barra de herramientas y miniaturas |
| `LiquidGlass.swift` | Estilos de vidrio de toda la app: tarjetas, secciones, campo de texto, selectores con efecto “derretido” |
| `GlassBackdrop.swift` | Fondo de degradado animado detrás del vidrio |
| `PageCanvas.swift` | Lienzo de PencilKit con fondo de hoja y zoom |
| `PDFExporter.swift` | Exportar a PDF y hoja de compartir |
