import algebra.group algebra.precategory.basic algebra.precategory.morphism

open eq sigma unit precategory morphism path_algebra

context
  parameters {P₀ : Type} [P : precategory P₀]

  structure my_structure := (a : P₀) (b : P₀) (f : @hom P₀ P a b)
  include P

  structure another_structure (X : my_structure) := (field1 : hom (my_structure.a X) (my_structure.a X))

end
