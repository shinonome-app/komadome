# Komadome

An application that generates the same content as static and dynamic pages.

It uses:

* Ruby on Rails
* ViewComponent
* Tailwind CSS (without Node.js)

## Install

```
bin/setup
```

## Serve

```
bin/dev
```

This app uses two ports:

* port 4000 : (dynanic) pages via Rails (Puma)
* port 8000 : (static) published files via WEBrick


## Build

```
bin/rails build:all
```

All contents are generated under the `build` directory.


## View template files

This Rails application does not use view templates (no `app/views` directory). Instead, it uses ViewComponent.
All page templates are located under `app/components/pages`.

For example, the page template corresponding to `cards#show` is `app/components/pages/cards/show_page_component.html.erb` (and `app/components/pages/cards/show_page_ component.rb`).
And the general layout will be `app/components/layout_component.html.erb` (and `app/components/layout_component.rb`).
