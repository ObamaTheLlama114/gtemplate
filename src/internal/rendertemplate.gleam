import gleam/dict.{type Dict}
import gleam/result
import internal/template.{type Token, type Variable, Loop, Text, Variable}

pub fn render_template(
  template: template.Template,
  variables: Dict(String, Variable),
) -> Result(String, String) {
  let template.Template(tokens) = template
  render_tokens(tokens, variables, "")
}

pub fn render_tokens(
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
        template.String(value) -> render_tokens(rest, variables, acc <> value)
        template.List(_) ->
          Error("Expected value of " <> name <> " to be a string")
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
        template.List(value) -> Ok(value)
        template.String(_) ->
          Error("Expected value of " <> iterable <> " to be a list")
      }
      use value <- result.try(value)
      let value = render_loop(value, variable_name, variables, inner, "")
      use value <- result.try(value)
      render_tokens(rest, variables, acc <> value)
    }
    [] -> acc |> Ok
  }
}

pub fn render_loop(
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
