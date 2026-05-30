---
iteracion: 7
tema: Declaración y llamada a funciones
tiempo_estimado: 45 min
---

# Iteración 7 — Funciones

## Meta

Tu compilador puede definir y llamar funciones con parámetros. Esto debe funcionar:

```
func doble(x) {
  return x + x
}

func suma(a, b) {
  return a + b
}

print doble(5)
print suma(3, 4)
```

## Lo que se añade a la gramática

- **Declaración de función**: la forma `func nombre(p1, p2, ...) { cuerpo }` define una
  función con nombre, lista de parámetros (puede estar vacía) y un bloque como cuerpo.
  Las funciones se declaran al nivel superior del programa, no anidadas.
- **Sentencia return**: dentro de una función, `return expresión` termina la función y
  entrega el valor al que llamó.
- **Llamada a función como expresión**: `nombre(arg1, arg2, ...)` llama a la función y
  el valor que retorna puede usarse en cualquier expresión o en `print`.

## Convenciones que el compilador debe adoptar

El compilador tiene que elegir cómo pasar argumentos y devolver valores. La convención
estándar de MIPS usa registros específicos para esto. Pídele al modelo que siga la
convención estándar: argumentos en los primeros cuatro registros de argumento, valor de
retorno en el registro de valor.

Los parámetros se pueden almacenar como variables en la sección de datos (igual que
las variables locales), pero esto implica que **las funciones no pueden llamarse a sí
mismas recursivamente** — si lo intentan, la segunda llamada sobreescribe los parámetros
de la primera. Esa es una limitación explícita de este compilador.

## El bug que debes encontrar

Hay un caso que la mayoría de implementaciones iniciales no manejan: **una función que
llama a otra función**. Pídele al LLM que genere un programa donde una función llama
a otra, y verifica si el resultado es correcto. Si el programa se cuelga o da un
resultado incorrecto, pídele al modelo que explique el problema y cómo corregirlo.

Pista: cuando una función usa la instrucción de llamada (`jal`), esa instrucción guarda
una dirección en un registro especial (`$ra`). Si la función ya tenía algo importante
en ese registro (la dirección de quien la llamó), se pierde. La solución es guardar
ese valor en la pila antes del jal y restaurarlo después.

## Pruebas de aceptación

Genera tus propios programas y verifica en QtSPIM.
Tu suite debe cubrir:

- Una función con un parámetro que retorna un valor — verificar resultado
- Una función con dos o más parámetros
- Llamar a la misma función dos veces con distintos argumentos — verificar que cada llamada da su resultado correcto
- Una función que llama a otra función — este es el caso difícil; verifica cuidadosamente el resultado
- Llamar a una función y usar el resultado en una expresión aritmética (`print doble(3) + 1`)

## Prompt de ejemplo para el LLM

---

> Necesito agregar funciones a mi compilador RaraLang → MIPS.
>
> En MIPS, una función es una sección de código con una etiqueta. Para llamarla se usa
> `jal`, que salta a esa etiqueta y guarda la dirección de retorno en el registro `$ra`.
> Al terminar, `jr $ra` regresa al punto de llamada.
>
> La convención que quiero usar: los argumentos se pasan en `$a0`, `$a1`, `$a2`, `$a3`
> (máximo 4). El valor de retorno va en `$v0`. Los parámetros se guardan en variables
> en `.data` al entrar a la función (igual que variables normales).
>
> El código de las funciones debe ir después del código de main, separado, para que
> main no caiga en el código de la función por error.
>
> Hay un caso importante: cuando una función llama a otra función con `jal`, esa
> instrucción sobreescribe `$ra`. Cuando la función exterior quiera retornar, `$ra`
> ya no tiene la dirección correcta. La solución es que antes del `jal` interno,
> guardemos `$ra` en la pila del procesador, y lo restauremos después.
>
> Necesito:
> - `enterFuncDecl` para marcar que estamos dentro de una función y guardar los parámetros
> - `exitFuncDecl` para cerrar la función con `jr $ra`
> - `exitReturnStmt` para mover el resultado a `$v0` y retornar
> - `exitCall` para cargar argumentos, llamar con `jal`, y recuperar el resultado de `$v0`

---

## Reflexión (llenar después de terminar esta iteración)

**¿Por qué las funciones de este compilador no pueden ser recursivas? Explícalo en tus palabras.**

> _

**Prueba una función que llama a otra. ¿Funcionó directamente o hubo que corregir el bug de `$ra`? Describe qué síntoma viste cuando fallaba.**

> _

**¿Qué pasa si llamas a una función con más argumentos de los que espera? ¿Con menos? ¿Tu compilador lo detecta?**

> _
