# Used by "mix format"
[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  plugins: [Quokka],
  quokka: [
    # everything:
    autosort: [:schema]
    # only: [:schema, :comment_directives, :module_directives]
  ]
]
