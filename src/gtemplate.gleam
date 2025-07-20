import gleam/dict.{type Dict}
import gleam/result
import simplifile

import internal/createtemplate.{type Token, get_block, tokenize}
import internal/rendertemplate.{render_tokens}
import template.{type Variable}

pub opaque type Template {
  Template(tokens: List(Token))
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

pub fn render_template(
  template: Template,
  variables: Dict(String, Variable),
) -> Result(String, String) {
  let Template(tokens) = template
  render_tokens(tokens, variables, "")
}
