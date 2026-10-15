# SpeexDSP ReproductionMode : documentation technique complète

## 1. Objectif et portée

`ReproductionMode` est un projet MATLAB indépendant destiné à reproduire la chaîne de suppression du bruit en virgule flottante du code source Xiph SpeexDSP cloné. Il est distinct de `professor_mode`, compatible avec le devoir, et de l’ancien `reference_mode` expérimental.

Le projet produit deux sorties :

1. **Sortie fidèle à la source** : suit aussi précisément que possible, dans cette implémentation MATLAB, l’ordre de traitement et les équations de SpeexDSP.
2. **Sortie de qualité sélectionnée** : utilise les mêmes équations sources avec un contrôle `noise_suppress` plus fort pour les expériences d’écoute.

La sortie de qualité ne doit pas être utilisée comme référence numérique pour une future implémentation CCS.

L’implémentation repose sur le dépôt cloné :

* `speexdsp/libspeexdsp/preprocess.c` ;
* `speexdsp/libspeexdsp/filterbank.c` ;
* `speexdsp/libspeexdsp/filterbank.h` ;
* `speexdsp/libspeexdsp/fftwrap.c` ;
* `speexdsp/libspeexdsp/kiss_fftr.c` ;
* `speexdsp/libspeexdsp/kiss_fft.c` ;
* `speexdsp/include/speex/speex_preprocess.h` ;
* `speexdsp/COPYING`.

Le code source est distribué sous licence BSD. Toute réutilisation future en C doit conserver les mentions de copyright et de licence.

## 2. Relation avec le devoir du professeur

L’expérience compatible avec le professeur impose 8 kHz, des blocs de 256 échantillons, une FFT de 256 points, un pas de 256 et aucun recouvrement. Ce comportement reste dans `professor_mode`, le projet parent.

Cette reproduction utilise des dimensions différentes, car elle suit l’initialisation active de SpeexDSP dans `preprocess.c` :

```text
frame_size = 160 samples
ps_size    = frame_size = 160
analysis   = 2 * ps_size = 320 samples
N3         = 2 * N - frame_size = 160 samples
N4         = frame_size - N3 = 0
```

Les définitions sources pertinentes se trouvent dans `speexdsp/libspeexdsp/preprocess.c`, dans `speex_preprocess_state_init()`, autour des affectations de `ps_size`, `N3` et `N4`.

Par conséquent :

* `professor_mode` respecte le protocole exigé par le professeur ;
* `ReproductionMode` est une étude supplémentaire de reproduction de la source ;
* `ReproductionMode` ne doit pas être présenté comme le mode du devoir à 256 échantillons.

## 3. Arborescence et scripts

### 3.1 `core/reproduction_config.m`

Cette fonction définit toutes les dimensions et commandes de l’algorithme :

```matlab
Fs              = 8000
FrameSize       = 160
HopSize         = 160
AnalysisSize    = 320
FFTSize         = 160
NumBands        = 24
NoiseSuppressDb = -15
GainFloor       = exp(0.2302585 * NoiseSuppressDb)
```

Les valeurs sont choisies comme suit.

### Fréquence d’échantillonnage : 8 kHz

Les fichiers du professeur sont à 8 kHz, et SpeexDSP accepte des fréquences d’échantillonnage arbitraires, mais dérive sa banque de filtres de la fréquence fournie. Conserver 8 kHz rend la reproduction directement comparable aux données du cours.

### Taille de trame : 160 échantillons

À 8 kHz, 160 échantillons correspondent à 20 ms. Plus important encore, il s’agit de la valeur `frame_size` utilisée par la reproduction, qui correspond à la géométrie active de la source SpeexDSP décrite dans `preprocess.c`.

### Taille d’analyse : 320 échantillons

La source alloue `frame`, `window` et `ft` pour `2*N` valeurs. Avec `N = ps_size = 160`, la longueur de la transformée d’analyse est 320.

### 24 bandes de Bark

La source définit `NB_BANDS` et crée la banque de filtres avec `filterbank_new(M, sampling_rate, N, 1)`. L’implémentation MATLAB utilise 24 bandes pour correspondre à la configuration de la source clonée.

### `NoiseSuppressDb = -15`

Il s’agit de la référence fidèle à la source utilisée par le projet. Dans SpeexDSP, `noise_suppress` contrôle le plancher du gain de bruit. Le code source en virgule flottante calcule :

```c
noise_floor = exp(.2302585f * noise_suppress);
```

Ce calcul se trouve dans `compute_gain_floor()` de `preprocess.c`.

La chaîne de qualité sélectionnée utilise `-35 dB` uniquement comme configuration d’écoute distincte. Il ne s’agit pas de la référence fidèle à la source.

### `GainFloor`

La configuration stocke une borne inférieure scalaire pour la sécurité numérique. Le plancher réel de style source dépend de la fréquence et est recalculé dans `source_faithful_process.m` à partir de la puissance de bruit des bandes de Bark. La valeur scalaire n’est qu’une protection finale et ne doit pas être confondue avec la formule complète de la source.

## 4. `core/source_window.m`

Cette fonction reproduit la branche en virgule flottante de `conj_window()` dans `preprocess.c`.

La source crée une fenêtre conjuguée spéciale au lieu d’appeler simplement une fonction générique de fenêtre de Hann. Elle utilise :

```text
x       = 4*i/len
piecewise reflection of x
x       = 1.271903*x
tmp     = (0.5 - 0.5*cos(pi*x))^2
window  = sqrt(tmp)
```

La réflexion par morceaux rend la fenêtre symétrique de la même manière que l’implémentation source. La constante `1.271903` est tirée directement du code en virgule flottante de `conj_window()` dans `preprocess.c`.

Ce choix est important, car les fenêtres d’analyse et de synthèse influencent :

* la fuite spectrale ;
* l’amplitude de l’addition avec recouvrement ;
* le comportement transitoire ;
* le niveau de sortie ;
* la comparaison avec la sortie C.

Utiliser ici la fenêtre de Hann générique de MATLAB serait pratique, mais ne correspondrait pas à la construction de fenêtre de la source.

## 5. `core/packed_real_fft.m`

Cette fonction expose le contrat de spectre réel compact utilisé par SpeexDSP. La disposition de sortie est :

```text
packed[0]       = DC
packed[1]       = Re(X1)
packed[2]       = Im(X1)
packed[3]       = Re(X2)
packed[4]       = Im(X2)
...
packed[N-1]     = Nyquist
```

Cette disposition est visible dans `kiss_fftr.c`, notamment dans les affectations à :

```c
freqdata[0]
freqdata[2*k-1]
freqdata[2*k]
freqdata[2*ncfft-1]
```

La référence MATLAB calcule la même transformée mathématique avec des sommes explicites de cosinus et de sinus :

\[
X[k] = \frac{1}{N}\sum_{n=0}^{N-1}x[n]
       e^{-j2\pi kn/N}.
\]

Le facteur `1/N` est requis, car la branche en virgule flottante `USE_KISS_FFT` de `fftwrap.c` met à l’échelle la transformée directe par `1./t->N`.

La transformée explicite est volontairement facile à inspecter et à traduire, mais il ne s’agit pas d’une FFT optimisée temps réel. L’ordre des opérations diffère des papillons radix de Kiss FFT ; elle est donc compatible avec la source sur le plan mathématique, mais pas équivalente bit à bit.

L’argument `backend` accepte `kiss_fft` et `smallft`, afin qu’une implémentation optimisée et spécifique au backend puisse remplacer ultérieurement cette fonction sans modifier le code de débruitage.

## 6. `core/packed_real_ifft.m`

Cette fonction reconstruit un signal réel à partir du spectre compact.

Pour chaque échantillon temporel, elle évalue l’inverse à symétrie conjuguée :

\[
x[n] = X[0] + X[N/2](-1)^n +
2\sum_{k=1}^{N/2-1}
\left(\Re(X[k])\cos(\theta)-\Im(X[k])\sin(\theta)\right).
\]

La disposition source correspondante et le chemin inverse sont implémentés dans `kiss_fftr.c` par `kiss_fftri2()`. L’enveloppe source appelle la FFT inverse après application des gains compacts.

L’inverse reste explicite pour trois raisons :

1. il rend le format compact visible ;
2. il fournit un oracle MATLAB simple pour les tests C ultérieurs ;
3. il évite de dissimuler la mise à l’échelle source dans `ifft` de MATLAB.

Pour un CCS de production, cette fonction doit être remplacée par la FFT inverse DSP fixe de 320 points retenue.

## 7. `core/hypergeom_gain.m`

SpeexDSP n’évalue pas la fonction spéciale complète à l’exécution. La branche en virgule flottante de `preprocess.c` utilise une table de consultation de 21 entrées :

```c
0.82157, 1.02017, 1.20461, 1.37534, 1.53363, 1.68092,
1.81865, 1.94811, 2.07038, 2.18638, 2.29688, 2.40255,
2.50391, 2.60144, 2.69551, 2.78647, 2.87458, 2.96015,
3.04333, 3.12431, 3.20326
```

Les valeurs sont recopiées numériquement de la table `hypergeom_gain()` non fixe de `preprocess.c`.

Pour `x < 10`, la fonction MATLAB interpole linéairement entre les entrées adjacentes de la table en utilisant `floor(2*x)`. Pour les valeurs plus grandes, elle utilise la branche asymptotique de la source :

\[
G(x) = 1 + \frac{0.1296}{x}.
\]

Cette approximation est utilisée parce qu’il s’agit de la stratégie réelle de la source et qu’elle est également pratique pour CCS. Une bibliothèque runtime de Bessel ou d’hypergéométrie serait plus coûteuse et ne décrirait plus l’implémentation SpeexDSP.

## 8. `core/design_bank.m`

Cette fonction implémente le mappage de Bark utilisé par `filterbank.c`.

La conversion de Bark de la source est :

\[
B(f) =
13.1\arctan(0.00074f)
+2.24\arctan(1.85\times10^{-8}f^2)
+10^{-4}f.
\]

Le code MATLAB évalue la coordonnée de Bark pour chaque bin du spectre positif, calcule la valeur de Bark à la fréquence de Nyquist, divise cette plage en 24 intervalles égaux et stocke les deux bandes voisines ainsi que les poids d’interpolation.

Le choix de précalculer :

```text
Left
Right
LeftWeight
RightWeight
```

est délibéré. La banque de filtres source calcule des mappages équivalents, tandis qu’une implémentation CCS gagne à calculer ces constantes une seule fois lors de l’initialisation plutôt qu’à chaque trame.

## 9. `core/bank_forward.m` et `core/bank_inverse.m`

### Mappage direct

`bank_forward.m` mappe un vecteur de fréquences linéaires vers 24 bandes de Bark :

\[
P_b = \sum_k
\left(w_{L,k,b} + w_{R,k,b}\right)P_k.
\]

Chaque bin FFT contribue à au plus deux bandes adjacentes. Cela correspond au comportement d’accumulation de `filterbank_compute_bank32()` dans `filterbank.c`.

### Mappage inverse

`bank_inverse.m` interpole un vecteur à 24 bandes vers les bins linéaires :

\[
G_k = (1-\alpha_k)G_{L,k}+\alpha_kG_{R,k}.
\]

Cela correspond au comportement d’interpolation de `filterbank_compute_psd16()` dans `filterbank.c`.

Ces fonctions utilisent des boucles explicites plutôt que des opérations matricielles implicites, car chaque boucle correspond directement à une boucle C fixe.

## 10. `core/source_faithful_process.m`

Il s’agit de l’algorithme central. C’est une enveloppe hors ligne autour d’un traitement par trames de taille fixe.

### 10.1 Préallocation et dimensions

La fonction préalloue l’entrée complétée, la sortie, la normalisation du recouvrement et les tableaux de diagnostic. Cela maintient les allocations en dehors de la boucle de trames et rend visible la mémoire nécessaire à une future implémentation C.

L’enveloppe MATLAB traite un signal complet, mais l’état algorithmique est explicite :

```text
S, Smin, Stmp
Noise, OldPower
Prior, Post, Zeta
Gain, GainFloor
UpdateProb
FrameIndex, MinCount, NbAdapt
```

Ces noms correspondent aux champs de `SpeexPreprocessState` dans `preprocess.c`.

### 10.2 Trame d’analyse

Chaque trame extrait 320 échantillons, applique la fenêtre source et calcule le spectre compact. Les 160 premières valeurs fréquentielles positives compactes sont converties en valeurs complexes uniquement pour faciliter le calcul lisible de la puissance dans MATLAB :

\[
P_k = |\mathit{FFT}_k|^2.
\]

Le code C stocke le spectre compact dans `ft` et calcule le spectre de puissance dans `ps`, à l’intérieur de `preprocess_analysis()`.

### 10.3 Spectre lissé et statistiques minimales

La source met à jour `S` selon :

\[
S_i = 0.8S_i+
0.05P_{i-1}+0.10P_i+0.05P_{i+1}.
\]

Les extrémités utilisent la règle source 0.8/0.2. `Smin` et `Stmp` suivent les minima sur l’intervalle d’adaptation source, et `UpdateProb` détermine où les mises à jour du bruit sont autorisées.

Cela repose sur `update_noise_prob()` dans `preprocess.c`. La motivation est d’éviter de mettre à jour agressivement le modèle de bruit pendant les trames dominées par la parole.

### 10.4 Estimation initiale et adaptative du bruit

L’expérience MATLAB fournit un préfixe ne contenant que du bruit. Les huit premières trames sont moyennées pour initialiser la puissance du bruit :

\[
\lambda_d^{(t)}
= \frac{(t-1)\lambda_d^{(t-1)}+P^{(t)}}{t}.
\]

Après l’initialisation, la mise à jour de style source utilise :

\[
\beta=\max(0.03,1/\text{nb\_adapt}),
\]

et ne met à jour que les bins autorisés par `UpdateProb` ou les bins dont la puissance actuelle est inférieure à l’estimation du bruit.

Le préfixe est une aide au niveau de l’expérience pour obtenir une initialisation stable. Le cœur du débruitage ne reçoit que le mélange bruité ; il ne reçoit pas le vecteur de bruit séparé.

### 10.5 SNR a posteriori

L’implémentation utilise :

\[
\gamma_k = \frac{P_k}{\lambda_{d,k}},
\qquad
\text{post}_k=\gamma_k-1.
\]

La source utilise la même relation dans `preprocess.c` :

```c
post = ps / total_noise - 1
```

La valeur est limitée à 100 pour correspondre à la borne pratique de la source.

### 10.6 SNR a priori dirigé par la décision

La mise à jour est :

\[
u_k =
0.1+0.89
\left(\frac{P_{x,k}^{old}}
{P_{x,k}^{old}+\lambda_{d,k}}\right)^2,
\]

\[
\xi_k =
u_k\max(0,\text{post}_k)
(1-\nu_k)\frac{P_{x,k}^{old}}{\lambda_{d,k}}.
\]

Cette formule utilise l’estimation précédente de la puissance du spectre propre, stockée dans `OldPower`. Cet état est essentiel : sans lui, la méthode n’est pas un estimateur dirigé par la décision.

Les constantes 0.1 et 0.89 proviennent de la mise à jour source dans `preprocess.c` ; elles fournissent une combinaison prudente des informations spectrales instantanées et précédentes.

### 10.7 Lissage de Zeta

La source lisse `zeta` ainsi :

\[
\zeta_i =
0.7\zeta_i+0.15\xi_i
0.075\xi_{i-1}+0.075\xi_{i+1}.
\]

Les extrémités utilisent la forme 0.7/0.3. Cela réduit le scintillement de la présence de parole d’une trame à l’autre et est implémenté dans la source avant le calcul de la probabilité de parole de la trame.

### 10.8 Probabilité de parole de la trame

L’implémentation corrigée mappe d’abord `zeta` vers les bandes de Bark, calcule la moyenne des valeurs de bande, puis applique :

\[
qcurve(z)=\frac{1}{1+0.15/z},
\]

\[
P_\text{frame}=0.1+0.899qcurve(\operatorname{mean}(\zeta_b)).
\]

Cet ordre est important. Calculer la moyenne des valeurs `qcurve` n’est pas équivalent à appliquer `qcurve` après la moyenne. L’implémentation a été corrigée après que les diagnostics ont révélé une estimation excessivement élevée de la présence de parole.

La valeur de présence de parole par bande est :

\[
P_{1,b}=0.199+0.8qcurve(\zeta_b).
\]

Les constantes et la définition de `qcurve` proviennent de `preprocess.c`.

### 10.9 Gain par bande de Bark

Pour chaque bande de Bark :

\[
r_b=\frac{\xi_b}{1+\xi_b},
\]

\[
\theta_b=r_b(1+\text{post}_b),
\]

\[
G_b=\min\left(1,r_b\,\text{hypergeom\_gain}(\theta_b)\right).
\]

Il s’agit de la chaîne source de gain d’amplitude MMSE hypergéométrique d’Ephraim-Malah. Le gain est borné par un pour éviter toute amplification.

### 10.10 `gain2`

La source calcule :

\[
q_b=1-P_\text{frame}P_{1,b},
\]

\[
G_{2,b}
=\frac{1}
{1+\frac{q_b}{1-q_b}(1+\xi_b)e^{-\theta_b}}.
\]

`gain2` exprime l’incertitude sur la présence de parole et est ensuite interpolé vers la fréquence linéaire. Ce n’est pas simplement un autre gain de bruit ; il contrôle l’intensité du mélange entre le gain et le plancher de gain.

### 10.11 Recalcul du gain en fréquence linéaire

La source interpole d’abord le gain de Bark, puis recalcule le gain hypergéométrique d’Ephraim-Malah à chaque bin de fréquence linéaire. L’implémentation MATLAB suit cet ordre corrigé :

1. calculer le gain de Bark ;
2. interpoler le gain de Bark ;
3. calculer le rapport a priori et `theta` du bin linéaire ;
4. calculer le gain hypergéométrique du bin linéaire ;
5. le contraindre à l’aide du gain de Bark interpolé ;
6. appliquer le plancher de gain ;
7. appliquer le mélange `gain2` dans le domaine de sonie.

Cette correction a amélioré sensiblement la suppression par rapport à la version précédente.

### 10.12 Calcul du plancher de gain source

La source en virgule flottante calcule :

\[
\text{noise\_floor}
=e^{0.2302585\,\text{noise\_suppress}},
\]

\[
G_{\text{floor},b}
=\sqrt{
\frac{\text{noise\_floor}\,N_b}
{1+N_b}
}.
\]

Ici, \(N_b\) est la puissance estimée du bruit de la bande de Bark. Le code MATLAB calcule ce plancher dans les bandes de Bark et l’interpole à nouveau vers la fréquence linéaire.

Cette méthode est supérieure à l’utilisation d’un seul plancher scalaire, car l’énergie du bruit dépend de la fréquence.

### 10.13 Mélange dans le domaine de la sonie

La source applique :

\[
G_\text{final}
=
\left[
G_2\sqrt{G}
(1-G_2)\sqrt{G_\text{floor}}
\right]^2.
\]

Le mélange avec racines carrées est délibéré. Il mélange les termes d’amplitude et de sonie avant de revenir au gain de puissance/amplitude, conformément au commentaire source dans `preprocess.c`.

### 10.14 Synthèse

Le gain final est appliqué au spectre réel compact, la transformée inverse est effectuée, la fenêtre source est appliquée une nouvelle fois et les trames adjacentes sont additionnées. L’enveloppe MATLAB divise par la puissance de fenêtre accumulée afin de compenser la normalisation du recouvrement.

Le code C maintient plutôt un état `outbuf` explicite et écrit directement les échantillons issus de l’addition avec recouvrement. Il s’agit de l’une des différences structurelles restantes à traiter pour une validation exacte bit à bit.

## 11. `core/quality_tuned_process.m`

Cette fonction exécute les mêmes équations sources, mais définit :

```matlab
QualityMode = true
NoiseSuppressDb = -35
GainFloor = exp(0.2302585 * -35)
QualityExponent = 1.0
```

L’objectif est de fournir une sortie d’écoute avec un plancher de gain SpeexDSP plus faible. Il ne s’agit pas d’une soustraction spectrale indépendante ni d’un post-filtre neuronal.

La sortie fidèle à la source reste à `-15 dB` ; la sortie sélectionnée est une configuration d’ingénierie distincte. Comme une suppression plus forte peut supprimer de l’énergie de parole, la sortie de qualité doit être évaluée à la fois avec le SNR et à l’écoute.

## 12. `core/load_sigd.m`

Il s’agit d’un utilitaire de la couche expérimentale. Il charge les fichiers MAT du professeur et exige une variable finie nommée `sigd`.

Il est volontairement extérieur à l’algorithme de traitement. Une implémentation CCS doit le remplacer par une interface d’entrée d’échantillons ou un lecteur de vecteurs de test.

## 13. `no_gui/main_reproduction_mode.m`

Il s’agit de l’environnement expérimental complet.

### Entrées

```matlab
main_reproduction_mode(cleanFile, noiseFile, backend, ...
                       qualityMode, showPlots, playAudio)
```

Exemple :

```matlab
results = main_reproduction_mode( ...
    '1z88153a8.mat', 'white8.mat', 'smallft', true, true, true);
```

### Génération du mélange

Le bruit est répété et tronqué à la longueur de la parole augmentée du préfixe, centré, puis mis à l’échelle pour atteindre le SNR cible de 10 dB dans la région de parole :

\[
a=
\sqrt{
\frac{E_s}
{10^{SNR/10}E_n}
}.
\]

Le signal propre est nul pendant le préfixe. Le débruiteur reçoit :

```text
noise-only prefix + noisy speech
```

Les signaux propres et de bruit séparé sont conservés uniquement par l’environnement pour la génération contrôlée, les métriques, les graphiques et la lecture.

### Métriques

Les métriques excluent le préfixe artificiel :

\[
SNR_\text{in}
=10\log_{10}
\frac{\sum s^2}{\sum(y_\text{noisy}-s)^2},
\]

\[
SNR_\text{out}
=10\log_{10}
\frac{\sum s^2}{\sum(y_\text{enhanced}-s)^2}.
\]

L’amélioration est :

\[
\Delta SNR=SNR_\text{out}-SNR_\text{in}.
\]

Exclure le préfixe est la métrique scientifiquement pertinente de la région de parole ; l’inclure pénaliserait le mélange avec une énergie de bruit là où la parole propre est intentionnellement nulle.

## 14. `no_gui/plot_and_listen.m`

Cette fonction est volontairement extérieure au cœur. Elle crée des spectrogrammes à échelle commune pour :

1. le signal propre ;
2. le bruit ;
3. le signal bruité ;
4. la sortie fidèle à la source ;
5. la sortie sélectionnée.

L’utilisation d’une seule plage de couleurs en dB empêche chaque graphique de masquer indépendamment le bruit résiduel. La fonction peut également lire les cinq signaux avec `soundsc`.

La fonction est destinée uniquement à l’analyse et ne doit pas être copiée dans le code d’exécution CCS.

## 15. `tests/run_tests.m`

Les tests couvrent :

* le cycle FFT/IFFT compact pour `kiss_fft` ;
* le cycle FFT/IFFT compact pour `smallft` ;
* les dimensions de la banque de filtres et les indices de bandes valides ;
* une sortie source finie ;
* des diagnostics de gain finis ;
* le nombre de trames attendu et la progression de l’état.

Les tests prouvent la stabilité numérique et la cohérence de l’interface. Ils ne prouvent pas un comportement SpeexDSP exact bit à bit. Cela exige une référence C compilée et une comparaison trame par trame.

## 16. Résultats actuels de validation

Avec la parole `1z88153a8.mat`, un SNR d’entrée de 10 dB et l’implémentation actuelle :

```text
Noise   Source-faithful SNR   Selected quality SNR
white       12.907 dB              12.862 dB
pink        12.653 dB              12.550 dB
Volvo       14.158 dB              14.174 dB
```

La sortie fidèle à la source est la référence numérique correcte. La sortie de qualité sélectionnée est destinée à l’écoute et utilise le plancher inférieur de `-35 dB`.

Ces résultats sont des améliorations positives, et non des garanties d’une parole transparente ou de niveau RNNoise. RNNoise comprend un modèle récurrent entraîné et devrait normalement fournir une meilleure séparation perceptuelle dans le cas de bruits non stationnaires difficiles.

## 17. Limites d’exactitude

L’implémentation MATLAB actuelle est dérivée de la source et non exacte bit à bit. Les différences connues sont :

1. la FFT utilise une sommation trigonométrique directe plutôt que les papillons radix de Kiss FFT ;
2. MATLAB utilise la double précision, tandis que la source utilise des types flottants C ;
3. MATLAB traite un signal complété hors ligne, tandis que la source maintient `inbuf` et `outbuf` en continu ;
4. MATLAB stocke la plupart des états spectraux dans des tableaux de taille `N` et calcule temporairement les tableaux de Bark ; la source stocke des tableaux combinés de taille `N+M` ;
5. MATLAB normalise l’addition avec recouvrement à l’aide d’un vecteur de puissance de fenêtre accumulée ; la source effectue un recouvrement explicite dans le tampon de sortie ;
6. l’étiquette actuelle `smallft` partage l’implémentation mathématique de référence compacte et ne constitue pas une implémentation distincte des papillons SmallFT.

Ces limites doivent être signalées plutôt que masquées.

## 18. Plan de traduction vers CCS

Les dimensions fixes rendent pratique une implémentation C6713 :

```c
#define FRAME_SIZE 160
#define ANALYSIS_SIZE 320
#define FFT_BINS 160
#define NUM_BANDS 24
```

L’état C doit contenir des tableaux fixes pour :

```text
S, Smin, Stmp
noise, old_power
prior, post, zeta
gain, gain_floor
inbuf, outbuf
frame, packed_spectrum
```

Le portage CCS doit remplacer :

* `packed_real_fft` par une FFT DSP fixe validée de 320 points ;
* `packed_real_ifft` par son inverse correspondant ;
* `load_sigd` par une entrée de vecteur de test ;
* les structures MATLAB par des structures C ;
* les matrices de diagnostic par des enregistrements de diagnostic d’une seule trame ;
* le remplissage hors ligne par des `inbuf` et `outbuf` explicites.

La séquence de validation correcte est :

1. exporter une trame d’analyse depuis MATLAB ;
2. comparer les valeurs de FFT compactes ;
3. comparer le spectre de puissance ;
4. comparer l’état du bruit ;
5. comparer les SNR a priori et a posteriori ;
6. comparer les gains par bande de Bark ;
7. comparer les gains linéaires ;
8. comparer la trame issue de la FFT inverse ;
9. comparer la sortie de l’addition avec recouvrement ;
10. comparer l’audio complet et le SNR.

## 19. Références sources

Références principales utilisées pour l’implémentation :

* Dépôt Xiph SpeexDSP :
  `https://github.com/xiph/speexdsp`
* Source locale :
  `speexdsp/libspeexdsp/preprocess.c`
* Source locale :
  `speexdsp/libspeexdsp/filterbank.c`
* Source locale :
  `speexdsp/libspeexdsp/fftwrap.c`
* Source locale :
  `speexdsp/libspeexdsp/kiss_fftr.c`
* Source locale :
  `speexdsp/libspeexdsp/kiss_fft.c`
* API publique :
  `speexdsp/include/speex/speex_preprocess.h`
* Licence :
  `speexdsp/COPYING`

Les références statistiques pour l’interprétation du SNR et de la MMSE sont :

* Y. Ephraim et D. Malah, « Speech Enhancement Using a Minimum Mean-Square Error Short-Time Spectral Amplitude Estimator », IEEE TASSP, 1984, DOI: 10.1109/TASSP.1984.1164453.
* I. Cohen et B. Berdugo, « Speech enhancement for non-stationary noise environments », Signal Processing, 2001.

Les équations utilisées dans le chemin réel de reproduction proviennent principalement du code source SpeexDSP, et non d’un paquet MATLAB distinct.
