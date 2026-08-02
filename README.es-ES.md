# Módulo dotenv para V
[![Última versión][version-badge]][version-url] [![CI](https://github.com/zztkm/vdotenv/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/zztkm/vdotenv/actions/workflows/ci.yml)

Inglés
/ [Japonés](./docs/README_ja.md)

vdotenv es un módulo que permite leer variables de entorno desde archivos `.env`.

- Carga variables de entorno desde un archivo `.env`.
- Permite sobrescribir variables de entorno existentes en el programa.
- Inspirado en https://github.com/joho/godotenv.


[Documentación del módulo.](docs/vdotenv.md)

## Uso

Añade la configuración de tu aplicación en el archivo `.env` ubicado en la raíz de tu proyecto:
```
S3_BUCKET=YOURS3BUCKET
DYNAMODB_TABLE=YOURDYNAMODBTABLE
```

Luego, en tu aplicación V, puedes hacer lo siguiente:

```v
import os

import zztkm.vdotenv

fn main() {
    // Carga variables de entorno desde un archivo .env.
    vdotenv.load()

    s3_bucket := os.getenv('S3_BUCKET')
    dynamodb_table := os.getenv('DYNAMODB_TABLE')

    // ...
}
```
Por defecto, `load` busca un archivo llamado `.env` en el directorio de trabajo actual, pero también puedes especificar el archivo de la siguiente manera:
```v
vdotenv.load(".env.develop") // Carga `.env.development`
vdotenv.load(".env", ".env.develop") // Carga `.env` y `.env.develop`
```

Puedes incluir comentarios en el archivo `.env`:
```
# Este es un comentario
FOO=BAR
API_URL=YOUR_API_URL # Este es un comentario en línea
```

## Instalación e importación

### Usando vpm:

Instalar/Actualizar:
```
v install zztkm.vdotenv
```

Importar:
```v
import zztkm.vdotenv
```

### Usando GitHub (poco recomendable):

```bash
v install --git https://github.com/hungrybluedev/whisker
```

Importar:
```v
import vdotenv
```


## Contribución

[Guía de contribución para este repositorio.](docs/CONTRIBUTING.md)

## Licencia

[Licencia MIT](LICENSE.txt)

[docs]: https://github.com/zztkm/vdotenv
[version-badge]: https://img.shields.io/github/v/release/zztkm/vdotenv?logo=github&logoColor=white
[version-url]: https://github.com/zztkm/vdotenv/releases/latest
[workflow-badge]: https://img.shields.io/github/workflow/status/zztkm/vdotenv/CI?label=test&logo=github&logoColor=white
[workflow-url]: https://github.com/zztkm/vdotenv/actions?query=workflow%3ACI

## Tareas pendientes

- [ ] [Aplicación CLI](https://github.com/zztkm/vdotenv/issues/13)
- [ ] README: agregar tutorial (para principiantes en dotenv)

## Agradecimientos

- [ivixvi](https://github.com/ivixvi)
- [ksk001100](https://github.com/ksk001100)
- [nyx-litenite](https://github.com/nyx-litenite)

## Autor

- [zztkm](https://github.com/zztkm/vdotenv)
