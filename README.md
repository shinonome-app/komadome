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
