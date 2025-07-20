import gleam/dict.{type Dict}
import gleam/result

import internal/createtemplate.{type Token, get_block, tokenize}
import internal/rendertemplate.{render_tokens}
import template.{type Variable}

pub opaque type Template {
  Template(tokens: List(Token))
}

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

pub fn render_template(
  template: Template,
  variables: Dict(String, Variable),
) -> Result(String, String) {
  let Template(tokens) = template
  render_tokens(tokens, variables, "")
}
