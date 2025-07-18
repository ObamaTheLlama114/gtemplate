import gleam/dict.{type Dict}
import gleam/result
import internal/template.{type Token, type Variable, Loop, Text, Variable}

pub fn render_template(
  template: template.Template,
  variables: Dict(String, Variable),
) -> Result(String, Nil) {
  let template.Template(tokens) = template
  render_tokens(tokens, variables, "")
}

pub fn render_tokens(
  tokens: List(Token),
  variables: Dict(String, Variable),
  acc: String,
) -> Result(String, Nil) {
  case tokens {
    [Variable(name), ..rest] -> {
      use value <- result.try(variables |> dict.get(name))
      case value {
        template.String(value) -> render_tokens(rest, variables, acc <> value)
        template.List(_) -> Error(Nil)
      }
    }
    [Text(text), ..rest] -> render_tokens(rest, variables, acc <> text)
    [Loop(iterable, variable_name, inner), ..rest] -> {
      use value <- result.try(variables |> dict.get(iterable))
      let value = case value {
        template.List(value) -> Ok(value)
        template.String(_) -> Error(Nil)
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
  iterable: List(String),
  variable_name: String,
  variables: Dict(String, Variable),
  tokens: List(Token),
  acc: String,
) -> Result(String, Nil) {
  case iterable {
    [] -> acc |> Ok
    [value, ..rest] -> {
      let new_variables =
        variables |> dict.insert(variable_name, template.String(value))
      let rendered = render_tokens(tokens, new_variables, "")
      use rendered <- result.try(rendered)
      render_loop(rest, variable_name, variables, tokens, acc <> rendered)
    }
  }
}
