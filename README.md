## Elixir Commons

[![Build Status](https://travis-ci.org/bitwalker/elixir-commons.svg?branch=master)](https://travis-ci.org/bitwalker/elixir-commons)

### What is it?

`elixir_commons` started as a collection of useful extensions to the standard library that I've been accumulating across projects. The name itself is inspired by a similar project by Erlware, called [erlware_commons](https://github.com/erlware/erlware_commons). This project is best used as a swiss army knife library that can help eliminate code that tends to get duplicated across projects, as well as form a foundation of well tested code that you can build upon, to better focus on what you are building rather than plumbing.

### Project Guidelines

Here's what I feel are the guidelines this project should adhere to, and set up the goals for future development.

- Compile a collection of useful code in one library, that acts as a superset of Elixir's standard library.
- Focus on well documented, well tested, high quality code that adheres to the community standards for Elixir projects. One of the goals is to make this project a great example to point people to for how to write general purpose code in Elixir.
- Stable API. I will avoid making any significant changes to the API once it has been made generally available in a release. The first few iterations of development will likely focus primarily on adding functionality, rather than changing functionality, but it's to be expected that there may be some changes early on. I will focus on making it stable as soon as possible.
- Ensure all code is cross-platform compatible.
- Avoid bulk, and attempt to keep this library lightweight enough so that it's not an issue to bring it in as a dependency.
- Highly modular. If you really want to use one piece of this library, you shouldn't have to spend a great deal of time extracting all the dependencies between modules.
- Avoid reproducing code readily available in other high quality libraries in the community. I don't want to try and reinvent the wheel in one library if it's already available elsewhere, and is well maintained. That said, if there are pieces of functionality that I feel belong in `elixir_commons`, I will likely allow exceptions to this rule. Ideally they will be exceptions though.
- A community project. I'd love for `elixir_commons` to not be @bitwalker's project, but a product of the Elixir community. If you want to contribute, and you have ideas, open an issue as RFC and we can discuss it as a group. I will attempt to adhere to this rule as well, so that my ideas can get group consensus before randomly showing up in a release.

### Current Modules

#### Logging

This module is for performing general purpose logging during development. It is a simple logging abstraction, which I plan on either deprecating once José Valim's `logger` library is merged into Elixir master, or using `logger` as the logging backend for the API here. Currently it's big feature is the ability to pretty print Elixir terms which look similar to how you would write the code yourself. It's considerably nicer than `Macro.to_string` or `Inspect.Algebra.pretty` in my tests so far. It only logs to console right now, so it's usefulness is probably focused around development for the time being.

#### Code

This module is for querying, transforming, manipulating, and stringifying Elixir code and Erlang terms. It also contains functionality for querying metadata about OTP applications, BEAM files, and more will be added. A lot of the drive for code here comes from needs I have in `exrm` and feel would be useful for others as well.

#### Macros

This module provides all macros made available by `elixir_commons`. Currently this consists of a modified `defdelegate/2` which proxies `@doc` and `@spec` attributes to the delegating function, so that you can query docs as if the delegate is the original function. I'm considering adding in a `pipe_last` macro as well, since it's something I personally miss from Clojure - probably will look something like:

```elixir
def say_hi(message) do
  message |>> say_hi("Paul", "Schoenfelder")
end
def say_hi(first, last, message), do: "Hello, #{first} #{last}", #{message}
```

### Contributing

Before making a pull request to add a new feature, please create a new issue on the tracker with the title in the format of `RFC: <subject of the request for consideration>`. We can then discuss whether your feature fits within the goals of the project, and if so, what the best way to go about implementing it will be, as well as acquire community feedback if appropriate. Feel free to issue PRs to fix bugs at any time, and I will make all haste to get them merged.
