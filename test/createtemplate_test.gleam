import gleeunit
import internal/createtemplate.{get_block, tokenize}
import internal/template.{If, Loop, Text, Variable}

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn get_block_single_test() {
  let str = "{{{ block foo }}}bar{{{ end block }}}"
  let assert Ok("bar") = str |> get_block("foo")
}

pub fn get_block_multi_test() {
  let str =
    "{{{ block foo }}}bar{{{ end block }}}{{{ block baz }}}boo{{{ end block }}}"
  let assert Ok("bar") = str |> get_block("foo")
  let assert Ok("boo") = str |> get_block("baz")
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

pub fn tokenize_if_test() {
  let str = "testing{{ if foo then }}bar{{ end if }}yaba"
  let assert Ok([Text("testing"), If("foo", [Text("bar")], []), Text("yaba")]) =
    tokenize(str, [])
}

pub fn tokenize_if_else_test() {
  let str = "testing{{ if foo then }}bar{{ else }}baz{{ end if }}yaba"
  let assert Ok([
    Text("testing"),
    If("foo", [Text("bar")], [Text("baz")]),
    Text("yaba"),
  ]) = tokenize(str, [])
}
