# gtemplate

[![Package Version](https://img.shields.io/hexpm/v/gtemplate)](https://hex.pm/packages/gtemplate)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/gtemplate/)

Gtemplate provides a simple yet effective templating engine

## Example

```html
<!-- index.html -->
{{{ block home_page }}}
<html>
  <header>
    <title>{{ title }}</title>
  </header>
  <body>
    {{ if show_list then }}
      <ul>
        {{ loop items as item }}
          <li>
            {{ item }}
          </li>
        {{ end loop }}
      </ul>
    {{ end if }}
  </body>
</html>
{{{ end block }}}
```
```gleam
import dict
import io
import gtemplate.{String}

pub fn main() -> Nil {
  let assert Ok(home_page_template) = gtemplate.create_template_from_file("index.html", "home_page")
  let render_home_page = gtemplate.render_template(home_page_template, _)
  let values = dict.from(#("title", "index"), #("show_list", True), #("Items", [String("list item 1"), String("list item 2")]))
  io.print(render_home_page(values))
}
```

Further documentation can be found at <https://hexdocs.pm/gtemplate>.

## Installation

```sh
gleam add gtemplate@1
```

## Contributing

Contributions are welcome! The best way to start for medium to large features is by opening an issue with the feature suggestion, otherwise feel free to just make a PR! Code contributions should include tests.