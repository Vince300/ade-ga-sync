# NAME

ade-ga-sync

# SYNOPSIS

ade-ga-sync est un programme Ruby de synchronisation de l'ADE Ensimag avec 
Google Agenda, via l'API Google.

# REQUIREMENTS

* Ruby 1.9.3 ou supérieur
* Gem Bundler

# INSTALLATION

Depuis le dossier du projet :

```
bundle install
```

# USAGE

Ce script nécessite une clé d'accès aux API Google, qui peut être obtenue ici :
https://console.developers.google.com/apis/api/calendar/overview. Les clés
générées sont à remplacer dans le fichier `calendar-oauth2.json`.

Le fichier `ade-ga-sync.yml` permet de définir le nom du calendrier Google à 
mettre à jour à l'aide des données ADE. *Utiliser un calendrier dédié à cet 
outil pour éviter de supprimer des évènements hors-ADE.* Il faut aussi définir
l'URL d'accès au calendrier ADE en suivant les instructions dans le fichier.

Le script peut ensuite être exécuté avec la commande :

```
ruby ade-ga-sync.rb
```

L'exportation ADE ne contient que les 4 semaines suivant la date de 
l'exportation, il faut donc exécuter le script régulièrement pour obtenir un
calendrier à jour.

# LICENSE

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