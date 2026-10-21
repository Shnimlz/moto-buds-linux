# Moto Buds Linux

Cliente y aplicacion de escritorio en Qt6/QML para auriculares Motorola Moto Buds en distribuciones Linux. Desarrollado mediante ingenieria inversa del protocolo de comunicacion Bluetooth de la aplicacion oficial de Android (`com.motorola.motobuds`).

## Descripcion General

Los auriculares Motorola Moto Buds utilizan una conexion Bluetooth Classic paralela al flujo de audio estandar (A2DP / PipeWire / PulseAudio) para transmitir telemetria, telemetria de carga y comandos de control.

Este proyecto implementa dicho protocolo de manera nativa sobre Linux, ofreciendo:
1. Una herramienta de linea de comandos (`moto-buds`) escrita en Rust con soporte para salidas en texto legible y en JSON.
2. Una aplicacion grafica de escritorio (`moto-buds-gui`) construida en C++20 y Qt6 Quick/QML, con tipografia de iconos Google Material Symbols y recursos graficos transparentes extraidos del firmware.

## Dispositivos Compatibles

- Probado y verificado en: **Motorola Moto Buds** (`moto buds bass`, modelo de hardware XT2441-1).
- Dispositivos con arquitectura compatible: Moto Buds+, Moto Buds Pro y modelos con identificador de protocolo 1.8 en adelante que implementen el servicio RFCOMM `SPP_MOBILE`.

## Funcionalidades Implementadas

- **Monitoreo de Bateria**: Lectura del nivel porcentual del auricular izquierdo, auricular derecho y estuche de carga, con deteccion de estado de carga en tiempo real.
- **Cancelacion Activa de Ruido (ANC)**:
  - Modos: Desactivado, Cancelacion Activa, Adaptativo y Transparencia.
  - Nota de hardware: Los auriculares validan los sensores opticos de proximidad antes de aplicar el modo ANC. Si no se encuentran colocados en los oidos, el firmware rechaza el comando con codigo de error 2.
- **Modo Juego**: Activacion y desactivacion de baja latencia para sincronizacion de audio en juegos y reproduccion de video.
- **Audio Espacial**: Modos desactivado, orientacion fija y seguimiento de cabeza.
- **Ecualizador**: Seleccion de perfiles de fabrica (Original, Predeterminado, Realce de Graves, Voces Claras).
- **Ajustes Inteligentes**:
  - Deteccion en oreja (pausa y reanudacion automatica).
  - Conexion Dual (Bluetooth Multipoint para dos dispositivos simultaneos).
- **Localizador de Auriculares**: Emision de senales acusticas independientes para auricular izquierdo, derecho o ambos.
- **Monitor en Tiempo Real**: Escucha continua de eventos de bateria y cambios de estado enviados por los auriculares.

## Arquitectura y Protocolo

La comunicacion se realiza mediante sockets directos de capa de enlace POSIX Bluetooth (`AF_BLUETOOTH`, `BTPROTO_RFCOMM`) dirigidos al canal 16:
- UUID del servicio: `fc9d9fe0-4899-11ee-be56-0242ac120002` (Servicio SDP: `SPP_MOBILE`).
- No requiere privilegios de superusuario (`root`).
- No interrumpe la reproduccion de audio activa en PipeWire o WirePlumber.

### Estructura del Paquete de Red

| Campo | Tamano | Descripcion |
|---|---|---|
| Magic Header | 4 bytes | Constante ASCII `HEAD` (`0x48 0x45 0x41 0x44`) |
| Body Length | 2 bytes | Longitud del encabezado PDU + Carga util (Little-Endian) |
| Opcode | 2 bytes | Identificador de comando (Big-Endian) |
| Type | 1 byte | `0x80` para comandos cliente, `0x20` para respuestas |
| Result | 1 byte | `0x00` para exito, codigos `>0` para error del dispositivo |
| Payload Length | 2 bytes | Longitud de la carga util (Little-Endian) |
| Sequence | 2 bytes | Contador incremental de secuencia (Little-Endian) |
| Payload | N bytes | Datos de comando o telemetria |
| Checksum CRC32 | 4 bytes | CRC32 calculado sobre `HEAD` + Body Length + PDU + Payload |
| Magic Tail | 4 bytes | Constante ASCII `TAIL` (`0x54 0x41 0x49 0x4C`) |

### Tabla de Opcodes Principales

| Opcode | Funcion | Carga Util Comando | Carga Util Respuesta |
|---|---|---|---|
| 0 | Version de perfil | Vacia | `[Major, Minor]` (ej. `[1, 8]`) |
| 5 | Estado de baterias | Vacia | `[Left, Right, Case]` (Bit 7: Cargando, Bits 0-6: Porcentaje) |
| 512 / 513 | Obtener / Fijar ANC | `[Modo, Submodo]` | `[Modo, Submodo]` |
| 514 / 515 | Obtener / Fijar EQ | `[Indice]` | `[Indice]` |
| 770 / 771 | Deteccion en oreja | `[0x01]` o `[0x00]` | `[0x01]` o `[0x00]` |
| 772 / 773 | Conexion dual | `[0x01]` o `[0x00]` | `[0x01]` o `[0x00]` |
| 774 / 775 | Localizador acustico | `[Target]` | Estado |
| 778 / 779 | Audio Espacial | `[Modo, Tracking]` | `[Modo, Tracking]` |
| 782 / 783 | Modo Juego | `[0x01]` o `[0x00]` | `[0x01]` o `[0x00]` |

## Instalacion

### Opcion A: AppImage (Sin necesidad de comandos ni compilacion)

Descarga el paquete autonomo desde la seccion de [Releases de GitHub](https://github.com/Shnimlz/moto-buds-linux/releases):
1. Descarga el archivo `Moto_Buds-x86_64.AppImage`.
2. Otorga permisos de ejecucion y abre la aplicacion:
   ```bash
   chmod +x Moto_Buds-x86_64.AppImage
   ./Moto_Buds-x86_64.AppImage
   ```

### Opcion B: Arch Linux / AUR

Se incluyen plantillas de empaquetado bajo `packaging/arch/`:

- **`moto-buds-bin`**: Binarios oficiales precompilados de 64 bits.
- **`moto-buds-appimage`**: Envoltorio AppImage integrado al sistema.
- **`moto-buds-git`**: Compilacion continua desde el codigo fuente.

```bash
# Instalacion mediante un asistente de AUR (ej. yay o paru):
yay -S moto-buds-bin
```

### Opcion C: Compilacion Manual desde el Codigo Fuente

#### Requisitos
- Linux x86_64 o AArch64 con kernel 5.15 o superior.
- Pila Bluetooth BlueZ activa (`bluetoothd`).
- Compilador de C++ con soporte C++20 (GCC 11+ o Clang 13+).
- CMake 3.16 o superior y generador Ninja.
- Qt 6 (modulos: `qt6-base`, `qt6-declarative`, `qt6-quickcontrols2`).
- Cadena de herramientas de Rust (Cargo) para compilar el motor CLI.
- Fuente Google Material Symbols (incluida en el repositorio bajo `assets/`).

#### 1. Compilar e Instalar el Motor CLI (Rust)

```bash
cargo build --release
install -Dm755 target/release/moto-buds ~/.local/bin/moto-buds
```

#### 2. Compilar e Instalar la Aplicacion Grafica (Qt6 / QML)

```bash
cmake -B build -S . -DCMAKE_INSTALL_PREFIX=~/.local -G Ninja
ninja -C build
ninja -C build install
```

Para actualizar la base de datos de lanzadores de escritorio:
```bash
update-desktop-database ~/.local/share/applications
```

## Uso

### Aplicacion Grafica

Ejecutar desde el menu de aplicaciones del sistema o mediante la terminal:
```bash
moto-buds-gui
```

### Herramienta de Linea de Comandos

```bash
# Consultar estado general y niveles de bateria
moto-buds status

# Salida estructurada en JSON (para scripts, Waybar o Polybar)
moto-buds --json status

# Cambiar el modo de cancelacion de ruido (off, noise-cancelling, adaptive, transparency)
moto-buds anc noise-cancelling

# Activar o desactivar el Modo Juego de baja latencia
moto-buds game-mode on
moto-buds game-mode off

# Configurar Audio Espacial (off, fixed, head-tracking)
moto-buds spatial fixed

# Activar o desactivar deteccion en oreja
moto-buds in-ear on

# Activar o desactivar conexion multipunto dual
moto-buds dual-conn on

# Seleccionar perfil de ecualizador (0 a 3)
moto-buds eq --set 2

# Localizar auriculares por sonido (left, right, both, stop)
moto-buds find both
moto-buds find stop

# Escuchar telemetria y eventos en tiempo real
moto-buds monitor
```

## Licencia

Este proyecto se distribuye bajo la licencia MIT. Los recursos graficos de producto pertenecen a sus respectivos titulares y se incluyen unicamente con fines de interoperabilidad.
