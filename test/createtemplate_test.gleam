import gleam/dict
import gleeunit
import internal/createtemplate.{
  EndBlock, StartBlock, get_block_tokens, get_blocks, tokenize,
}
import internal/template.{Loop, Text, Variable}

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn get_tokens_single_test() {
  let tokens =
    "{{{ block testing }}}gabagabagoo{{{ block end }}}"
    |> get_block_tokens

  let assert [StartBlock("testing", "gabagabagoo"), EndBlock] = tokens
}

pub fn get_tokens_multi_test() {
  let tokens =
    "{{{ block testing }}}gabagabagoo{{{ block end }}}{{{ block testing2 }}}gabagabagee{{{ block end }}}"
    |> get_block_tokens

  let assert [
    StartBlock("testing", "gabagabagoo"),
    EndBlock,
    StartBlock("testing2", "gabagabagee"),
    EndBlock,
  ] = tokens
}

pub fn get_tokens_with_vars_test() {
  let tokens =
    "{{{ block testing }}}{{ gabagabagoo }}{{{ block end }}}"
    |> get_block_tokens

  let assert [StartBlock("testing", "{{ gabagabagoo }}"), EndBlock] = tokens
}

pub fn get_blocks_single_test() {
  let assert Ok(blocks) =
    [StartBlock(name: "testing", contents: "gabagabagoo"), EndBlock]
    |> get_blocks(dict.new())
  let assert Ok("gabagabagoo") =
    blocks
    |> dict.get("testing")
}

pub fn get_blocks_multiple_test() {
  let assert Ok(blocks) =
    [
      StartBlock(name: "testing", contents: "gabagabagoo"),
      EndBlock,
      StartBlock(name: "testing2", contents: "gabagabagee"),
      EndBlock,
    ]
    |> get_blocks(dict.new())
  let assert Ok("gabagabagoo") =
    blocks
    |> dict.get("testing")
  let assert Ok("gabagabagee") =
    blocks
    |> dict.get("testing2")
}

pub fn get_blocks_error_test() {
  let assert Error(_) =
    [
      StartBlock(name: "testing", contents: "gabagabagoo"),
      StartBlock(name: "testing2", contents: "gabagabagee"),
      EndBlock,
    ]
    |> get_blocks(dict.new())
}

pub fn tokenize_no_tokens_test() {
  let str = "testing"
  let assert Ok([Text("testing")]) = tokenize(str, [])
}

pub fn tokenize_variable_test() {
  let str = "testing{{ var1 }}yaba"
  let assert Ok([Text("testing"), Variable("var1"), Text("yaba")]) =
    tokenize(str, [])
}

pub fn tokenize_loop_test() {
  let str = "testing{{ loop vars as var }}foo{{ end loop }}yaba"
  let assert Ok([
    Text("testing"),
    Loop("vars", "var", [Text("foo")]),
    Text("yaba"),
  ]) = tokenize(str, [])
}

pub fn tokenize_variable_in_loop_test() {
  let str = "testing{{ loop vars as var }}aga{{ foo }}aba{{ end loop }}yaba"
  let assert Ok([
    Text("testing"),
    Loop("vars", "var", [Text("aga"), Variable("foo"), Text("aba")]),
    Text("yaba"),
  ]) = tokenize(str, [])
}
