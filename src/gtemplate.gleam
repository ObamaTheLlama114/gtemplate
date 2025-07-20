import gleam/dict.{type Dict}
import gleam/list
import gleam/result
import gleam/string
import simplifile

pub opaque type Token {
  Text(String)
  Variable(name: String)
  Loop(iterable: String, variable_name: String, tokens: List(Token))
  If(condition: String, then_tokens: List(Token), else_tokens: List(Token))
}

pub opaque type Template {
  Template(tokens: List(Token))
}

pub type Variable {
  String(String)
  List(List(Variable))
  Bool(Bool)
}

pub fn create_template_from_file(file_name: String, name: String) {
  let str = simplifile.read(file_name)
  let str = case str {
    Ok(str) -> str |> Ok
    Error(err) ->
      Error("Error reading file: " <> simplifile.describe_error(err))
  }
  use str <- result.try(str)
  create_template_from_block(str, name)
}

pub fn create_template_from_block(str: String, name: String) {
  let block = get_block(str, name)
  let block = case block {
    Ok(block) -> Ok(block)
    Error(_) -> Error("Block " <> name <> " does not exist")
  }
  use block <- result.try(block)
  create_template(block)
}

pub fn create_template(str: String) {
  let tokens = str |> tokenize([])
  use tokens <- result.try(tokens)

  Template(tokens)
  |> Ok
}

fn get_block(str: String, name: String) {
  use #(_, str) <- result.try(
    str |> string.split_once("{{{ block " <> name <> " }}}"),
  )
  use #(str, _) <- result.try(str |> string.split_once("{{{ end block }}}"))
  str |> Ok
}

fn tokenize(str: String, acc: List(Token)) -> Result(List(Token), String) {
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

pub fn render_template(
  template: Template,
  variables: Dict(String, Variable),
) -> Result(String, String) {
  let Template(tokens) = template
  render_tokens(tokens, variables, "")
}

fn render_tokens(
  tokens: List(Token),
  variables: Dict(String, Variable),
  acc: String,
) -> Result(String, String) {
  case tokens {
    [Variable(name), ..rest] -> {
      let value = variables |> dict.get(name)
      let value = case value {
        Ok(value) -> value |> Ok
        Error(_) -> Error(name <> " not in variables")
      }
      use value <- result.try(value)
      case value {
        String(value) -> render_tokens(rest, variables, acc <> value)
        _ -> Error("Expected value of " <> name <> " to be a string")
      }
    }
    [Text(text), ..rest] -> render_tokens(rest, variables, acc <> text)
    [Loop(iterable, variable_name, inner), ..rest] -> {
      let value = variables |> dict.get(iterable)
      let value = case value {
        Ok(value) -> value |> Ok
        Error(_) -> Error(iterable <> " not in variables")
      }
      use value <- result.try(value)
      let value = case value {
        List(value) -> Ok(value)
        _ -> Error("Expected value of " <> iterable <> " to be a list")
      }
      use value <- result.try(value)
      let value = render_loop(value, variable_name, variables, inner, "")
      use value <- result.try(value)
      render_tokens(rest, variables, acc <> value)
    }
    [If(condition, then_tokens, else_tokens), ..rest] -> {
      let value = variables |> dict.get(condition)
      let value = case value {
        Ok(value) -> value |> Ok
        Error(_) -> Error(condition <> " not in variables")
      }
      use value <- result.try(value)
      let value = case value {
        Bool(value) -> Ok(value)
        _ -> Error("Expected value of " <> condition <> " to be a bool")
      }
      use value <- result.try(value)
      let value = case value {
        True -> render_tokens(then_tokens, variables, "")
        False -> render_tokens(else_tokens, variables, "")
      }
      use value <- result.try(value)
      render_tokens(rest, variables, acc <> value)
    }
    [] -> acc |> Ok
  }
}

fn render_loop(
  iterable: List(Variable),
  variable_name: String,
  variables: Dict(String, Variable),
  tokens: List(Token),
  acc: String,
) -> Result(String, String) {
  case iterable {
    [] -> acc |> Ok
    [value, ..rest] -> {
      let new_variables = variables |> dict.insert(variable_name, value)
      let rendered = render_tokens(tokens, new_variables, "")
      use rendered <- result.try(rendered)
      render_loop(rest, variable_name, variables, tokens, acc <> rendered)
    }
  }
}
