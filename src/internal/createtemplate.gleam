import gleam/list
import gleam/result
import gleam/string
import internal/template.{type Token, Loop, Template, Text, Variable}

pub fn create_template(str: String, name: String) {
  let block = get_block(str, name)
  let block = case block {
    Ok(block) -> Ok(block)
    Error(_) -> Error("Block " <> name <> " doesnt exist")
  }
  use block <- result.try(block)

  let tokens = block |> tokenize([])
  let tokens = case tokens {
    Ok(tokens) -> Ok(tokens)
    Error(_) -> Error("Invalid instructions")
  }
  use tokens <- result.try(tokens)

  Template(tokens)
  |> Ok
}

pub fn get_block(str: String, name: String) {
  use #(_, str) <- result.try(
    str |> string.split_once("{{{ block " <> name <> " }}}"),
  )
  use #(str, _) <- result.try(str |> string.split_once("{{{ end block }}}"))
  str |> Ok
}

pub fn tokenize(str: String, acc: List(Token)) {
  case str |> string.split_once("{{ ") {
    Ok(#(before, after)) -> {
      use #(token, after) <- result.try(after |> string.split_once(" }}"))
      let token = token |> string.split(" ")

      // this case also returns after as the loop case changes it
      let token = case token {
        // loop case
        ["loop", iterable, "as", variable_name] -> {
          use #(inner, after) <- result.try(
            after |> string.split_once("{{ end loop }}"),
          )
          use inner <- result.try(tokenize(inner, []))
          let loop = Loop(iterable, variable_name, inner)
          #(loop, after) |> Ok
        }

        // variable case
        [var] -> #(Variable(var), after) |> Ok

        _ -> Error(Nil)
      }

      use #(token, after) <- result.try(token)
      let before = Text(before)
      let acc = list.append(acc, [before, token])
      tokenize(after, acc)
    }
    Error(_) -> {
      list.append(acc, [Text(str)]) |> Ok
    }
  }
}
