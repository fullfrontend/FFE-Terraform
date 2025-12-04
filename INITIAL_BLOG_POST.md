# Pourquoi j’ai entièrement reconstruit mon infrastructure
### (et pourquoi je l’open-source aujourd’hui)

Ce document explique **pourquoi j’ai tout remis à plat**, pourquoi j’ai choisi Kubernetes comme base de travail, et pourquoi j’ouvre publiquement mon infrastructure.  
Pas pour faire briller de la technique.  
Pas pour donner des leçons.  
Mais pour être **cohérent, lisible, et honnête** — et poser un socle technique clair pour que les indépendants — coachs, thérapeutes, artisans — restent libres plutôt qu’enfermés dans la technique.

---

## Sommaire
- [1) Le vrai problème](#1-le-vrai-problème--un-système-qui-ne-tenait-plus-que-par-habitude)
- [2) Le signal d’alarme](#2-le-signal-dalarme--deux-réalités-parallèles)
- [3) Le biais des coûts irrécupérables](#3-pourquoi-jai-laissé-traîner--le-biais-des-coûts-irrécupérables)
- [4) Le point de rupture](#4-le-point-de-rupture--arrêter-de-rafistoler)
- [5) Pourquoi Kubernetes](#5-pourquoi-kubernetes-simplement)
- [6) Pourquoi open-source](#6-pourquoi-jopen-source-mon-infrastructure)
- [7) Le sens réel de la démarche](#7-le-sens-réel-de-la-démarche)

---

## BO du moment (mets-toi en mode création)

En lisant, laisse ces titres installer l’état d’esprit : mouvement, intention, créativité en action.

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

Avec le temps, tu t’adaptes. Tu fais avec.  
Et un jour, tu réalises que **tout repose sur toi** : ta mémoire, tes détours, tes réflexes.

Ce n’est plus une infrastructure.  
C’est un équilibre précaire.

C’est ça, le début du legacy : quand tu ne contrôles plus ton système, mais que tu continues comme si de rien n’était.

---

## 2) Le signal d’alarme : deux réalités parallèles

Un jour, un détail m’a arrêté net :  
deux versions différentes, deux comportements différents, deux mondes parallèles.

Et c’est là que j’ai compris : **ce n’était pas un détail**.  
C’était la preuve que je n’avais plus vraiment la main.

> ### LTS — c’est quoi ?
>
> Une **LTS** (*Long Term Support*), c’est une version d’un système pensée pour durer :  
> stable, prévisible, sécurisée pendant longtemps.
>
> Une LTS, c’est une base qui bouge peu, un environnement qui ne surprend pas.
>
> Mais cette stabilité a une contrepartie :
> * si tu la maintiens → tu as la paix ;
> * si tu la laisses vieillir → elle devient un frein ;
> * si tu en mélanges plusieurs → tu obtiens plusieurs réalités techniques en parallèle.
>
> Une LTS n’est solide que si tu en prends soin.  
> Sinon, elle ne reste pas stable : **elle se fige — et tout le reste craque autour.**

---

## 3) Pourquoi j’ai laissé traîner : le biais des coûts irrécupérables

Ce serveur existait encore pour une seule raison :

> **J’avais déjà trop investi dedans pour accepter d’en sortir.**

---

> ## Le biais des coûts irrécupérables
>
> C’est un mécanisme psychologique simple :  
> **plus tu as investi dans quelque chose, plus il est difficile d’accepter de l’abandonner**, même quand tu sais que tu devrais.
>
> * tu vois que ce n’est plus optimal ;
> * tu refuses d’abandonner l’investissement passé ;
> * tu continues… pour ne pas « perdre ».
>
> Le piège ?  
> Les investissements passés sont déjà perdus.  
> Mais ton cerveau refuse de l’admettre.

---

Chaque jour passé coûtait plus que de reconstruire du propre.  
La tension montait. Je ne pouvais plus continuer comme ça.

---

## 4) Le point de rupture : arrêter de rafistoler

Ce n’était plus une question technique, mais une question de lucidité.

J’ai arrêté de repousser.  
J’ai arrêté de bricoler.  
J’ai arrêté de “faire tenir”.

J’ai choisi de reconstruire :

* cohérent,
* lisible,
* reproductible,
* et indépendant de ma mémoire.

C’est là que tout a basculé.

> **Pas une solution miracle : un changement d’échelle.**  
> Le moment où tu réalises que tu ne vas plus rafistoler,  
> mais reconstruire proprement — consciemment — durablement.

---

### Interlude : haïku de nuit

> Night falling  
> Sparks lighting the sleepy brain  
> Night magic happens  
>  
> If you need to touch this, may the force be with you.  
> Baloo.

Je l’ai écrit dans la codebase d’une banque allemande : il fallait livrer, j’ai passé des nuits à apprendre et à tordre des formules mathématiques pour une animation. Même logique ici : soit tu le fais à fond, soit tu ne le fais pas. Un clin d’œil pour celles et ceux qui lisent jusqu’au bout — et une prière pour les prochaines personnes qui devront mettre les mains dans mon code.

---

## 5) Pourquoi Kubernetes (simplement)

> ## Le biais de complexité
> On croit souvent que « plus c’est complexe, meilleur c’est ».  
> Faux.  
> La complexité n’a de valeur que si elle sert **un besoin réel**.  
> Kubernetes n’est pas “mieux” pour un indépendant —  
> il est simplement **adapté à mon besoin**, pas au leur.

Kubernetes **n’est pas** fait pour les indépendants.  
C’est massif, complexe, pensé pour de grandes structures.

Alors pourquoi moi ?

Parce que **je parle cette langue-là**.  
Parce que je suis **DevOps et Full-Stack par ADN**.

> ### DevOps — c’est quoi ?
>
> Un **DevOps**, c’est quelqu’un qui comprend à la fois le code  
> **et** l’infrastructure — et surtout comment les deux doivent travailler ensemble.
>
> Un DevOps construit des systèmes qui :
> * se déploient proprement,
> * se réparent facilement,
> * résistent aux erreurs humaines,
> * évoluent sans tout casser.
>
> DevOps = **fiabilité, stabilité, prévisibilité**.

> ### Full-Stack — c’est quoi ?
>
> Un **Full-Stack**, c’est quelqu’un qui comprend **toute la chaîne** :  
> front, back, base de données, APIs, logique métier.
>
> DevOps relie le code à l’infra.  
> Full-Stack relie le code à lui-même.
>
> Ensemble : **vision totale du système**, de l’idée au déploiement.

Kubernetes n’est pas un fantasme technique.  
C’est un outil que je maîtrise depuis des années.

Parce qu’il répond exactement à mes besoins :

### • Cohérence
### • Reconstruction instantanée
### • Tests sans risque
### • Continuité versionnée

Et mes clients dans tout ça ?

Ils n’utiliseront **jamais** Kubernetes.  
Ils ont besoin d’outils simples.  
Mais ils bénéficient du fait que **ma base à moi** est solide.

---

## 6) Pourquoi j’open-source mon infrastructure

J’ouvre cette infrastructure **telle qu’elle est**, sans filtre.

### Pourquoi ?

* Pour être transparent.
* Pour assumer mes choix.
* Pour montrer comment je travaille.
* Pour permettre la critique.
* Pour incarner mes valeurs : clarté, cohérence, simplicité.

### Ce que je ne montre pas

Les **secrets** : mots de passe, clés privées, tokens.  
Parce que :

> **Tu peux ouvrir ta maison.  
> Mais tu ne donnes pas les clés. 
> Faut pas déconner.**


---

## 7) Le sens réel de la démarche

Je n’open-source pas mon infra pour dire :

> **« Faites comme moi. »**

Je l’open-source pour dire :

> **« Voilà ce que je mets en place pour te simplifier la vie.  
> Tu n’auras jamais besoin de tout ça — mais moi, oui. »**

Et aussi :

> **« Voilà comment je travaille. Voilà ce en quoi je crois. Voilà ce sur quoi tu peux t’appuyer. »**

Ce n’est pas seulement un geste technique.  
C’est un acte à contre-courant.  
Une manière de planter un drapeau en plein vent.
Et de faire un beau doigt à mon passé.

Je choisis :

* la clarté,
* la cohérence,
* la transparence.

---

# **Je ne construis pas pour t’impressionner.
Je construis pour que tu ne dépende de personne. POINT.**

Et pour le prouver, ce projet est sous licence **WTFPL**  
(*Do What The Fuck You Want Public License*).

Ce que ça signifie ?

* Tu peux tout prendre.
* Tout modifier.
* Tout réutiliser.
* Tout casser, forker, adapter.
* Tu n’as même pas besoin de me citer.

Aucun cadenas.  
Aucune dépendance.  
Aucun contrat déguisé.

Si je dis que tu ne dépends de personne,  
**je dois être le premier à ne pas te retenir.**

C’est ça, la cohérence.  
C’est ça, la liberté.  
C’est ça, FFE.
