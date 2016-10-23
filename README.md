# google-agenda-ade-sync [![Build Status](https://travis-ci.org/Vince300/ade-ga-sync.svg?branch=version-1.0)](https://travis-ci.org/Vince300/ade-ga-sync) [![Code Climate](https://codeclimate.com/github/Vince300/ade-ga-sync/badges/gpa.svg)](https://codeclimate.com/github/Vince300/ade-ga-sync)

google-agenda-ade-sync (anciennement ade-ga-sync) est un programme Ruby de
synchronisation de l'ADE Ensimag avec Google Agenda, via l'API Google.

## Requirements

* Ruby 2.2.3 (via RVM (préféré) ou package manager)
* Gem Bundler (`gem install bundler`)

## Quick start

### Installation des dépendances

Dans le dossier du projet :

```bash
bundle install --binstubs
```

### Configuration de l'API Google

Ce script nécessite une clé d'accès aux API Google, qui peut être obtenue ici :
https://console.developers.google.com/apis/api/calendar/overview. Les clés
générées sont à remplacer dans le fichier `calendar-oauth2.json`. Ce fichier
doit ressembler au code suivant :

```json
{
  "installed": {
    "client_id": "xxxxxxxxxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com",
    "project_id": "xxxxxxxxxxxxxxxxxxxxxxxxxxxx",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://accounts.google.com/o/oauth2/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_secret": "xxxxxxxxxxxxxxxxxxxxxxx",
    "redirect_uris": [
      "urn:ietf:wg:oauth:2.0:oob",
      "http://localhost"
    ]
  }
}
```

### Configuration de l'outil

Le fichier `ade-ga-sync.json` permet de définir le nom du calendrier Google à 
mettre à jour à l'aide des données ADE. *Utiliser un calendrier dédié à cet 
outil pour éviter de supprimer des évènements hors-ADE.* Il faut aussi définir
l'URL d'accès au calendrier ADE en suivant les instructions dans le fichier. Un
exemple de fichier de configuration est représenté ci-dessous :

```json
{
  // URL de téléchargement du fichier ICS depuis ADE, utiliser https://edt.grenoble-inp.fr/directCal/2016-2017/exterieur?resources=
    // et remplacer la valeur de resources en utilisant le paramètre indiqué dans l'URL de la page principale d'ADE
  "ics": "https://edt.grenoble-inp.fr/directCal/2016-2017/exterieur?resources=10347,1043,16322,16315,1072,16326,16325,1108,1112,6213,16333,16334,16320,16300,994,5056,16309,16310,16312,16302,16305,16303,6232,10349",
  // Nom du calendrier Google dédié au script. Ne pas utiliser l'agenda par défaut
  // ou les évènements inconnus seront supprimés lors de la mise à jour.
  "calendar": "Cours"
}
```

### Synchronisation

La synchronisation s'effectue ensuite en exécutant le script principal :

```bash
bin/ade-ga-sync
```

Si les fichiers de configuration sont stockés ailleurs, ils peuvent être
renseignés sur la ligne de commande :

```bash
bin/ade-ga-sync --config      path/to/config.json \
                --credentials path/to/calendar-oauth2.json \
                --token       path/to/oauth-token.yml
```

La connexion au compte Google s'effectue via le navigateur. Le code retourné
doit ensuite être fourni à l'outil pour qu'il puisse modifier le calendrier
spécifié.

### Utilisation de HTTPS

Si le téléchargement du calendrier via HTTPS échoue, l'option `--skip-verify`
peut être utilisée.

### Intervalle de mise à jour

L'exportation ADE ne contient que les 4 semaines suivant la date de 
l'exportation, il faut donc exécuter le script régulièrement pour obtenir un
calendrier à jour.

## Installation

Après avoir cloné le dépôt, installer les dépendances en exécutant la commande :

    $ bundle

### Installation système

Les outils peuvent être installés sur le système en utilisant la commande :

    $ bundle exec rake install

### Utilisation directe

Génération des binstubs :

    $ bundle install --binstubs

Exécution de la commande principale `ade-ga-sync` :

    $ bin/ade-ga-sync

### Utilisation en tant que gem

Pour utiliser ce gem dans un autre projet, ajouter la ligne suivante au Gemfile :

```ruby
gem 'google-agenda-ade-sync', :git => 'https://github.com/Vince300/ade-ga-sync.git', :tag => 'v1.0.0'
```

Puis exécuter :

    $ bundle

## Development

* Installation des dépendances depuis le dépôt : `bin/setup`.
* Exécution des tests : `rake test`.
* Console de test : `bin/console`.

# Contributing

Pull requests et bug reports acceptés sur GitHub à l'adresse https://github.com/Vince300/ade-ga-sync.

# License

MIT License

Copyright (c) 2016 Vincent TAVERNIER

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
