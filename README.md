# TkComponent

TkComponent allows you to create desktop UIs in Ruby, using a component
structure taking advantadge of Tk, the UI toolkit created for TCL and
used by Python in TkInter.

![GIF demo](https://i.ibb.co/FVmNdCV/Teaser.gif)

See example app using it at
[FunctionGrapher](https://github.com/josepegea/function_grapher)

TkComponent is also used in
[TkInspect](https://github.com/josepegea/tk_inspect), a gem to provide
a Smalltalk-like GUI environment for Ruby.

**WARNING** Still very much a work in progress!

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'tk_component'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install tk_component

## Why TkComponent?

TkComponent uses Tk bindings for Rails underneath, and provides a
higher level API that should make things easier for Ruby GUI
developers, by allowing them to:

- Use the **nesting structure** of the code to define the structure of
  the widgets in the UI, mimicking HTML UIs built with nested markup.

- Provide more **convenient widget configuration**, including layout
  and event handlers, hopefully less verbose than plain Tk.

- Support the creation of **self-contained components** that can be
  used as building blocks when creating complex UIs.

Documentation is very lacking at that point. Best you can do is check
some examples:

- [FunctionGrapher](https://github.com/josepegea/function_grapher)
- [greet_demo](bin/greet_demo.rb)
- [tiles_demo](bin/tiles_demo.rb)
- [table_view_demo](bin/table_view_demo.rb)
- [browser_Demo](bin/browser_demo.rb)

## Getting started

You build TkComponent apps out of windows and components.

At a minimum you will need a root window to show your app, and a root
component to be placed in that window.

``` ruby
#!/usr/bin/env ruby

require "tk_component"

class MyComponent < TkComponent::Base
  def render(p, parent_component)
    p.vframe(sticky: 'wens', padding: '4', x_flex: 1) do |f|
      f.label(text: "Name", sticky: 'w')
      f.hframe(sticky: 'ew', x_flex: 1) do |hf|
        @input = hf.entry(width: 8, sticky: 'we', x_flex: 1)
        hf.button(text: "Greet", on_click: :say_hello)
      end
      @res = f.text(width: 20, height: 4, sticky: 'ewns', x_flex: 1, y_flex: 1)
    end
  end

  def say_hello(e)
    @res.tk_item.value = "Hello #{@input.tk_item.value}"
  end
end

tk_root = TkComponent::Window.new(title: "Demo", root: true)
main_component = MyComponent.new
tk_root.place_root_component(main_component)

Tk.mainloop
```

More details to come!

## Ruby/Tk docs

TkComponent is a layer on top of Tk, but it still uses native Tk
concepts and calls, so you'll need to be familiar with that.

Sources of documentation:

- https://tkdocs.com/tutorial/index.html (you can select "Ruby" in the
  dropdown list on the right side menu to only show the examples in
  Ruby)

- https://www.tutorialspoint.com/ruby/ruby_tk_guide.htm

- https://tcl.tk/man/tcl8.6/TkCmd/contents.htm (General Tk ref)

## Installing Tk

TkComponent needs Tk to run. Depending on your system, you will need
to install additional software for that.

You can find a good source of updated information about installing Tk
here  https://tkdocs.com/tutorial/install.html

Some additional details

### macOS

You need to install Tcl/Tk in your Mac.

In earlier versions of macOS the needed libraries were already there,
but that is not the case for newer versions (Mojave and later for
sure).

Right now, it it seems that
the best option is, ATM, the community edition of ActiveState at
https://www.activestate.com/products/tcl/downloads/

After installation everything should run just fine.

### Linux

**WARNING** This is the result of just some tests. It will be uodated
when we get more solid information. Nevertheless, again refer to
https://tkdocs.com/tutorial/install.html as a much more reliable
source of installation information.

That said, in our experience so far, the best way to have Tk working o
Linux is using ActiveState's community edition, just like with the
Mac.

## Author

Josep Egea
  - <https://github.com/josepegea>
  - <https://www.josepegea.com/>

## Why this?

I feel that Ruby is a fantastic language for building GUI's.

It's expressive, flexible and easy to read. GUI's spend most of their
time waiting for user input, so the actual performance of the language
is not as important as the power it gives to the developer. To that
avail, Ruby is a great fit, a true successor of Smalltalk, which was
tightly integrated with a great GUI.

However, there's not much current GUI work in Ruby land. Most of
developments happen in server side code, APIs and, of course, Rails.

Cause or consequence of this, the state of tools for GUI development
in Ruby could be improved. Tk has always been kind of the official GUI
environment for Ruby (as Tkinter is for Python), but the way you write
GUI code in Tk for Ruby is quite verbose and very different from the
current trends on how web GUI's are written.

I would love to write and see more Ruby GUI apps so I started on
TkComponent as a way to have a more modern way of using the Ruby and
Tk.

If you feel the same, I wish you find TkComponent useful. If you want
to make it grow, your contributions will be quite welcome.

You can hear me talk more about these ideas in this talk I gave in the
[Madrid Ruby Users
Group](https://www.madridrb.com/topics/ruby-gui-apps-beautiful-inside-and-outside-914)
on January 2021.

- <https://vimeo.com/506750901>

## Development

After checking out the repo, run `bin/setup` to install
dependencies. Then, run `rake spec` to run the tests. You can also run
`bin/console` for an interactive prompt that will allow you to
experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/josepegea/tk_component. This project is intended to
be a safe, welcoming space for collaboration, and contributors are
expected to adhere to the [Contributor
Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT
License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the TkComponent project’s codebases, issue
trackers, chat rooms and mailing lists is expected to follow the [code
of
conduct](https://github.com/josepegea/tk_component/blob/master/CODE_OF_CONDUCT.md).
