import gleam/list
import gleam/result
import gleam/string
import internal/template.{type Token, If, Loop, Template, Text, Variable}

pub fn create_template(str: String, name: String) {
  let block = get_block(str, name)
  let block = case block {
    Ok(block) -> Ok(block)
    Error(_) -> Error("Block " <> name <> " does not exist")
  }
  use block <- result.try(block)

  let tokens = block |> tokenize([])
  let tokens = case tokens {
    Ok(tokens) -> Ok(tokens)
    Error(err) ->
      Error("Block " <> name <> " has invalid instructions: " <> err)
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

pub fn tokenize(str: String, acc: List(Token)) -> Result(List(Token), String) {
  case str |> string.split_once("{{ ") {
    Ok(#(before, after)) -> {
      let result = after |> string.split_once(" }}")
      let result = case result {
        Ok(x) -> x |> Ok
        Error(_) -> Error("Unfinished instruction")
      }
      use #(token, after) <- result.try(result)
      let token = token |> string.split(" ")

      // this case also returns after as the loop case changes it
      let token = case token {
        // loop case
        ["loop", iterable, "as", variable_name] -> {
          let end_loop = case
            after |> string.split("{{ end loop }}") |> list.reverse
          {
            [_] ->
              Error(
                "loop "
                <> iterable
                <> " as "
                <> variable_name
                <> " has no end loop",
              )
            [] -> panic
            [after, ..inner] -> {
              let inner = inner |> list.reverse |> string.join("{{ end loop }}")
              Ok(#(inner, after))
            }
          }
          use #(inner, after) <- result.try(end_loop)
          use inner <- result.try(tokenize(inner, []))
          let loop = Loop(iterable, variable_name, inner)
          #(loop, after) |> Ok
        }

        // if case
        ["if", condition, "then"] -> {
          let end_if = case
            after |> string.split("{{ end if }}") |> list.reverse
          {
            [_] -> Error("if " <> condition <> " then" <> " has no end if")
            [] -> panic
            [after, ..inner] -> {
              let inner = inner |> list.reverse |> string.join("{{ end if }}")
              Ok(#(inner, after))
            }
          }
          use #(inner, after) <- result.try(end_if)
          let token = case inner |> string.split("{{ else }}") |> list.reverse {
            [str] -> {
              use then_tokens <- result.try(str |> tokenize([]))
              Ok(If(condition, then_tokens, []))
            }
            [else_tokens, ..then_tokens] -> {
              let then_tokens =
                then_tokens |> list.reverse |> string.join("{{ else }}")
              use then_tokens <- result.try(tokenize(then_tokens, []))
              use else_tokens <- result.try(tokenize(else_tokens, []))
              Ok(If(condition, then_tokens, else_tokens))
            }
            _ -> panic
          }
          use token <- result.try(token)
          Ok(#(token, after))
        }

        // variable case
        [var] -> #(Variable(var), after) |> Ok

        _ -> Error("Empty instruction")
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
