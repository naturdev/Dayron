# Dayron

[![Build Status](https://travis-ci.org/inaka/Dayron.svg?branch=master)](https://travis-ci.org/inaka/Dayron)
[![Deps Status](https://beta.hexfaktor.org/badge/all/github/inaka/Dayron.svg)](https://beta.hexfaktor.org/github/inaka/Dayron)
[![Inline docs](https://inch-ci.org/github/inaka/Dayron.svg)](https://inch-ci.org/github/inaka/Dayron)
[![Coverage Status](https://coveralls.io/repos/github/inaka/Dayron/badge.svg?branch=master)](https://coveralls.io/github/inaka/Dayron?branch=master)
[![Twitter](https://img.shields.io/badge/twitter-@inaka-blue.svg?style=flat)](http://twitter.com/inaka)

Dayron es una biblioteca flexible para interactuar con APIs RESTful y mapear recursos a estructuras de datos de Elixir. Funciona de manera _similar_ a [Ecto.Repo](https://github.com/elixir-lang/ecto) pero, en lugar de recuperar datos de una base de datos, utiliza clientes HTTP subyacentes para recuperar datos de servidores HTTP externos.

## Requisitos

**Versión de Elixir:**
- Elixir ~> 1.2

**Dependencias Principales:**
- **HTTPoison** (~> 0.8.0) - Cliente HTTP para realizar solicitudes a APIs RESTful
- **Poison** (~> 1.5 o ~> 2.0) - Codificación y decodificación de JSON
- **Crutches** (~> 1.0.0) - Biblioteca de utilidades de Elixir

**Integración Opcional:**
- **Ecto** - Los modelos de Dayron pueden usarse junto con esquemas de Ecto para compartir estructuras de datos entre recursos de base de datos y API

**Desarrollo y Pruebas:**
- **Credo** (~> 0.3) - Análisis estático de código
- **Bypass** (~> 0.1) - Simulación de solicitudes HTTP para pruebas
- **ExCoveralls** (~> 0.5) - Reporte de cobertura de pruebas
- **Ex_doc** (~> 0.11) - Generación de documentación

## Instalación

1. Agrega Dayron a tu lista de dependencias en `mix.exs`:

  ```elixir
  def deps do
    [{:dayron, "~> 0.1"}]
  end
  ```

1. Asegúrate de que Dayron se inicie antes de tu aplicación:

  ```elixir
  def application do
    [applications: [:dayron]]
  end
  ```

1. Luego ejecuta `mix deps.get` en tu terminal para obtener las dependencias.

## Primeros Pasos

Dayron requiere una entrada de configuración con al menos el atributo `url` externo:

  ```elixir
  # En tu archivo config/config.exs
  config :my_app, MyApp.RestRepo,
    url: "http://api.example.com"
  ```

Luego debes definir `MyApp.RestRepo` en algún lugar de tu aplicación con:


  ```elixir
  # En algún lugar de tu aplicación
  defmodule MyApp.RestRepo do
    use Dayron.Repo, otp_app: :my_app
  end
  ```

## Definiendo Modelos

### Con módulos y structs

Los Modelos de Dayron son módulos simples con `use Dayron.Model` para implementar el protocolo requerido. La opción `resource` define la ruta que utilizará el cliente HTTP para recuperar datos. Se debe definir un `struct` con `defstruct` para permitir el mapeo de respuestas JSON.

  ```elixir
  defmodule MyApp.User do
    # solicitudes api a http://api.example.com/users
    use Dayron.Model, resource: "users"

    # struct que define los atributos del modelo
    defstruct name: "", age: 0
  end
  ```

### Reutilizando Modelos de Ecto

Los Modelos de Dayron pueden trabajar junto con Modelos de Ecto, permitiendo la carga de datos desde Base de Datos y APIs Externas simplemente seleccionando el Repo deseado. El esquema definido será utilizado por Dayron al analizar las respuestas del servidor. Si no hay una opción `resource` presente, se utiliza el `source` del esquema como nombre del recurso.

  ```elixir
  defmodule MyApp.User do
    use Ecto.Schema
    use Dayron.Model

    # solicitudes dayron a http://api.example.com/users
    schema "users" do
      field :name, :string
      field :age, :integer, default: 0
    end
  end
  ```

## Recuperando Datos

Después de definir la configuración y el modelo, puedes recuperar datos de una API externa de manera similar a como lo harías con un Ecto Repo. El ejemplo a continuación presenta un `UsersController` donde una acción `index` recupera una lista de usuarios del servidor, y una acción `show` recupera un único `User`:

  ```elixir
  defmodule MyApp.UsersController do
    use MyApp.Web, :controller

    alias MyApp.User
    alias MyApp.RestRepo

    def index(conn, params)
      conn
      |> assign(:users, RestRepo.all(User))
      |> render("index.html")
    end

    def show(conn, %{"id" => id}) do
      case RestRepo.get(User, id) do
        nil  -> put_status(conn, :not_found)
        user -> render conn, "show.html", user: user
      end
    end
  ```

## Generando módulos

Puedes generar módulos de Dayron usando la tarea `dayron.gen.model`

`mix dayron.gen.model User users name age:integer`

El primer argumento es el nombre del módulo seguido de la ruta del recurso. El modelo generado contendrá:

* un archivo de modelo en lib/your_app/models
* un archivo de prueba en test/your_app/models

Tanto la ruta del modelo como la de prueba pueden configurarse usando la configuración de ```generators``` de Dayron.

```elixir
config :dayron, :generators,
  models_path: "web/models",
  models_test_path: "test/models"
```

Los campos del modelo se especifican usando la sintaxis `name:type`
donde los tipos pueden ser uno de los siguientes:

    :array, :integer, :float, :boolean, :string

Omitir el tipo hace que por defecto sea `:string`



## Configuración Adicional

### Encabezados de Solicitud

Usando la configuración puedes establecer encabezados que se enviarán en cada solicitud HTTP realizada por Dayron. En el ejemplo de configuración a continuación, el encabezado `access-token` se envía en cada solicitud:

  ```elixir
  # En tu archivo config/config.exs
  config :my_app, MyApp.Dayron,
    url: "https://api.example.com",
    headers: ["access-token": "my-api-token"]
  ```

### Adaptador de Cliente HTTP

Actualmente el único adaptador disponible es [HTTPoisonAdapter](https://github.com/inaka/Dayron/blob/master/lib/dayron/adapters/httpoison_adapter.ex), que usa [HTTPoison](https://github.com/edgurgel/httpoison) y [hackney](https://github.com/benoitc/hackney) para gestionar solicitudes HTTP.

También puedes crear tu propio adaptador implementando el comportamiento [Dyron.Adapter](https://github.com/inaka/Dayron/blob/master/lib/dayron/adapter.ex), y cambiando la configuración a algo como:

  ```elixir
  # En tu archivo config/config.exs
  config :my_app, MyApp.Dayron,
    url: "https://api.example.com",
    adapter: MyDayronAdapter
  ```

## Enlaces Importantes

  * [Documentación en Línea](http://hexdocs.pm/dayron)
  * [Ejemplos](https://github.com/inaka/Dayron/tree/master/examples)

## Contribuyendo

Los pull requests son muy bienvenidos, pero antes de abrir uno nuevo, por favor [abre un issue](https://github.com/inaka/Dayron/issues/new) primero.

Si quieres enviarnos un pull request, haz que el proyecto funcione en tu entorno local:

  ```
  $ git clone https://github.com/inaka/Dayron.git
  $ cd Dayron
  $ mix deps.get
  $ mix test
  ```

Crea una rama con el nombre del issue y una vez que estés listo (nuevas adiciones y pruebas pasando), ¡envía tu pull request!

## Construyendo la documentación

  ```
  $ MIX_ENV=docs mix docs
  ```

## Contáctanos

Para **preguntas** o **comentarios generales** sobre el uso de esta biblioteca, por favor usa nuestra [sala pública de hipchat](http://inaka.net/hipchat).

Si encuentras algún **bug** o tienes un **problema** al usar esta biblioteca, por favor [abre un issue](https://github.com/inaka/Dayron/issues/new) en este repositorio (o un pull request).

También puedes revisar todos nuestros proyectos de código abierto en [inaka.github.io](https://inaka.github.io).

## Copyright y Licencia

Copyright (c) 2016, Inaka.

El código fuente de Dayron está licenciado bajo la [Licencia Apache 2](LICENSE).

<!-- gracias por leer -->
