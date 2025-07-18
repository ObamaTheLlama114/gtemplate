import gleam/dict
import gleeunit
import internal/rendertemplate

import internal/createtemplate.{create_template}
import internal/template.{Template, Text, Variable}

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn create_template_single_test() {
  let assert Ok(template) =
    "{{{ block testing }}}gabagabagoo{{{ block end }}}"
    |> create_template("testing")
  let assert Template([Text("gabagabagoo")]) = template
}

pub fn create_template_multi_test() {
  let str =
    "{{{ block testing }}}gabagabagoo{{{ block end }}}{{{ block testing2 }}}gabagabagee{{{ block end }}}"
  let assert Ok(template) =
    str
    |> create_template("testing")
  let assert Template([Text("gabagabagoo")]) = template
  let assert Ok(template) =
    str
    |> create_template("testing2")
  let assert Template([Text("gabagabagee")]) = template
}

pub fn create_template_with_variable_test() {
  let assert Ok(template) =
    "{{{ block testing }}}hello {{ var }}!{{{ block end }}}"
    |> create_template("testing")
  let assert Template([Text("hello "), Variable("var"), Text("!")]) = template
}

pub fn render_template_with_variable_test() {
  let assert Ok(template) =
    "{{{ block testing }}}hello {{ var }}!{{{ block end }}}"
    |> create_template("testing")
  let assert Template([Text("hello "), Variable("var"), Text("!")]) = template
  let assert Ok("hello world!") =
    rendertemplate.render_template(
      template,
      dict.from_list([#("var", template.String("world"))]),
    )
}

pub fn render_template_with_loop_test() {
  let assert Ok(template) =
    "{{{ block testing }}}{{ loop vars as var }}hello {{ var }}!{{ end loop }}{{{ block end }}}"
    |> create_template("testing")
  let assert Ok("hello world!hello mom!") =
    rendertemplate.render_template(
      template,
      dict.from_list([#("vars", template.List(["world", "mom"]))]),
    )
}
