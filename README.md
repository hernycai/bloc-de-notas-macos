# Bloc de notas de Windows para macOS (Native macOS App)

Una copia fiel, rápida y 100% nativa del clásico **Bloc de notas de Windows (Windows Notepad)** para macOS, desarrollada en Swift y AppKit (sin Electron ni navegadores embebidos, con inicio instantáneo y mínimo consumo de memoria).

Ya se encuentra compilada e instalada en tu carpeta de `/Applications` como una aplicación nativa `.app`.

---

## 🚀 Cómo abrir la aplicación

Puedes abrirla de cualquiera de las siguientes maneras:

1. **Desde Spotlight**:
   - Pulsa `Cmd + Espacio`, escribe `Bloc de notas` y pulsa `Enter`.
2. **Desde la carpeta Aplicaciones**:
   - Abre Finder, haz clic en **Aplicaciones** en la barra lateral y haz doble clic sobre **Bloc de notas**.
3. **Desde la terminal**:
   ```bash
   open -a "Bloc de notas"
   # o abriendo directamente un archivo de texto:
   open -a "Bloc de notas" mi_archivo.txt
   ```
4. **Haciendo clic derecho en cualquier archivo `.txt`**:
   - *Abrir con...* > **Bloc de notas**.

---

## 🎨 Características y Detalles de Réplica

- **Barra de menús integrada con seguimiento continuo del cursor**:
  - Cuenta con la clásica barra `Archivo`, `Edición`, `Formato`, `Ver`, `Ayuda` dentro de la ventana.
  - Al abrir un menú (por ejemplo *Archivo*), basta con deslizar el cursor sobre *Edición*, *Formato*, etc., y el menú correspondiente se despliega de forma inmediata y automática, sin necesidad de hacer clic fuera.
- **Guardado en formatos `.txt` y `.md` (Markdown)**:
  - En *Guardar como...* (`Cmd + Shift + S`) se incluye un selector de tipo:
    - *Documento de texto (*.txt)*
    - *Archivo Markdown (*.md)*
  - Adapta automáticamente la extensión del archivo y su asociación en el sistema.
- **Barra de herramientas de formato de texto**:
  - Ubicada justo debajo del menú (ocultable desde `Ver > Barra de formato`).
  - **Familia tipográfica**: Selector de fuentes (Consolas, Menlo, Courier New, SF Pro, Helvetica, etc.).
  - **Tamaño de letra**: Selector de tamaño dinámico (9, 10, 11, 12, 14, 16, 18, 20, 24, 28, 32, 36, 48).
  - **Estilos de texto**:
    - **Negrita (B)** (`Cmd + B`)
    - *Cursiva (I)* (`Cmd + I`)
    - ~~Tachada (S̶)~~
    - <u>Subrayada (U̲)</u> (`Cmd + U`)
  - **Modo sintaxis Markdown (`**`)**: Permite alternar entre formateo visual directo o inserción/envoltura automática de etiquetas Markdown (`**negrita**`, `*cursiva*`, `~~tachada~~`).
- **⚙️ Panel de Configuración completo (`Cmd + ,` o icono ⚙️)**:
  - **Tema por omisión**: Claro, Oscuro o Automático según el sistema.
  - **Tipografía por omisión**: Selector de fuente por defecto y tamaño predeterminado.
  - **Comportamiento del editor**: Ajuste de línea por defecto, salto de línea (CRLF / LF), codificación inicial (UTF-8 / ANSI) y visibilidad de barras.
  - **Buscar actualizaciones**: Botón integrado para comprobar nuevas versiones directamente contra los releases de GitHub y descargar el nuevo instalador `.dmg`.
- **Alternar entre Modo Claro y Oscuro**:
  - **Botón rápido en la barra de formato**: Haz clic en `🌙 Oscuro` o `☀️ Claro` en el extremo derecho de la barra de formato.
  - **Icono en la barra de menús**: Botón `🌙` / `☀️` en la esquina superior derecha.
  - **Menú Ver**: `Ver > Tema` para seleccionar *Modo Claro*, *Modo Oscuro* o *Automático (Sistema)*.
  - **Atajo de teclado global**: `Cmd + Shift + D` para alternar instantáneamente.
  - **Persistencia**: La aplicación recuerda tu preferencia (claro u oscuro) para que se mantenga cada vez que la abras.
- **Barra de estado completa (Status Bar)**:
  - Posición del cursor en tiempo real (`Lín X, Col Y`).
  - Nivel de zoom (`100%`).
  - Finales de línea detectados (`Windows (CRLF)` o `Unix (LF)`).
  - Codificación del archivo (`UTF-8`, `ANSI / Windows-1252`, etc.).
- **Atajos clásicos**:
  - `F5`: Inserta la fecha y hora actual en la posición del cursor (formato `HH:mm dd/MM/yyyy`).
  - `Cmd + F`: Barra de búsqueda integrada con opción de mayúsculas/minúsculas y ajuste de línea.
  - `Cmd + H`: Búsqueda y reemplazo integrado ("Reemplazar" y "Reemplazar todo").
  - `Cmd + L`: Diálogo modal clásico "Ir a la línea...".
  - `Cmd + +` / `Cmd + -` / `Cmd + 0`: Control de zoom dinámico.
  - `Cmd + Shift + N`: Abrir una nueva ventana independiente del Bloc de notas.
  - `Cmd + N` / `Cmd + O` / `Cmd + S` / `Cmd + Shift + S`: Nuevo, Abrir, Guardar y Guardar como.
- **Formato y Fuentes**:
  - Ajuste de línea (*Word Wrap*) activable/desactivable en tiempo real (con barra de desplazamiento horizontal cuando está desactivado).
  - Selector de fuentes compatible con *Consolas*, *Menlo*, *Courier New* y cualquier tipografía del sistema.
- **Temas**:
  - Menú `Ver > Tema` para alternar entre el clásico Windows Claro, Windows 11 Oscuro o automático según el sistema macOS.
- **Gestión de cambios**:
  - Indicador `*` en el título cuando hay cambios pendientes (`*Sin título - Bloc de notas`).
  - Confirmación al salir o cerrar: *"¿Desea guardar los cambios en ...?"* con botones *Guardar*, *No guardar* y *Cancelar*.
- **Diálogo "Acerca del Bloc de notas"**:
  - Accesible desde `Ayuda > Acerca del Bloc de notas` con el formato y estilo clásico de Windows.
- **Icono original en alta definición**:
  - Icono de bloc de notas con espiral y lápiz diseñado a medida y compilado en formato Retina `.icns`.

---

## 💿 Instalador DMG para compartir o instalar en otros Mac

El proyecto incluye el instalador listo para usar:
* **Archivo:** [`Bloc de notas.dmg`](file:///Users/hernanluciano/Documents/bloc_de_notas/Bloc%20de%20notas.dmg)
* **Uso:** Haz doble clic sobre `Bloc de notas.dmg` y arrastra el icono de **Bloc de notas** a la carpeta **Applications**.

Para regenerar el instalador DMG en cualquier momento:
```bash
./create_dmg.sh
```

---

## 🛠️ Recompilación manual (si realizas modificaciones)

Para recompilar, reinstalar y generar el DMG en un solo paso, ejecuta:

```bash
./build.sh
```

El script compila el código Swift nativo, empaqueta la aplicación con sus recursos, la firma, la instala en `/Applications/Bloc de notas.app` y genera `Bloc de notas.dmg`.
