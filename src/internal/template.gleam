pub type Token {
  Text(String)
  Variable(name: String)
  Loop(iterable: String, variable_name: String, tokens: List(Token))
  If(condition: String, then_tokens: List(Token), else_tokens: List(Token))
}

pub type Template {
  Template(tokens: List(Token))
}

pub type Variable {
  String(String)
  List(List(Variable))
  Bool(Bool)
}
