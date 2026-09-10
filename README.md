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

## Cargar una reunión desde un chat

El flujo pensado es: el resumen lo arma Claude en un chat normal, y se pega en el minutero
**tal cual**, sin pedirle ningún formato de máquina.

1. En **Config → Copiar el prompt para el chat** está el prompt fijo (la constante
   `PROMPT_RESUMEN` del script). Se pega en Claude junto con la reunión, o pidiéndole que la
   busque en Tactiq.
2. Se copia el resumen que devuelve.
3. **Config → Pegar una reunión**: la app lo interpreta, muestra qué entendió y recién con
   *Confirmar e importar* lo guarda. Si es una sola, la abre para revisarla.

El prompt y el parser viven en el mismo archivo a propósito: si cambia el formato del
resumen, se cambian los dos juntos.

El parser es tolerante — acepta encabezados en mayúscula o minúscula, con `##`, con `**` o
con dos puntos, y reconoce estas secciones (con sinónimos): **Objetivo** (contexto, motivo),
**Qué se habló** (temas, notas, resumen), **Decisiones** (acuerdos, definiciones),
**Riesgos** (alertas), **Pendientes** (tareas, próximos pasos, action items). Las claves del
encabezado son `Título`, `Fecha`, `Hora`, `Tipo`, `Marca` (o cuenta/cliente),
`Participantes`, `Etiquetas` y `Próxima reunión`. Varias reuniones en un mismo texto se
separan con una línea de `---`.

Cada pendiente se escribe `- [ ] qué hay que hacer — Responsable — DD/MM`. El responsable
también se reconoce como `@Nombre` o `(Nombre)`, y una fecha sin año cae en el año de la
reunión. Lo que no cae en ninguna sección va a *qué se habló*, así que nunca se pierde texto.

Si el tipo no viene, se deduce del título y de si hay marca: "1 a 1" → 1 a 1, "kickoff" →
comercial, con marca → cliente.

### Formato JSON (alternativa)

Sigue funcionando pegar JSON, útil si en algún momento conviene que Claude lo genere:

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
  "riesgos":"...",
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
