# Minutas

Registro de minutas de reuniones. Archivo único (`index.html`), sin build ni dependencias
más allá de la librería de Supabase que baja del CDN.

Mismo lenguaje visual y misma mecánica de datos que
[seguimiento-semanl](https://github.com/tdeluca-we-are/seguimiento-semanl): navy + naranja,
Montserrat, login con la cuenta de We Are y un documento JSON por usuario en Supabase.

## Puesta en marcha

1. Correr `minutas-schema.sql` una sola vez en el SQL editor de Supabase
   (proyecto `ojzcxwhoinmljospgmfp`). Crea `public.min_estado` con RLS.
2. Abrir `index.html` y entrar con la misma cuenta del seguimiento, el semáforo y slots.
   La fila se crea sola en el primer login.

## Cómo guarda

Un documento `jsonb` por usuario en `min_estado`, con una columna `version` como control
optimista: la app actualiza con `where version = <la que leyó>`; si no afecta ninguna fila
es que otro dispositivo guardó primero, y en vez de pisar pregunta qué hacer.

`localStorage` (`minutas_v1` + `minutas_meta`) queda como caché: si falla la subida se
reintenta sola, y al volver a entrar ofrece recuperar lo que nunca llegó.

Ojo: `file://` y `https://` son orígenes distintos para el navegador, pero eso solo afecta
a la caché — los datos reales viven en Supabase, así que la versión publicada muestra lo
mismo que la local apenas iniciás sesión.

## Qué tiene

- **Minutas** — historial completo agrupado por mes, con filtros por tipo, marca,
  participante y rango de fechas, más un filtro de texto sobre todo el contenido.
- **Detalle** — título, fecha, hora, tipo, marca, participantes y etiquetas; tres bloques
  de notas con formato (objetivo, qué se habló, decisiones), pendientes con responsable y
  fecha, y las reuniones anteriores de la misma marca o con la misma gente.
- **Pendientes** — todo lo que quedó abierto en cualquier reunión, filtrable por estado,
  responsable y marca, con link a la minuta de origen.
- **Personas y marcas** — cuántas reuniones tuviste con cada uno, cuándo fue la última y
  el historial completo en orden, exportable como texto.
- **Buscador global** (Ctrl+K) sobre todas las minutas, con el fragmento resaltado.
- **Config** — pegar minutas en JSON (lo que devuelve Claude al volcar una reunión de
  Tactiq), exportar/importar respaldo, exportar todo en `.txt`.

## Traer una reunión de Tactiq

Pedirle a Claude *"volcá al minutero la reunión de hoy con X"*. Devuelve un bloque JSON con
esta forma, que se pega en **Config → Pegar minutas**:

```json
{"minutas":[{
  "titulo":"Weekly O'Higgins",
  "fecha":"2026-09-08",
  "hora":"10:30",
  "tipo":"cliente",
  "marca":"O'Higgins",
  "participantes":["Tomás","Peny"],
  "tags":["email"],
  "objetivo":"...",
  "notas":"...",
  "decisiones":"...",
  "pendientes":[{"texto":"...","resp":"Peny","fecha":"2026-09-15"}],
  "proxima":"2026-09-15",
  "fuente":"tactiq",
  "tactiqId":"<id de la reunión>",
  "tactiqUrl":"https://..."
}]}
```

Solo `titulo` y `fecha` son obligatorios. Si ya existe una minuta con el mismo `tactiqId`,
se actualiza en lugar de duplicarse — así se puede volver a volcar la misma reunión sin
ensuciar el historial.
