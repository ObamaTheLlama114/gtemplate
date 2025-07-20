import gleam/dict
import gleeunit

import gtemplate.{create_template, render_template}
import template

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn render_template_with_variable_test() {
  let assert Ok(template) =
    "{{{ block testing }}}hello {{ var }}!{{{ end block }}}"
    |> create_template("testing")
  let assert Ok("hello world!") =
    render_template(
      template,
      dict.from_list([#("var", template.String("world"))]),
    )
}

pub fn render_template_with_loop_test() {
  let assert Ok(template) =
    "{{{ block testing }}}{{ loop vars as var }}hello {{ var }}!{{ end loop }}{{{ end block }}}"
    |> create_template("testing")
  let assert Ok("hello world!hello mom!") =
    render_template(
      template,
      dict.from_list([
        #(
          "vars",
          template.List([template.String("world"), template.String("mom")]),
        ),
      ]),
    )
}

pub fn render_template_with_loop_in_loop_test() {
  let assert Ok(template) =
    "{{{ block testing }}}{{ loop vars as var }}{{ loop vars2 as var2 }}{{ var }} {{ var2 }}!{{ end loop }}{{ end loop }}{{{ end block }}}"
    |> create_template("testing")
  let assert Ok("hello world!hello mom!goodbye world!goodbye mom!") =
    render_template(
      template,
      dict.from_list([
        #(
          "vars",
          template.List([template.String("hello"), template.String("goodbye")]),
        ),
        #(
          "vars2",
          template.List([template.String("world"), template.String("mom")]),
        ),
      ]),
    )
}

pub fn render_template_with_if_test() {
  let assert Ok(template) =
    "{{{ block testing }}}{{ if var then }}{{ var2 }}{{ end if }}{{{ end block }}}"
    |> create_template("testing")
  let assert Ok("foo") =
    render_template(
      template,
      dict.from_list([
        #("var", template.Bool(True)),
        #("var2", template.String("foo")),
      ]),
    )
}

pub fn render_template_with_if_else_test() {
  let assert Ok(template) =
    "{{{ block testing }}}{{ if var then }}{{ var2 }}{{ else }}{{ var3 }}{{ end if }}{{{ end block }}}"
    |> create_template("testing")
  let assert Ok("bar") =
    render_template(
      template,
      dict.from_list([
        #("var", template.Bool(False)),
        #("var2", template.String("foo")),
        #("var3", template.String("bar")),
      ]),
    )
}
