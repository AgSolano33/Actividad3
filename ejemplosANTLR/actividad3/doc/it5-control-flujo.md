---
iteracion: 5
tema: Comparaciones e if/then/else
tiempo_estimado: 45 min
---

# Iteración 5 — Control de flujo

## Meta

Tu compilador puede tomar decisiones. Un programa como este debe funcionar:

```
x <-- 7
if x > 5 then
  print x
else
  print 0
```

Y también sin else:

```
if x == 10 then
  print 1
```

## Lo que se añade a la gramática

- **Comparadores**: `==` (igual), `!=` (distinto), `<` (menor que), `>` (mayor que).
  Una comparación entre dos expresiones produce el valor 1 si es verdadera, 0 si es falsa.
- **Sentencia if/then/else**: la forma `if expresión then sentencia` ejecuta la sentencia
  solo si la expresión es distinta de cero. La parte `else sentencia` es opcional.

Esta iteración es la más compleja hasta ahora porque el compilador no puede simplemente
traducir línea por línea: tiene que generar saltos en el código MIPS para saltar el bloque
`then` cuando la condición es falsa, y saltar el bloque `else` cuando ya ejecutó el `then`.
El LLM necesitará generar etiquetas únicas para cada if.

## Una pista conceptual importante

Cuando el compilador genera código para un `if`, el código en MIPS tiene esta forma:

```
evaluar la condición → queda un valor (0 o 1) en un registro
si ese valor es 0, saltar a la etiqueta del else (o del fin)
[código del then]
saltar al fin (solo si hay else)
etiqueta del else:
[código del else]
etiqueta del fin:
```

El desafío es que cuando el método del Listener se ejecuta, los sub-bloques (condición,
then, else) ya fueron procesados. El truco es acumular cada bloque en un buffer separado
y ensamblarlos en el orden correcto al final. Explícaselo así al modelo.

## Pruebas de aceptación

Genera tus propios programas y verifica en QtSPIM.
Tu suite debe cubrir:

- Cada comparador por separado (`==`, `!=`, `<`, `>`) con un `print` del resultado — deben imprimir 1 o 0
- Un `if` sin `else` donde la condición sea verdadera — verificar que ejecuta el bloque
- Un `if` sin `else` donde la condición sea falsa — verificar que no ejecuta nada
- Un `if/else` — verificar que solo ejecuta una rama
- Un `if` anidado dentro de otro `if` — verificar que el `else` pertenece al `if` más cercano
- Una comparación usada como valor en una expresión aritmética (ej. `print (x > 0) + 1`)

## Prompt de ejemplo para el LLM

---

> Necesito agregar comparaciones e if/then/else a mi compilador RaraLang → MIPS.
>
> Las comparaciones (`==`, `!=`, `<`, `>`) deben producir 1 si son verdaderas y 0 si
> son falsas. En SPIM hay pseudo-instrucciones para esto que hacen exactamente eso.
> Para "mayor que", nota que `a > b` es lo mismo que `b < a`, así que se puede
> reusar la misma instrucción invirtiendo los operandos.
>
> Para el if/then/else, el problema es que cuando el Listener termina de procesar el
> nodo `ifStmt`, el código de la condición, del bloque then y del bloque else ya fue
> generado y está en la pila. La solución es usar buffers separados: mientras se procesa
> la condición, emitir a un buffer "cond"; cuando empieza el then, cambiar a buffer "then";
> cuando empieza el else, cambiar a buffer "else". Al salir del ifStmt, ensamblar los tres
> buffers con los saltos correctos.
>
> Para detectar cuándo empieza el then (vs la condición), se puede usar el método
> `enterEveryRule` del Listener, que se llama antes de cada regla. Cuando el nodo que
> está por procesarse es el primer stmt hijo del ifStmt, sabemos que terminó la condición.
>
> Necesito:
> - `exitEq`, `exitNeq`, `exitLt`, `exitGt`
> - Una clase o estructura `_CtrlFrame` para guardar los buffers de un bloque if
> - `enterIfStmt` para preparar el frame
> - `exitIfStmt` para ensamblar los buffers con etiquetas y saltos
> - `enterEveryRule` para detectar las transiciones de fase
>
> Aquí está la gramática del if: [pegar la sección ifStmt].

---

## Reflexión (llenar después de terminar esta iteración)

**¿Para qué sirve `enterEveryRule` en esta implementación? ¿Por qué no basta con `enterIfStmt` y `exitIfStmt`?**

> _

**Prueba un if anidado dentro de otro if. ¿Funciona? Si algo falla, ¿dónde está el problema?**

> _

**El modelo generó etiquetas como `if_end_1`, `if_end_2`, etc. ¿Por qué tiene que ser un número diferente para cada if? ¿Qué pasaría si todos usaran la misma etiqueta?**

> _
