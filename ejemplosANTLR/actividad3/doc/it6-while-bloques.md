---
iteracion: 6
tema: While y bloques de sentencias
tiempo_estimado: 30 min
---

# Iteración 6 — While y bloques

## Meta

Tu compilador puede ejecutar ciclos y agrupar sentencias. Esto debe funcionar:

```
x <-- 1
while x < 10 do {
  print x
  x <-- x + 1
}
```

## Lo que se añade a la gramática

- **Bloque de sentencias**: un grupo de sentencias entre llaves `{ ... }`. Puede contener
  cualquier número de sentencias (incluso cero). Sirve como una sola sentencia en
  cualquier lugar donde puede ir una sentencia.
- **Sentencia while**: la forma `while condición do sentencia` repite la sentencia
  mientras la condición sea distinta de cero. La sentencia puede ser un bloque.

El while usa la misma técnica de buffers que el if: hay que acumular el código de la
condición y el cuerpo por separado, porque al salir del while hay que ensamblarlos
en un orden específico con etiquetas de salto hacia atrás.

## Pruebas de aceptación

Genera tus propios programas y verifica en QtSPIM.
Tu suite debe cubrir:

- Un while que itere un número conocido de veces e imprima algo en cada iteración
- Un while cuya condición sea falsa desde el inicio — no debe ejecutar el cuerpo ni una vez
- Un bloque vacío `{}` — no debe generar error
- Un bloque con múltiples sentencias usado como cuerpo del while
- Dos while anidados — el interno debe terminar antes de que el externo avance
- Un while dentro de un if (o un if dentro de un while) — verificar que los frames no se mezclan

## Prompt de ejemplo para el LLM

---

> Necesito agregar while y bloques a mi compilador RaraLang → MIPS.
>
> Un bloque `{ stmt1 stmt2 ... }` no necesita generar instrucciones adicionales: las
> sentencias dentro ya fueron procesadas y su código ya está en el buffer correcto.
> El método `exitBlockStmt` puede quedar vacío.
>
> Para el while, el código MIPS tiene la estructura de un ciclo con salto hacia atrás:
> hay una etiqueta al inicio (antes de la condición), un salto condicional al final si
> la condición es falsa, el cuerpo del ciclo, un salto incondicional de vuelta al inicio,
> y la etiqueta del final. La misma técnica de buffers del if aplica aquí: buffer para
> la condición y buffer para el cuerpo.
>
> Necesito:
> - `enterWhileStmt` para preparar el frame con las etiquetas del ciclo
> - `exitWhileStmt` para ensamblar condición + cuerpo con los saltos
> - El `enterEveryRule` que ya existe debe detectar también la transición al cuerpo del while
>
> Aquí está el frame del if que ya funciona: [pegar la implementación].
> El while sigue el mismo patrón pero con distintas etiquetas y estructura de ensamblado.

---

## Reflexión (llenar después de terminar esta iteración)

**¿Cuántos saltos tiene un while en el código generado? ¿Cuál va hacia adelante y cuál hacia atrás?**

> _

**Escribe (o pídele al LLM) un programa con tres while anidados. ¿Funciona correctamente? Describe brevemente qué hace el programa.**

> _

**¿Qué pasaría si el `exitBlockStmt` no existiera en el Listener? ¿Daría error?**

> _
