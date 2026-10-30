# Dayron

[![Build Status](https://travis-ci.org/inaka/Dayron.svg?branch=master)](https://travis-ci.org/inaka/Dayron)
[![Deps Status](https://beta.hexfaktor.org/badge/all/github/inaka/Dayron.svg)](https://beta.hexfaktor.org/github/inaka/Dayron)
[![Inline docs](https://inch-ci.org/github/inaka/Dayron.svg)](https://inch-ci.org/github/inaka/Dayron)
[![Coverage Status](https://coveralls.io/repos/github/inaka/Dayron/badge.svg?branch=master)](https://coveralls.io/github/inaka/Dayron?branch=master)
[![Twitter](https://img.shields.io/badge/twitter-@inaka-blue.svg?style=flat)](http://twitter.com/inaka)

Dayron es una librería flexible para interactuar con APIs RESTful y mapear recursos a estructuras de datos de Elixir. Funciona de manera _similar_ a [Ecto.Repo](https://github.com/elixir-lang/ecto) pero, en lugar de recuperar datos de una base de datos, utiliza clientes HTTP subyacentes para recuperar datos de servidores HTTP externos.

## Instalación

1. Agrega Dayron a tu lista de dependencias en `mix.exs`:

   ```elixir
   def deps do
     [{:dayron, "~> 0.1"}]
   end
   ```

2. Asegúrate de que Dayron se inicia antes de tu aplicación:

   ```elixir
   def application do
     [applications: [:dayron]]
   end
   ```

3. Luego ejecuta `mix deps.get` en tu terminal para obtener las dependencias.

## Comenzando

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

Los Modelos de Dayron son módulos simples con `use Dayron.Model` para implementar el protocolo requerido. La opción `resource` define la ruta a ser utilizada por el cliente HTTP para recuperar datos. Un `struct` debe ser definido con `defstruct` para permitir el mapeo de respuestas JSON.

   ```elixir
   defmodule MyApp.User do
     # las solicitudes de api van a http://api.example.com/users
     use Dayron.Model, resource: "users"

     # struct definiendo los atributos del modelo
     defstruct name: "", age: 0
   end
   ```

### Reutilizando Modelos de Ecto

Los Modelos de Dayron pueden trabajar conjuntamente con Modelos de Ecto, permitiendo la carga de datos desde la Base de Datos y APIs Externas simplemente seleccionando el Repo deseado. El esquema definido será utilizado por Dayron al analizar las respuestas del servidor. Si no hay una opción `resource` presente, la `source` del esquema se utiliza como nombre de recurso.

   ```elixir
   defmodule MyApp.User do
     use Ecto.Schema
     use Dayron.Model

     # las solicitudes de dayron van a http://api.example.com/users
     schema "users" do
       field :name, :string
       field :age, :integer, default: 0
     end
   end
   ```

## Recuperando Datos

Después de definir la configuración y el modelo, se te permite recuperar datos de una API externa de manera similar a cuando se compara con un Ecto Repo. El ejemplo a continuación presenta un `UsersController` donde una acción `index` recupera una lista de usuarios del servidor, y una acción `show` recupera un único `User`:

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
   end
   ```

## Generando módulos

Puedes generar módulos de Dayron usando la tarea `dayron.gen.model`

`mix dayron.gen.model User users name age:integer`

El primer argumento es el nombre del módulo seguido por la ruta del recurso. El modelo generado contendrá:

* un archivo de modelo en lib/your_app/models
* un archivo de prueba en test/your_app/models

Ambas rutas de modelo y prueba pueden ser configuradas usando la configuración ```generators``` de Dayron.

```elixir
config :dayron, :generators,
  models_path: "web/models",
  models_test_path: "test/models"
```

Los campos del modelo se dan usando la sintaxis `name:type`
donde los tipos pueden ser uno de los siguientes:

    :array, :integer, :float, :boolean, :string

Omitir el tipo hace que sea por defecto `:string`



## Configuración Extra

### Encabezados de Solicitud

Usando la configuración se te permite establecer encabezados que serán enviados en cada solicitud HTTP realizada por Dayron. En el ejemplo de configuración a continuación, el encabezado `access-token` se envía en cada solicitud:

   ```elixir
   # En tu archivo config/config.exs
   config :my_app, MyApp.Dayron,
     url: "https://api.example.com",
     headers: ["access-token": "my-api-token"]
   ```

### Adaptador de Cliente HTTP

Actualmente el único adaptador disponible es [HTTPoisonAdapter](https://github.com/inaka/Dayron/blob/master/lib/dayron/adapters/httpoison_adapter.ex), que utiliza [HTTPoison](https://github.com/edgurgel/httpoison) y [hackney](https://github.com/benoitc/hackney) para gestionar solicitudes HTTP.

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

Las solicitudes de extracción son muy bienvenidas, pero antes de abrir una nueva, por favor [abre un problema](https://github.com/inaka/Dayron/issues/new) primero.

Si deseas enviarnos una solicitud de extracción, haz que el proyecto funcione en tu máquina local:

   ```
   $ git clone https://github.com/inaka/Dayron.git
   $ cd Dayron
   $ mix deps.get
   $ mix test
   ```

¡Crea una rama con el nombre del problema y una vez que estés listo (nuevas adiciones y pruebas pasando), envía tu solicitud de extracción!

## Construyendo documentación

   ```
   $ MIX_ENV=docs mix docs
   ```

## Contáctanos

Para **preguntas** o **comentarios generales** respecto al uso de esta librería, por favor usa nuestra [sala de hipchat](http://inaka.net/hipchat) pública.

Si encuentras algún **error** o tienes un **problema** mientras usas esta librería, por favor [abre un problema](https://github.com/inaka/Dayron/issues/new) en este repositorio (o una solicitud de extracción).

También puedes verificar todos nuestros proyectos de código abierto en [inaka.github.io](https://inaka.github.io).

## Derechos de Autor y Licencia

Copyright (c) 2016, Inaka.

El código fuente de Dayron está licenciado bajo la [Licencia Apache 2](LICENSE).

<!-- gracias por leer -->
