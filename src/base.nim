import std/macros
import results

type Err = object
  msg: string

macro bindResults(): untyped =
  discard

when isMainModule:
  proc getSomeValue(n = false): Result[float, Err] =
    if not n: 
      return err(Err(msg: "This is an error"))
    else:
      return ok(123.3)

  let x = getSomeValue()
  echo x
