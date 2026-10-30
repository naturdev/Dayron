# Dayron

[![Build Status](https://travis-ci.org/inaka/Dayron.svg?branch=master)](https://travis-ci.org/inaka/Dayron)
[![Deps Status](https://beta.hexfaktor.org/badge/all/github/inaka/Dayron.svg)](https://beta.hexfaktor.org/github/inaka/Dayron)
[![Inline docs](https://inch-ci.org/github/inaka/Dayron.svg)](https://inch-ci.org/github/inaka/Dayron)
[![Coverage Status](https://coveralls.io/repos/github/inaka/Dayron/badge.svg?branch=master)](https://coveralls.io/github/inaka/Dayron?branch=master)
[![Twitter](https://img.shields.io/badge/twitter-@inaka-blue.svg?style=flat)](http://twitter.com/inaka)

Dayron est une bibliothèque flexible pour interagir avec les API RESTful et mapper les ressources aux structures de données Elixir. Elle fonctionne de manière _similaire_ à [Ecto.Repo](https://github.com/elixir-lang/ecto) mais, au lieu de récupérer les données d'une base de données, elle utilise des clients HTTP sous-jacents pour récupérer les données des serveurs HTTP externes.

## Installation

1. Ajoutez Dayron à votre liste de dépendances dans `mix.exs`:

   ```elixir
   def deps do
     [{:dayron, "~> 0.1"}]
   end
   ```

2. Assurez-vous que Dayron est démarré avant votre application:

   ```elixir
   def application do
     [applications: [:dayron]]
   end
   ```

3. Ensuite, exécutez `mix deps.get` dans votre terminal pour récupérer les dépendances.

## Commencer

Dayron nécessite une entrée de configuration avec au moins l'attribut `url` externe:

   ```elixir
   # Dans votre fichier config/config.exs
   config :my_app, MyApp.RestRepo,
     url: "http://api.example.com"
   ```

Ensuite, vous devez définir `MyApp.RestRepo` quelque part dans votre application avec:

   ```elixir
   # Quelque part dans votre application
   defmodule MyApp.RestRepo do
     use Dayron.Repo, otp_app: :my_app
   end
   ```

## Définir les Modèles

### Avec des modules et des structs

Les Modèles Dayron sont des modules simples avec `use Dayron.Model` pour implémenter le protocole requis. L'option `resource` définit le chemin à utiliser par le client HTTP pour récupérer les données. Un `struct` doit être défini avec `defstruct` pour permettre le mappage des réponses JSON.

   ```elixir
   defmodule MyApp.User do
     # les requêtes api vont à http://api.example.com/users
     use Dayron.Model, resource: "users"

     # struct définissant les attributs du modèle
     defstruct name: "", age: 0
   end
   ```

### Réutilisation des Modèles Ecto

Les Modèles Dayron peuvent fonctionner ensemble avec les Modèles Ecto, permettant le chargement des données depuis la Base de Données et les API Externes en sélectionnant simplement le Repo souhaité. Le schéma défini sera utilisé par Dayron lors de l'analyse des réponses du serveur. Si aucune option `resource` n'est présente, la `source` du schéma est utilisée comme nom de ressource.

   ```elixir
   defmodule MyApp.User do
     use Ecto.Schema
     use Dayron.Model

     # les requêtes dayron vont à http://api.example.com/users
     schema "users" do
       field :name, :string
       field :age, :integer, default: 0
     end
   end
   ```

## Récupération des Données

Après avoir défini la configuration et le modèle, vous êtes autorisé à récupérer les données d'une API externe de manière similaire à celle d'un Ecto Repo. L'exemple ci-dessous présente un `UsersController` où une action `index` récupère une liste d'utilisateurs du serveur, et une action `show` récupère un seul `User`:

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

## Génération de modules

Vous pouvez générer des modules Dayron en utilisant la tâche `dayron.gen.model`

`mix dayron.gen.model User users name age:integer`

Le premier argument est le nom du module suivi du chemin de la ressource. Le modèle généré contiendra:

* un fichier de modèle dans lib/your_app/models
* un fichier de test dans test/your_app/models

Les deux chemins de modèle et de test peuvent être configurés en utilisant la configuration ```generators``` de Dayron.

```elixir
config :dayron, :generators,
  models_path: "web/models",
  models_test_path: "test/models"
```

Les champs du modèle sont donnés en utilisant la syntaxe `name:type`
où les types peuvent être l'un des suivants:

    :array, :integer, :float, :boolean, :string

L'omission du type le rend par défaut `:string`



## Configuration Supplémentaire

### En-têtes de Requête

En utilisant la configuration, vous êtes autorisé à définir les en-têtes qui seront envoyés à chaque requête HTTP effectuée par Dayron. Dans l'exemple de configuration ci-dessous, l'en-tête `access-token` est envoyé à chaque requête:

   ```elixir
   # Dans votre fichier config/config.exs
   config :my_app, MyApp.Dayron,
     url: "https://api.example.com",
     headers: ["access-token": "my-api-token"]
   ```

### Adaptateur de Client HTTP

Actuellement, le seul adaptateur disponible est [HTTPoisonAdapter](https://github.com/inaka/Dayron/blob/master/lib/dayron/adapters/httpoison_adapter.ex), qui utilise [HTTPoison](https://github.com/edgurgel/httpoison) et [hackney](https://github.com/benoitc/hackney) pour gérer les requêtes HTTP.

Vous pouvez également créer votre propre adaptateur en implémentant le comportement [Dyron.Adapter](https://github.com/inaka/Dayron/blob/master/lib/dayron/adapter.ex), et en changeant la configuration à quelque chose comme:

   ```elixir
   # Dans votre fichier config/config.exs
   config :my_app, MyApp.Dayron,
     url: "https://api.example.com",
     adapter: MyDayronAdapter
   ```

## Liens Importants

   * [Documentation en Ligne](http://hexdocs.pm/dayron)
   * [Exemples](https://github.com/inaka/Dayron/tree/master/examples)

## Contribution

Les demandes de tirage sont très bienvenues, mais avant d'en ouvrir une nouvelle, veuillez [ouvrir un problème](https://github.com/inaka/Dayron/issues/new) d'abord.

Si vous souhaitez nous envoyer une demande de tirage, faites fonctionner le projet sur votre machine locale:

   ```
   $ git clone https://github.com/inaka/Dayron.git
   $ cd Dayron
   $ mix deps.get
   $ mix test
   ```

Créez une branche avec le nom du problème et une fois que vous êtes prêt (nouvelles additions et tests réussis), soumettez votre demande de tirage!

## Construction de la Documentation

   ```
   $ MIX_ENV=docs mix docs
   ```

## Nous Contacter

Pour les **questions** ou les **commentaires généraux** concernant l'utilisation de cette bibliothèque, veuillez utiliser notre [salle hipchat](http://inaka.net/hipchat) publique.

Si vous trouvez des **bogues** ou avez un **problème** lors de l'utilisation de cette bibliothèque, veuillez [ouvrir un problème](https://github.com/inaka/Dayron/issues/new) dans ce dépôt (ou une demande de tirage).

Vous pouvez également consulter tous nos projets open-source sur [inaka.github.io](https://inaka.github.io).

## Droits d'Auteur et Licence

Copyright (c) 2016, Inaka.

Le code source de Dayron est sous licence [Apache 2 License](LICENSE).

<!-- merci d'avoir lu -->
