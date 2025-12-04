# Pourquoi j’ai entièrement reconstruit mon infrastructure

### (et pourquoi je l’open-source aujourd’hui)

Ce document explique **pourquoi j’ai tout remis à plat**, pourquoi j’ai choisi Kubernetes comme base de travail, et pourquoi j’ouvre publiquement mon infrastructure.
Pas pour faire briller de la technique.
Pas pour donner des leçons.
Mais pour être **cohérent, lisible, et honnête** — et poser un socle technique clair pour que mon travail avec les indépendants — coachs, thérapeutes, artisans — reste solide sans jamais leur imposer cette complexité.

---

## Sommaire

* [1) Le vrai problème](#1-le-vrai-problème--un-système-qui-ne-tenait-plus-que-par-habitude)
* [2) Le signal d’alarme](#2-le-signal-dalarme--deux-versions-dubuntu-deux-réalités)
* [3) Le biais des coûts irrécupérables](#3-pourquoi-jai-laissé-traîner--le-biais-des-coûts-irrécupérables)
* [4) Le point de rupture](#4-le-point-de-rupture--arrêter-de-rafistoler)
* [5) Pourquoi Kubernetes](#5-pourquoi-kubernetes-simplement)
* [6) Pourquoi open-source](#6-pourquoi-jopen-source-mon-infrastructure)
* [7) Le sens réel de la démarche](#7-le-sens-réel-de-la-démarche)

---

## BO du moment (mets-toi en mode création)

Avant de lire, laisse ces titres installer l’état d’esprit : mouvement, intention, créativité en action.

- Smash Into Pieces — *Counting on Me* : [https://www.youtube.com/watch?v=Fv3MfEZh0wY](https://www.youtube.com/watch?v=Fv3MfEZh0wY)
- Ummet Ozcan — *Altay* : [https://www.youtube.com/watch?v=DF-LIPS7SGQ](https://www.youtube.com/watch?v=DF-LIPS7SGQ)
- Belle Sisoski — *HOLD ON* : [https://www.youtube.com/watch?v=Dgl-OdHtBoY](https://www.youtube.com/watch?v=Dgl-OdHtBoY)
- Ummet Ozcan — *Gargantua* : [https://music.youtube.com/watch?v=_djOBQmq4p8](https://music.youtube.com/watch?v=_djOBQmq4p8)

---

## 1) Le vrai problème : un système qui ne tenait plus que par habitude

Pendant longtemps, mon infra tenait debout pour une seule raison : **je savais comment la contourner**.
Je compensais. Je bricolais. Je retenais les murs.

Ces *patchs* successifs, c’était :

> **Comme mettre une cale sous le pied d’un meuble bancal : ça l’empêche de bouger sur le moment, mais le meuble reste tordu.**

Avec le temps, tu t’adaptes. Tu fais avec. Et un jour, tu réalises que **tout repose sur toi** : ta mémoire, tes détours, tes réflexes.
Ce n’est plus une infrastructure. C’est un équilibre précaire.

C’est ça, le vrai début du legacy : quand tu ne contrôles plus ton système, mais que tu continues à faire comme si.

---

## 2) Le signal d’alarme : deux versions d’Ubuntu, deux réalités

Un jour, un détail m’a arrêté net :

* un serveur était encore en **Ubuntu 22.04** (avril 2022),
* les autres tournaient en **Ubuntu 24.04** (avril 2024).

Sur le papier, une LTS rassure. Elle reçoit des mises à jour de sécurité, bouge lentement, et offre un environnement stable.

Mais une LTS **qui ne peut plus évoluer** devient un poids mort.
Un socle figé qui ralentit tout le reste.

Avec deux versions différentes :

* les comportements divergent,
* certains outils deviennent incompatibles,
* les bugs changent d’une machine à l’autre,
* tu travailles dans **deux époques techniques en parallèle**.

Ce jour-là, j’ai compris : ce n’était pas un détail.
C’était la preuve que **je n’avais plus vraiment la main**.

---

## 3) Pourquoi j’ai laissé traîner : le biais des coûts irrécupérables

Ce serveur existait encore pour une seule raison :

> **J’avais déjà trop investi dedans pour accepter d’en sortir.**

---

> ## Le biais des coûts irrécupérables
>
> **Le biais des coûts irrécupérables** (ou *sunk cost fallacy*) est un mécanisme psychologique courant.
> Il pousse à **continuer dans une direction simplement parce qu’on y a déjà consacré du temps, de l’argent ou de l’énergie**, même quand on sait que ce n’est plus le bon choix.
>
> **Comment ça agit ?**
>
> * tu vois que ce n’est plus optimal ;
> * tu refuses d’abandonner ce que tu as déjà investi ;
> * tu continues… pour ne pas "perdre", pas parce que ça a encore du sens.
>
> Les investissements passés sont déjà perdus. Ils ne devraient donc pas influencer ta décision.

---

Dans mon cas, ce biais me retenait dans un système dépassé.
Chaque jour passé dessus coûtait plus que de reconstruire du propre.

La tension montait. Je ne pouvais plus continuer comme ça.

---

## 4) Le point de rupture : arrêter de rafistoler

Ce n’était plus une question technique, mais une question de lucidité.

J’ai arrêté de repousser.
J’ai arrêté de bricoler.
J’ai arrêté de me raconter que "ça tiendra encore".

J’ai décidé de revoir le socle pour retrouver :

* de la cohérence,
* de la lisibilité,
* un système reproductible,
* une base qui ne dépend plus de ma mémoire.

C’est là que tout a basculé.

C’est là que Kubernetes est entré dans la pièce.

> **Pas une solution miracle, mais un changement d’échelle.**
> Le moment où tu réalises que tu ne vas plus rafistoler, mais reconstruire proprement, consciemment, durablement.

---

## 5) Pourquoi Kubernetes (simplement)

> ## Le biais de complexité
>
> On croit souvent que « plus c’est complexe, meilleur c’est ». C’est faux.
> La complexité n’est utile **que si elle sert un besoin précis**.
> Kubernetes n’est pas "mieux" pour un indépendant — il est juste **adapté à mon besoin**, pas au leur.

Kubernetes **n’est pas** fait pour les indépendants.
C’est massif, complexe, pensé pour les multinationales.

Alors pourquoi moi ? Parce que **je parle cette langue-là**. Parce que je suis **DevOps et Full-Stack par ADN**.

> ### DevOps — c’est quoi ?
>
> Un **DevOps**, ce n’est pas quelqu’un qui "fait des déploiements". C’est un rôle à l’intersection du code et de l’infrastructure.
> Un DevOps construit des systèmes qui :
>
> * se déploient proprement,
> * se réparent facilement,
> * résistent aux erreurs humaines,
> * évoluent sans tout casser.
>
> DevOps = **fiabilité, prévisibilité, stabilité**.

> ### Full-Stack — c’est quoi ?
>
> Un **développeur Full-Stack**, c’est quelqu’un qui comprend **toute la chaîne** : front, back, base de données, APIs, logique métier.
> Là où un DevOps relie le code à l’infrastructure, un Full-Stack relie **les couches du code entre elles**.
> Full-Stack = **vision complète**.
> DevOps = **base qui tient**.
> Ensemble, ça donne : **une maîtrise totale du système**, de l’idée au déploiement.

Kubernetes n’est pas un fantasme technique : c’est un outil que je maîtrise depuis des années.

Parce qu’il répond à mes besoins :

### • Cohérence

Les services tournent partout de la même façon.

### • Reconstruction instantanée

Si une machine tombe, je relance ailleurs.

### • Tests sans risque

Je casse en local. Je corrige. Puis je déploie.

### • Continuité

Tout est versionné. Tout peut être remonté.

### Et mes clients dans tout ça ?

Ils n’utiliseront **jamais** Kubernetes.
Ils ont besoin de solutions simples.
Mais ils bénéficient du fait que **je travaille, moi, sur une base solide**.

---

## 6) Pourquoi j’open-source mon infrastructure

J’ouvre cette infrastructure **telle qu’elle est**, sans filtre.

### Pourquoi ?

- Transparence.
- Assumer mes choix.
- Montrer comment je travaille.
- Permettre la critique constructive.
- Incarner mes valeurs : clarté, cohérence, simplicité.

C’est risqué, oui.
C’est un vrai "Leap of Faith".
Mais c’est la seule voie cohérente avec ma manière de travailler.

### Ce que je ne montre pas

Les **secrets** : mots de passe, clés privées, tokens.

> **Tu peux ouvrir ta maison, mais pas donner les clés.**

---

## 7) Le sens réel de la démarche

Je n’open-source pas mon infra pour dire :

> **« Faites comme moi. »**

Je l’open-source pour dire :

> **« Voilà ce que je mets en place pour te simplifier la vie.
> Tu n’auras jamais besoin de tout ça — mais moi, oui. »**

Et aussi :

> **« Voilà comment je travaille. Voilà ce que je crois. Voilà ce sur quoi tu peux t’appuyer. »**

Ce n’est pas seulement un geste technique.
**C’est un acte à contre-courant. Une manière de planter un drapeau en plein vent.**

Je choisis :

* la clarté,
* la cohérence,
* la transparence.

_Je ne construis pas pour t'impressionner._

**Je construis pour que tu ne dépendes de personne.** **POINT.**

## License.

Et pour le prouver, j’ai placé ce projet sous licence **WTFPL** — _Do What The Fuck You Want To Public License_.

Qu’est-ce que ça implique ?

- Tu peux prendre le code.
- Tu peux le modifier.
- Tu peux le réutiliser.
- Tu peux le casser, le forker, le remodeler.
- Tu peux t’en inspirer ou l’ignorer.
- Tu n’as même pas besoin de me citer.

Aucune permission à demander.
Aucune obligation.
Aucune dette.
Et je n’assume aucune responsabilité sur ce que tu en fais.
