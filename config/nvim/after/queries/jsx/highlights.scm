; extends

; Treat both sides of component member tags like components: <Field.Root>
(jsx_opening_element
  (member_expression
    (identifier) @tag
    (property_identifier) @tag))

(jsx_closing_element
  (member_expression
    (identifier) @tag
    (property_identifier) @tag))

(jsx_self_closing_element
  (member_expression
    (identifier) @tag
    (property_identifier) @tag))
