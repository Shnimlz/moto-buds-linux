# Paquetes para Arch Linux / AUR

Esta carpeta contiene los ficheros `PKGBUILD` y `.SRCINFO` preparados para Arch Linux, CachyOS y el AUR (Arch User Repository).

## Opciones Disponibles

1. **`moto-buds-bin`**: Descarga los binarios precompilados directamente desde los lanzamientos (GitHub Releases). Recomendado para instalacion rapida sin necesidad de compilar Qt6 o Rust.
2. **`moto-buds-appimage`**: Descarga el paquete autonomo AppImage e integra el lanzador `.desktop` e iconos en el sistema.
3. **`moto-buds-git`**: Clona el codigo fuente de la rama principal y lo compila localmente con Cargo y CMake.

## Instalacion Local (Pruebas)

Para probar cualquiera de los paquetes localmente:

```bash
cd packaging/arch/moto-buds-bin
makepkg -si
```

O para el paquete basado en AppImage:
```bash
cd packaging/arch/moto-buds-appimage
makepkg -si
```

## Como Publicar en el AUR

Si mantienes una cuenta en [aur.archlinux.org](https://aur.archlinux.org):

1. Clona el repositorio AUR correspondiente (por ejemplo, para `moto-buds-bin`):
   ```bash
   git clone ssh://aur@aur.archlinux.org/moto-buds-bin.git /tmp/moto-buds-bin-aur
   ```

2. Copia el `PKGBUILD` y genera el `.SRCINFO`:
   ```bash
   cp packaging/arch/moto-buds-bin/PKGBUILD /tmp/moto-buds-bin-aur/
   cd /tmp/moto-buds-bin-aur
   makepkg --printsrcinfo > .SRCINFO
   ```

3. Confirma y sube los cambios:
   ```bash
   git add PKGBUILD .SRCINFO
   git commit -m "Initial release 0.1.0"
   git push origin master
   ```

Una vez publicado, cualquier usuario de Arch Linux o CachyOS podra instalarlo con:
```bash
yay -S moto-buds-bin
# o bien
paru -S moto-buds-bin
```
