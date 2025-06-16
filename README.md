# JDI DRM Enhanced Driver

Driver DRM mejorado para pantalla Sharp Memory LCD 2.7" (JDI LT027B5AC01) con resolución 400x240.

## Características

- Soporte completo para DRM (Direct Rendering Manager)
- Optimizado para pantalla JDI LT027B5AC01
- Soporte para color y monocromo
- Control de retroiluminación
- Gestión de energía avanzada
- Comunicación SPI optimizada
- Interfaz IOCTL para control directo
- Overlays gráficos

## Instalación

```bash
make
sudo make install
```

## Configuración

El driver incluye varios parámetros configurables:

- `backlight`: Habilitar/deshabilitar retroiluminación (0/1)
- `mono_cutoff`: Umbral de escala de grises (0-255)
- `mono_invert`: Inversión de monocromo (0/1)
- `auto_clear`: Limpiar pantalla al descargar driver (0/1)
- `color`: Habilitar modo color (0/1)

## Uso

Una vez instalado, el driver aparecerá como dispositivo DRM estándar en `/dev/dri/`.

## Hardware Soportado

- JDI LT027B5AC01 (400x240)
- Sharp Memory LCD compatible

## Autor

N@Xs

## Licencia

GPL v2 o posterior
