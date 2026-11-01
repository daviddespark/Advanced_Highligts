; ==============================================================================
;                  SYSTÈME DE HIGHLIGHTS COMPLET POUR mIRC v2.0
;                             Auteur : Paradoxe80
; ==============================================================================
; Fonctionnalités :
; - Configuration indépendante pour chaque mot clé / pseudo / expression regex :
;   * Choix d'un son distinct (WAV, MP3, etc.) avec pré-écoute et sélecteur de fichier
;   * Activation ou désactivation individuelle de chaque mot
;   * Mode d'affichage au choix : Fenêtre active uniquement, Fenêtre @Highlights, ou Les deux
;   * Option mot entier (insensible à la casse, respectant la ponctuation IRC) ou partiel
;   * Prise en charge des Expressions Régulières (Regex) avec assistant et exemples intégrés
; - Affichage dans le salon & Alerte en fenêtre active :
;   * Affichage systématique dans le salon d'origine avec le mot surligné en rouge vif et gras
;   * Avertissement instantané dans la fenêtre active si vous êtes ailleurs : [#salon] <Pseudo> Phrase complète
;   * Respect absolu de la vie privée (aucune altération envoyée aux autres utilisateurs)
; - Détection bidirectionnelle :
;   * Messages reçus sur les salons (TEXT et ACTION)
;   * Vos propres saisies en salon (INPUT) pour tests et confort
; - Fenêtre de journalisation dédiée : @Highlights
;   * Horodatage propre et mise en valeur des mots clés
;   * Double-clic sur une ligne pour rejoindre directement le salon concerné
;   * Clic-droit avec menu contextuel (rejoindre, ouvrir PV, vider, etc.)
; - Alertes visuelles : Surlignage coloré dans la fenêtre active et clignotement mIRC (Flash)
; - Interface graphique complète (Dialog / GUI) moderne et ergonomique (/hl)
;   * Vérification anti-doublon lors des ajouts
;   * Confirmation d'enregistrement automatique et actualisation instantanée
;   * Modale d'aide et d'insertion rapide de motifs Regex prêts à l'emploi
; - Raccourcis console (/hl, /hl on, /hl off, /hl win, /hl add, /hl del, /hl list, /hl test)
; - Menus intégrés : Barre de menus, Salons, PV, Liste des pseudos, Fenêtre @Highlights
; ==============================================================================

; ------------------------------------------------------------------------------
; GESTION DU CHARGEMENT / DÉCHARGEMENT
; ------------------------------------------------------------------------------
on *:LOAD: {
  hl_init_config
  echo -a $chr(3) $+ 10╔════════════════════════════════════════════════════════════════════╗
  echo -a $chr(3) $+ 11   *** Système de Highlights mIRC v2.0 chargé avec succès ! ***
  echo -a $chr(3) $+ 14   Tapez $chr(3) $+ 04/hl $chr(3) $+ 14pour ouvrir le panneau de configuration.
  echo -a $chr(3) $+ 14   Tapez $chr(3) $+ 04/hl win $chr(3) $+ 14pour afficher la fenêtre @Highlights.
  echo -a $chr(3) $+ 14   Tapez $chr(3) $+ 04/hl test <mot> $chr(3) $+ 14pour tester immédiatement un Highlight.
  echo -a $chr(3) $+ 10╚════════════════════════════════════════════════════════════════════╝
}

on *:UNLOAD: {
  echo -a $chr(3) $+ 04*** Système de Highlights mIRC déchargé.
}

; ------------------------------------------------------------------------------
; ALIAS INTERNES & FICHIER DE CONFIGURATION
; ------------------------------------------------------------------------------
alias -l hl_file {
  return $qt($scriptdir $+ highlight.ini)
}

alias -l hl_ini {
  return $qt($scriptdir $+ highlight.ini)
}

alias -l hl_sec {
  return HL_ $+ $1
}

alias -l hl_get_cfg {
  var %val = $readini($hl_file, General, $1)
  if (%val != $null) return %val
  return $2
}

alias -l hl_init_config {
  if (!$isfile($hl_file)) {
    writeini $hl_ini General enabled 1
    writeini $hl_ini General flash 1
    writeini $hl_ini General count 1
    
    ; Entrée par défaut : votre propre pseudonyme
    writeini $hl_ini HL_1 word $me
    writeini $hl_ini HL_1 active 1
    writeini $hl_ini HL_1 exact 1
    writeini $hl_ini HL_1 is_regex 0
    writeini $hl_ini HL_1 target both
    writeini $hl_ini HL_1 sound $null
  }
}

; Échappement des caractères réservés aux regex (sans aucun caractère pipe littéral)
alias -l hl_escape_regex {
  return $regsubex($1-, /([\\^$*+?.() $+ $chr(124) $+ [\]{}])/g, \\\1)
}



; Surlignage d'un mot dans un texte avec gras et couleur rouge vif ($chr(3)04)
alias -l hl_colorize {
  var %text = $1
  var %word = $2
  var %exact = $3
  var %is_regex = $4
  var %col = 04
  
  if (%is_regex == 1) {
    var %pat = %word
    if ($left(%pat, 1) == / && $right(%pat, 1) == /) {
      %pat = $mid(%pat, 2, $calc($len(%pat) - 2))
    }
    return $regsubex(%text, /(?i)( $+ %pat $+ )/g, $chr(3) $+ %col $+ $chr(2) $+ \1 $+ $chr(2) $+ $chr(15))
  }
  
  var %esc = $hl_escape_regex(%word)
  if (%exact == 1) {
    return $regsubex(%text, /(?i)\b( $+ %esc $+ )\b/g, $chr(3) $+ %col $+ $chr(2) $+ \1 $+ $chr(2) $+ $chr(15))
  }
  else {
    return $regsubex(%text, /(?i)( $+ %esc $+ )/g, $chr(3) $+ %col $+ $chr(2) $+ \1 $+ $chr(2) $+ $chr(15))
  }
}

; Suppression et réindexation d'une entrée dans le fichier INI
alias -l hl_del_entry {
  var %del = $1
  var %total = $readini($hl_file, General, count)
  if (%del !isnum 1-%total) return
  
  remini $hl_ini $hl_sec(%del)
  
  var %i = $calc(%del + 1)
  while (%i <= %total) {
    var %prev = $calc(%i - 1)
    writeini $hl_ini $hl_sec(%prev) word $readini($hl_file, $hl_sec(%i), word)
    writeini $hl_ini $hl_sec(%prev) active $readini($hl_file, $hl_sec(%i), active)
    writeini $hl_ini $hl_sec(%prev) exact $readini($hl_file, $hl_sec(%i), exact)
    writeini $hl_ini $hl_sec(%prev) is_regex $readini($hl_file, $hl_sec(%i), is_regex)
    writeini $hl_ini $hl_sec(%prev) target $readini($hl_file, $hl_sec(%i), target)
    writeini $hl_ini $hl_sec(%prev) sound $readini($hl_file, $hl_sec(%i), sound)
    remini $hl_ini $hl_sec(%i)
    inc %i
  }
  
  dec %total
  writeini $hl_ini General count %total
}

; Extraction de l'ID depuis une ligne de la liste GUI (ex: "#2 [ON] ...")
alias -l hl_extract_id {
  var %tok = $gettok($1, 1, 32)
  if (#* iswm %tok) return $remove(%tok, #)
  return $null
}

; ------------------------------------------------------------------------------
; FENÊTRE DÉDIÉE : @Highlights
; ------------------------------------------------------------------------------
alias hl_win {
  if (!$window(@Highlights)) {
    window -e @Highlights
    titlebar @Highlights - Journal des Highlights
    aline @Highlights $chr(3) $+ 03*** Fenêtre des Highlights ouverte le $asctime(dd/mm/yyyy à HH:nn:ss) ***
    aline @Highlights $chr(3) $+ 14Double-cliquez sur une ligne pour ouvrir le salon et localiser le Highlight.
    aline @Highlights $chr(3) $+ 14════════════════════════════════════════════════════════════════════════════════
  }
  else {
    window -a @Highlights
  }
}

alias -l hl_log_win {
  var %type = $1
  var %chan = $2
  var %nick = $3
  var %word = $4
  var %colored = $5-
  
  ; Créer la fenêtre si elle est fermée
  if (!$window(@Highlights)) {
    window -e @Highlights
    titlebar @Highlights - Journal des Highlights
    aline @Highlights $chr(3) $+ 03*** Fenêtre des Highlights ouverte le $asctime(dd/mm/yyyy à HH:nn:ss) ***
    aline @Highlights $chr(3) $+ 14Double-cliquez sur une ligne pour ouvrir le salon et localiser le Highlight.
    aline @Highlights $chr(3) $+ 14════════════════════════════════════════════════════════════════════════════════
  }
  
  var %time = $asctime(HH:nn:ss)
  var %net = $network
  if (!%net) %net = $server
  var %pnick = %nick
  if ($nick(%chan, %nick).pnick) %pnick = $nick(%chan, %nick).pnick
  
  var %time_str = $chr(91) $+ %time $+ $chr(93)
  var %net_str = $chr(91) $+ %net $+ $chr(93)
  var %chan_str = $chr(91) $+ %chan $+ $chr(93)
  var %nick_str = $chr(60) $+ %pnick $+ $chr(62)
  
  if (%type == action) {
    aline -p @Highlights $chr(3) $+ 14 $+ %time_str $chr(3) $+ 06 $+ %net_str $chr(3) $+ 10 $+ %chan_str $chr(06) * %pnick $+ $chr(15) %colored
  }
  else {
    aline -p @Highlights $chr(3) $+ 14 $+ %time_str $chr(3) $+ 06 $+ %net_str $chr(3) $+ 10 $+ %chan_str $chr(3) $+ 03 $+ %nick_str $+ $chr(15) %colored
  }
}

; Copie sécurisée dans le presse-papier avec préservation stricte des espaces multiples
alias -l hl_copy_clip {
  clipboard $1-
  if ($pos($1-, $chr(32) $+ $chr(32))) {
    var %wsh = hl_wsh_clip_ $+ $ticks
    .comopen %wsh WScript.Shell
    if (!$comerr) {
      var %cmd = powershell -NoProfile -WindowStyle Hidden -Command "Set-Clipboard -Value ([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(' $+ $encode($1-, m) $+ ')))"
      noop $com(%wsh, Run, 1, string, %cmd, integer, 0, boolean, true)
      .comclose %wsh
    }
  }
}

; Envoi sécurisé de touches virtuelles Windows à mIRC via WScript.Shell
alias -l hl_sendkeys {
  var %wsh = hl_wsh_ $+ $ticks
  .comopen %wsh WScript.Shell
  if (!$comerr) {
    noop $com(%wsh, SendKeys, 3, string, $1-)
    .comclose %wsh
  }
}

; Recherche du Connection ID ($cid) associé à un salon à travers les fenêtres ouvertes
alias -l hl_find_chan_cid {
  var %target = $1
  var %net = $2
  if ($window(%target).cid) return $window(%target).cid
  if (%net) {
    var %i = 1
    while (%i <= $scid(0)) {
      if ($scid(%i).network == %net) return $scid(%i)
      inc %i
    }
  }
  return $cid
}

; Alias d'ouverture du salon et de positionnement à l'endroit exact du Highlight par Timestamp (Multi-serveur)
alias -l hl_open_chan_at_hl {
  var %line = $null
  if ($1 isnum) && ($window(@Highlights)) {
    %line = $line(@Highlights, $1)
  }
  if (%line == $null) %line = $1-
  %line = $strip(%line)
  if (%line == $null) return
  
  ; 1. Extraction du timestamp [HH:nn:ss], du réseau éventuel et du salon [#salon]
  var %time = $null
  var %chan = $null
  var %net = $null
  
  ; Format avec réseau éventuel [HH:nn:ss] [Network] [#salon]
  if ($regex(%line, /^(\[\d{1,2}:\d{2}(?::\d{2})?\])\s+\[([^\]\s#]+)\]\s+\[(#[^\]\s]+)\]/)) {
    %time = $regml(1)
    %net = $regml(2)
    %chan = $regml(3)
  }
  ; Format standard [HH:nn:ss] [#salon]
  elseif ($regex(%line, /^(\[\d{1,2}:\d{2}(?::\d{2})?\])\s+\[(#[^\]\s]+)\]/)) {
    %time = $regml(1)
    %chan = $regml(2)
  }
  else {
    if ($regex(%line, /(\[\d{1,2}:\d{2}(?::\d{2})?\])/)) %time = $regml(1)
    if ($regex(%line, /\[(#[^\]\s]+)\]/)) %chan = $regml(1)
    elseif ($regex(%line, /\b(#[^\s,;:]+)\b/)) %chan = $regml(1)
    if ($regex(%line, /\[([^\]\s#]+)\]\s+\[#/)) %net = $regml(1)
  }
  
  if (%chan == $null) || (%time == $null) return
  
  ; 2. Trouver le bon serveur (Connection ID / $cid) pour ce salon
  var %cid = $hl_find_chan_cid(%chan, %net)
  if (%cid == $null) %cid = $cid
  
  ; Basculer le contexte sur le bon serveur
  scid %cid
  
  ; Si l'utilisateur n'est pas sur le salon, on le rejoint sur ce serveur
  if (!$me ison %chan) {
    join %chan
    echo -a $chr(3) $+ 10*** Rejoint le salon %chan sur $network suite au Highlight.
    return
  }
  
  ; 3. Activer la fenêtre du salon sur ce serveur
  window -a %chan
  
  ; 4. Copie du timestamp dans le presse-papier et positionnement à la 1re occurrence
  var %search = %time
  clipboard %search
  set -u10 %hl_jump_cid %cid
  set -u10 %hl_jump_chan %chan
  set -u10 %hl_jump_search %search
  echo -a $chr(3) $+ 10*** [Highlights] Localisation de %chan sur $network (Heure : %search) ...
  ; Étape 1 : dès que le salon a le focus (150ms), ouvrir la boîte Find Text native (Ctrl+F)
  .timer_hl_jump1 -m 1 150 hl_exec_jump_step1
}

; Étape 1 : ouvrir la boîte native de recherche Find Text de mIRC (Ctrl+F)
alias -l hl_exec_jump_step1 {
  var %cid = %hl_jump_cid
  var %chan = %hl_jump_chan
  if ($window(%chan)) {
    scid %cid
    window -a %chan
    hl_sendkeys ^f
    ; Étape 2 : coller le texte, forcer recherche vers le haut et valider
    .timer_hl_jump2 -m 1 200 hl_exec_jump_step2
  }
}

; Étape 2 : coller le texte recherché, forcer la recherche vers le haut (%u = Alt+U), puis valider (Entrée)
alias -l hl_exec_jump_step2 {
  var %cid = %hl_jump_cid
  var %chan = %hl_jump_chan
  if ($window(%chan)) {
    scid %cid
    ; ^a = tout sélectionner, ^v = coller le timestamp, %u = Alt+U (direction Up), {ENTER} = Valider la recherche
    hl_sendkeys ^a^v%u{ENTER}
    ; Étape 3 : fermer la boîte Find Text après que mIRC a scrollé sur la ligne
    .timer_hl_jump3 -m 1 250 hl_exec_jump_step3
  }
}

; Étape 3 : fermer la boîte de recherche (Échap)
alias -l hl_exec_jump_step3 {
  hl_sendkeys {ESC}
}

; ------------------------------------------------------------------------------
; GESTION DU SURVOL ET DU DOUBLE-CLIC DANS @Highlights (ÉVÉNEMENTS HOTLINK)
; ------------------------------------------------------------------------------
; Interception au survol de la souris : transforme le curseur en main sur les lignes de HL
on ^*:HOTLINK:*:@Highlights: {
  if ($regex($hotline, /\[#[^\]\s]+\]/)) {
    set -u5 %hl_last_clicked_line $hotline
    return
  }
  halt
}

; Déclenchement automatique lors du DOUBLE-CLIC sur une ligne
on *:HOTLINK:*:@Highlights: {
  haltdef
  var %line = $hotline
  if (%line == $null) %line = %hl_last_clicked_line
  if (%line != $null) hl_open_chan_at_hl %line
}

; Menu contextuel (clic-droit) sur la fenêtre @Highlights
menu @Highlights {
  dclick: {
    var %ln = $mouse.line
    if (%ln == $null) %ln = $sline(@Highlights, 1).ln
    if (%ln != $null) hl_open_chan_at_hl %ln
    elseif (%hl_last_clicked_line != $null) hl_open_chan_at_hl %hl_last_clicked_line
    elseif ($hotline != $null) hl_open_chan_at_hl $hotline
  }
  Aller au salon et localiser le HL: {
    var %ln = $mouse.line
    if (%ln == $null) %ln = $sline(@Highlights, 1).ln
    if (%ln != $null) hl_open_chan_at_hl %ln
    elseif (%hl_last_clicked_line != $null) hl_open_chan_at_hl %hl_last_clicked_line
    elseif ($hotline != $null) hl_open_chan_at_hl $hotline
  }
  Ouvrir un PV avec le pseudo: {
    var %line = $hotline
    if (!%line) %line = %hl_last_clicked_line
    if (!%line && $mouse.line) %line = $line(@Highlights, $mouse.line)
    if (!%line && $sline(@Highlights, 1).ln) %line = $line(@Highlights, $sline(@Highlights, 1).ln)
    var %nick = $null
    if ($regex(%line, /<([^>]+)>/)) {
      %nick = $regml(1)
    }
    elseif ($regex(%line, /\]\s+\*\s+([^\s]+)/)) {
      %nick = $regml(1)
    }
    if (%nick) {
      while ($left(%nick, 1) isin ~&@%+) %nick = $mid(%nick, 2)
      if (%nick) query %nick
    }
  }
  -
  Vider cette fenêtre:clear @Highlights
  Configurer les Highlights...:hl
  Fermer cette fenêtre:window -c @Highlights
}

; ------------------------------------------------------------------------------
; MOTEUR CENTRAL DE DÉTECTION ET TRAITEMENT
; ------------------------------------------------------------------------------
alias -l hl_check_msg {
  var %type = $1
  var %chan = $2
  var %nick = $3
  var %msg = $4-
  
  if ($hl_get_cfg(enabled, 1) != 1) return
  
  var %f = $hl_file
  var %total = $readini(%f, General, count)
  if (!%total) return
  
  var %clean_msg = $strip(%msg)
  
  var %i = 1
  while (%i <= %total) {
    var %sec = $hl_sec(%i)
    var %active = $readini(%f, %sec, active)
    
    if (%active == 1) {
      var %raw_w = $readini(%f, %sec, word)
      var %w = $replace(%raw_w, $chr(36) $+ me, $me)
      var %exact = $readini(%f, %sec, exact)
      var %is_regex = $readini(%f, %sec, is_regex)
      var %matched = 0
      
      if (%is_regex == 1) {
        var %pat = %w
        if ($left(%pat, 1) != /) %pat = /(?i) $+ %pat $+ /
        if ($regex(%clean_msg, %pat)) %matched = 1
      }
      else {
        var %esc = $hl_escape_regex(%w)
        if (%exact == 1) {
          if ($regex(%clean_msg, /(?i)\b $+ %esc $+ \b/)) %matched = 1
        }
        else {
          if ($regex(%clean_msg, /(?i) $+ %esc/)) %matched = 1
        }
      }
      
      if (%matched == 1) {
        var %target = $readini(%f, %sec, target)
        var %sound = $readini(%f, %sec, sound)
        
        ; 1. Alerte sonore si configurée
        if (%sound && $isfile(%sound)) {
          .splay $qt(%sound)
        }
        
        ; 2. Alerte visuelle : clignotement barre des tâches mIRC
        if ($hl_get_cfg(flash, 1) == 1) {
          .flash -b 2
        }
        
        var %col_txt = $hl_colorize(%msg, %w, %exact, %is_regex)
        var %pnick = %nick
        if ($nick(%chan, %nick).pnick) %pnick = $nick(%chan, %nick).pnick
        var %time_str = $chr(91) $+ $time $+ $chr(93)
        var %nick_str = $chr(60) $+ %pnick $+ $chr(62)
        
        ; 3. Affichage dans la fenêtre @Highlights (si target != active et != salon)
        if (%target !isin active salon) {
          hl_log_win %type %chan %nick %w %col_txt
        }
        
        ; 4. Affichage systématique dans le SALON EN QUESTION (%chan) avec le mot surligné
        if ($window(%chan)) {
          if (%type == action) {
            echo %chan $chr(3) $+ 14 $+ %time_str $chr(06) * %pnick $+ $chr(15) %col_txt
          }
          else {
            echo %chan $chr(3) $+ 14 $+ %time_str $chr(3) $+ 03 $+ %nick_str $+ $chr(15) %col_txt
          }
        }
        
        ; 5. Avertissement dans la FENÊTRE ACTIVE (-a) :
        ; Affiché si la fenêtre active n'est pas le salon concerné (ou si le salon n'est pas une fenêtre ouverte)
        if ((!$window(%chan) || $active != %chan) && %target != fenetre) {
          var %chan_str = $chr(91) $+ %chan $+ $chr(93)
          if (%type == action) {
            echo -a $chr(3) $+ 14 $+ %time_str $chr(3) $+ 10 $+ %chan_str $chr(06) * %pnick $+ $chr(15) %col_txt
          }
          else {
            echo -a $chr(3) $+ 14 $+ %time_str $chr(3) $+ 10 $+ %chan_str $chr(3) $+ 03 $+ %nick_str $+ $chr(15) %col_txt
          }
        }
        
        set -u1 %hl_last_match %target
        return
      }
    }
    inc %i
  }
}

; Événement TEXT (messages des autres utilisateurs sur les salons)
on ^*:TEXT:*:#: {
  if ($nick == $me) return
  unset %hl_last_match
  hl_check_msg text $chan $nick $1-
  if (%hl_last_match) {
    haltdef
  }
}

; Événement ACTION (actions /me des autres utilisateurs sur les salons)
on ^*:ACTION:*:#: {
  if ($nick == $me) return
  unset %hl_last_match
  hl_check_msg action $chan $nick $1-
  if (%hl_last_match) {
    haltdef
  }
}

; Événement INPUT (vos propres messages tapés sur un salon contenant un mot clé)
on *:INPUT:#: {
  ; Ne pas intercepter les commandes mIRC débutant par /
  if ($left($1, 1) == / && $left($1, 2) != //) return
  if ($ctrlenter) return
  
  var %chan = $iif($chan, $chan, $active)
  unset %hl_last_match
  hl_check_msg text %chan $me $1-
  if (%hl_last_match) {
    if ($server) .msg %chan $1-
    haltdef
  }
}

; ------------------------------------------------------------------------------
; GESTION DES IMAGES ET ASSETS GRAPHIQUES (BANNIÈRE MODERNE)
; ------------------------------------------------------------------------------
alias -l hl_dir {
  return $scriptdir $+ highlight_assets\
}

alias -l hl_gfx {
  var %f = $hl_dir $+ $1
  var %s = $shortfn(%f)
  if ($chr(32) !isin %s) return %s
  return $qt(%f)
}

alias -l hl_assets {
  var %dir = $hl_dir
  if (!$isdir(%dir)) mkdir $qt(%dir)
  var %w = @hl_draw
  if ($window(%w)) window -c %w
  
  ; Création d'une fenêtre hors écran pour dessiner la bannière (840x64 pixels)
  window -hpfB %w 0 0 840 64
  
  ; Dégradé sombre moderne
  drawrect -rfn %w $rgb(18,20,32) 1 0 0 840 64
  drawrect -rfn %w $rgb(28,32,52) 1 0 0 840 32
  
  ; Liseré multicolore moderne en bas de la bannière
  var %k = 0
  while (%k < 14) {
    var %col = $rgb($calc(50 + %k * 14), $calc(110 + %k * 6), $calc(230 - %k * 10))
    drawrect -rfn %w %col 1 $calc(%k * 60) 60 60 4
    inc %k
  }
  
  ; Badge d'état global dynamique à droite
  var %sys_st = $hl_get_cfg(enabled, 1)
  var %st_bg = $iif(%sys_st == 1, $rgb(36,160,82), $rgb(210,45,45))
  var %st_txt = $iif(%sys_st == 1, SYSTEME ACTIF, SYSTEME EN PAUSE)
  drawrect -rfn %w %st_bg 1 670 18 145 28
  drawrect -rn %w $rgb(255,255,255) 1 670 18 145 28
  drawtext -nro %w $rgb(255,255,255) Verdana 11 685 24 %st_txt
  
  ; Titre et sous-titre
  drawtext -nro %w $rgb(255,255,255) Verdana 18 20 8 Highlight Manager par Paradoxe80
  drawtext -nr %w $rgb(165,180,220) Verdana 10 22 36 Surveillance des mots cles, alertes sonores & expressions regex
  
  drawsave %w $qt(%dir $+ banner.bmp)
  window -c %w
}

; ------------------------------------------------------------------------------
; INTERFACE GRAPHIQUE (DIALOG / GUI) - DESIGN HAUTE QUALITÉ EN PIXELS
; ------------------------------------------------------------------------------
dialog hl_dialog {
  title "Highlight Manager v2.0 - Configuration Avancée"
  size -1 -1 840 496
  option pixels

  ; Bannière graphique d'en-tête (840x64)
  icon 1, 0 0 840 64, $mircexe, 0, noborder

  ; Panneau Gauche : Liste des Highlights
  box "Highlights configurés", 2, 14 74 380 370
  list 10, 24 98 360 296, vsbar
  button "Supprimer", 52, 24 404 110 26
  button "Activer / Pause", 53, 148 404 115 26
  button "Ouvrir @HL", 4, 274 404 110 26

  ; Panneau Droit : Paramètres du mot sélectionné
  box "Paramètres du mot sélectionné", 3, 408 74 418 370
  text "Mot clé ou Expression :", 20, 424 96 230 16
  button "? Exemples Regex", 25, 664 92 146 20
  edit "", 21, 424 114 386 24, autohs
  check "Actif", 22, 424 146 55 20
  check "Mot entier (IRC)", 23, 485 146 140 20
  check "Mode Regex", 24, 635 146 175 20

  text "Destination de l'alerte :", 29, 424 174 250 16
  radio "Fenêtre active uniquement", 30, 424 192 350 18, group
  radio "Fenêtre @Highlights uniquement", 31, 424 212 350 18
  radio "Les deux (Fenêtre active + @Highlights)", 32, 424 232 350 18

  text "Alerte sonore associée (WAV, MP3...) :", 39, 424 258 250 16
  edit "", 40, 424 276 386 24, autohs
  button "Parcourir...", 41, 424 308 90 26
  button "Écouter", 42, 524 308 86 26
  button "Stop", 43, 618 308 76 26
  button "Effacer son", 44, 702 308 90 26

  button "Ajouter", 51, 424 402 120 28
  button "Modifier", 54, 556 402 120 28
  button "Nouveau", 50, 688 402 120 28

  ; Barre inférieure globale
  check "Activer le système de Highlights", 8, 14 456 210 24
  check "Flasher mIRC (Windows)", 9, 234 456 190 24
  button "Vider journal @HL", 6, 520 454 140 28
  button "Fermer", 70, 672 454 154 28, ok
}

on *:dialog:hl_dialog:init:0: {
  did -g $dname 1 $shortfn($hl_dir $+ banner.bmp)
  
  ; Charger les réglages généraux
  if ($hl_get_cfg(enabled, 1) == 1) did -c $dname 8
  if ($hl_get_cfg(flash, 1) == 1) did -c $dname 9
  
  ; Valeurs par défaut du formulaire
  did -c $dname 22
  did -c $dname 23
  did -u $dname 24
  did -c $dname 32
  
  ; Charger la liste
  hl_dialog_refresh_list
}

on *:dialog:hl_dialog:close:0: {
  if ($window(@hl_draw)) window -c @hl_draw
}

; Clic sur la case générale Activer/Désactiver
on *:dialog:hl_dialog:sclick:8: {
  writeini $hl_ini General enabled $did(8).state
  hl_assets
  did -g $dname 1 $shortfn($hl_dir $+ banner.bmp)
}

; Clic sur la case Flasher mIRC
on *:dialog:hl_dialog:sclick:9: {
  writeini $hl_ini General flash $did(9).state
}

; Bouton Ouvrir @Highlights
on *:dialog:hl_dialog:sclick:4: {
  hl_win
}

; Bouton Vider @Highlights
on *:dialog:hl_dialog:sclick:6: {
  if ($window(@Highlights)) clear @Highlights
  echo -a $chr(3) $+ 10*** Journal de la fenêtre @Highlights vidé.
}

; Sélection d'un élément dans la liste
on *:dialog:hl_dialog:sclick:10: {
  var %sel = $did($dname, 10).sel
  if (!%sel) %sel = $did(10).sel
  if (!%sel) %sel = $hl_extract_id($did(10).seltext)
  if (%sel) {
    hl_dialog_load_entry %sel
  }
}

; Double-clic sur un élément dans la liste : charger les données dans le formulaire
on *:dialog:hl_dialog:dclick:10: {
  var %sel = $did($dname, 10).sel
  if (!%sel) %sel = $did(10).sel
  if (!%sel) %sel = $hl_extract_id($did(10).seltext)
  if (%sel) {
    hl_dialog_load_entry %sel
    did -f $dname 21
  }
}

; Interaction entre cases Mot Entier et Mode Regex
on *:dialog:hl_dialog:sclick:24: {
  if ($did(24).state == 1) did -u $dname 23
}

on *:dialog:hl_dialog:sclick:23: {
  if ($did(23).state == 1) did -u $dname 24
}

; Bouton Exemples Regex (ouvre la modale)
on *:dialog:hl_dialog:sclick:25: {
  dialog -m hl_regex_help hl_regex_help
}

; Bouton Parcourir pour le son
on *:dialog:hl_dialog:sclick:41: {
  var %f = $sfile($mircdirsounds\*.wav;*.mp3;*.ogg;*.wma;*.mid, Sélectionner un son pour le HL, Choisir)
  if (%f) {
    did -ra $dname 40 %f
  }
}

; Bouton Tester le son
on *:dialog:hl_dialog:sclick:42: {
  var %f = $did(40).text
  if ($isfile(%f)) {
    .splay $qt(%f)
  }
  else {
    noop $input(Fichier son introuvable : $+ $crlf $+ %f, o w, Erreur Fichier Son)
  }
}

; Bouton Stopper le son
on *:dialog:hl_dialog:sclick:43: {
  .splay stop
}

; Bouton Effacer le son
on *:dialog:hl_dialog:sclick:44: {
  did -ra $dname 40 $null
}

; Bouton Nouveau (vider le formulaire)
on *:dialog:hl_dialog:sclick:50: {
  hl_dialog_clear_form
}

; Bouton Ajouter (créer un nouveau Highlight avec vérification anti-doublon)
on *:dialog:hl_dialog:sclick:51: {
  var %d = $dname
  var %word = $strip($did(21).text)
  if (%word == $null) {
    noop $input(Veuillez entrer un mot clé ou un pseudonyme à ajouter., o w, Champ obligatoire)
    return
  }
  
  var %f = $hl_file
  var %count = $readini(%f, General, count)
  if (!%count) %count = 0
  
  ; 1°) Vérification anti-doublon (insensible à la casse)
  var %i = 1
  while (%i <= %count) {
    var %exist_w = $readini(%f, $hl_sec(%i), word)
    if ($lower(%word) == $lower(%exist_w)) {
      noop $input(Le mot ou motif ' $+ %word $+ ' existe déjà dans votre liste (# $+ %i $+ ). $+ $crlf $+ Veuillez modifier l'entrée existante ou spécifier un autre mot., o w, Mot déjà existant)
      did -c %d 10 %i
      hl_dialog_load_entry %i
      return
    }
    inc %i
  }
  
  inc %count
  var %sec = $hl_sec(%count)
  
  var %active = $did(22).state
  var %exact = $did(23).state
  var %is_regex = $did(24).state
  
  var %target = both
  if ($did(30).state == 1) %target = active
  elseif ($did(31).state == 1) %target = fenetre
  elseif ($did(32).state == 1) %target = both
  
  var %sound = $did(40).text
  
  writeini $hl_ini General count %count
  writeini $hl_ini %sec word %word
  writeini $hl_ini %sec active %active
  writeini $hl_ini %sec exact %exact
  writeini $hl_ini %sec is_regex %is_regex
  writeini $hl_ini %sec target %target
  writeini $hl_ini %sec sound %sound
  
  ; 2°) Mise à jour de la liste avec sélection du mot ajouté
  hl_dialog_refresh_list %count
  
  ; Message d'enregistrement réussi
  noop $input(Le Highlight pour ' $+ %word $+ ' a été enregistré avec succès ! $+ $crlf $+ Il porte le numéro # $+ %count $+  et est désormais actif dans votre liste., o i, Enregistrement réussi)
  echo -a $chr(3) $+ 03*** Highlight pour ' $+ %word $+ ' enregistré avec succès (# $+ %count $+ ).
}

; Bouton Modifier (enregistrer les modifications sur le mot sélectionné)
on *:dialog:hl_dialog:sclick:54: {
  var %d = $dname
  var %seltext = $did(10).seltext
  if (!%seltext) {
    noop $input(Veuillez sélectionner le mot à modifier dans la liste, ou cliquez sur 'Ajouter' pour en créer un nouveau., o w, Aucune sélection)
    return
  }
  
  var %id = $hl_extract_id(%seltext)
  var %word = $strip($did(21).text)
  if (%word == $null) {
    noop $input(Le mot clé ne peut pas être vide., o w, Champ obligatoire)
    return
  }
  
  var %f = $hl_file
  var %count = $readini(%f, General, count)
  
  ; Vérifier si le mot modifié n'entre pas en conflit avec une autre entrée
  var %i = 1
  while (%i <= %count) {
    if (%i != %id) {
      if ($lower(%word) == $lower($readini(%f, $hl_sec(%i), word))) {
        noop $input(Le mot ou motif ' $+ %word $+ ' existe déjà sous le numéro # $+ %i $+ ., o w, Doublon détecté)
        return
      }
    }
    inc %i
  }
  
  var %sec = $hl_sec(%id)
  var %active = $did(22).state
  var %exact = $did(23).state
  var %is_regex = $did(24).state
  
  var %target = both
  if ($did(30).state == 1) %target = active
  elseif ($did(31).state == 1) %target = fenetre
  elseif ($did(32).state == 1) %target = both
  
  var %sound = $did(40).text
  
  writeini $hl_ini %sec word %word
  writeini $hl_ini %sec active %active
  writeini $hl_ini %sec exact %exact
  writeini $hl_ini %sec is_regex %is_regex
  writeini $hl_ini %sec target %target
  writeini $hl_ini %sec sound %sound
  
  hl_dialog_refresh_list %id
  noop $input(Le Highlight # $+ %id $+  (' $+ %word $+ ') a été mis à jour avec succès !, o i, Modification enregistrée)
  echo -a $chr(3) $+ 03*** Highlight # $+ %id $+  (' $+ %word $+ ') mis à jour avec succès.
}

; Bouton Supprimer
on *:dialog:hl_dialog:sclick:52: {
  var %seltext = $did(10).seltext
  if (!%seltext) {
    noop $input(Veuillez sélectionner un mot dans la liste à supprimer., o w, Aucune sélection)
    return
  }
  var %id = $hl_extract_id(%seltext)
  var %word = $readini($hl_file, $hl_sec(%id), word)
  var %conf = $input(Confirmez-vous la suppression du highlight pour ' $+ %word $+ ' ?, y n, Confirmation)
  if (%conf == $yes) {
    hl_del_entry %id
    hl_dialog_refresh_list
    hl_dialog_clear_form
    echo -a $chr(3) $+ 04*** Highlight ' $+ %word $+ ' supprimé.
  }
}

; Bouton Activer / Désactiver rapidement
on *:dialog:hl_dialog:sclick:53: {
  var %seltext = $did(10).seltext
  if (!%seltext) {
    noop $input(Veuillez sélectionner un mot dans la liste., o w, Aucune sélection)
    return
  }
  var %id = $hl_extract_id(%seltext)
  var %sec = $hl_sec(%id)
  var %st = $readini($hl_file, %sec, active)
  var %newst = $iif(%st == 1, 0, 1)
  writeini $hl_ini %sec active %newst
  hl_dialog_refresh_list %id
}

; Rafraîchissement de la liste dans le dialogue
alias -l hl_dialog_refresh_list {
  if (!$dialog(hl_dialog)) return
  var %d = hl_dialog
  var %sel_id = $1
  var %f = $hl_file
  var %total = $readini(%f, General, count)
  
  did -r %d 10
  
  var %i = 1
  while (%i <= %total) {
    var %sec = $hl_sec(%i)
    var %w = $readini(%f, %sec, word)
    if (%w != $null) {
      var %act = $readini(%f, %sec, active)
      var %is_reg = $readini(%f, %sec, is_regex)
      var %target = $readini(%f, %sec, target)
      var %sound = $readini(%f, %sec, sound)
      
      var %acttxt = $iif(%act == 1, ON, OFF)
      var %regtag = $iif(%is_reg == 1, [REG] , )
      var %dest
      if (%target isin active salon) %dest = Active
      elseif (%target == fenetre) %dest = Fenêtre
      else %dest = Les deux
      
      var %sndtxt = $iif(%sound, $nopath(%sound), Sans son)
      
      var %disp_w = %w
      if (%w == $chr(36) $+ me) {
        %disp_w = $iif($me, $me $+  ($chr(36) $+ me), $chr(36) $+ me)
      }
      
      ; Format d'affichage : #1 [ON] Mot (Destination - Son) sans pipe
      var %item_txt = $chr(35) $+ %i $chr(91) $+ %acttxt $+ $chr(93) %regtag $+ %disp_w ( $+ %dest - %sndtxt $+ )
      did -a %d 10 %item_txt
      
      if (%sel_id == %i) {
        did -c %d 10 %i
      }
    }
    inc %i
  }
  
  if (%sel_id && %sel_id <= %total) {
    hl_dialog_load_entry %sel_id
  }
}

; Chargement d'une entrée dans les champs du dialogue
alias -l hl_dialog_load_entry {
  if (!$dialog(hl_dialog)) return
  var %d = hl_dialog
  var %id = $1
  if (%id !isnum) return
  var %f = $hl_ini
  var %sec = $hl_sec(%id)
  
  var %w = $readini(%f, %sec, word)
  if (%w == $null) return
  
  var %act = $readini(%f, %sec, active)
  var %exact = $readini(%f, %sec, exact)
  var %is_regex = $readini(%f, %sec, is_regex)
  var %target = $readini(%f, %sec, target)
  var %sound = $readini(%f, %sec, sound)
  
  did -ra %d 21 %w
  
  if (%act == 1) did -c %d 22
  else did -u %d 22
  
  if (%exact == 1) did -c %d 23
  else did -u %d 23
  
  if (%is_regex == 1) did -c %d 24
  else did -u %d 24
  
  did -u %d 30
  did -u %d 31
  did -u %d 32
  if (%target isin active salon) did -c %d 30
  elseif (%target == fenetre) did -c %d 31
  else did -c %d 32
  
  did -ra %d 40 %sound
}

; Réinitialisation des champs du dialogue
alias -l hl_dialog_clear_form {
  if (!$dialog(hl_dialog)) return
  var %d = hl_dialog
  did -ra %d 21 $null
  did -c %d 22
  did -c %d 23
  did -u %d 24
  did -u %d 30
  did -u %d 31
  did -c %d 32
  did -ra %d 40 $null
  did -u %d 10
  did -f %d 21
}

; ------------------------------------------------------------------------------
; BOÎTE DE DIALOGUE MODALE : ASSISTANT & EXEMPLES REGEX
; ------------------------------------------------------------------------------
dialog hl_regex_help {
  title "Assistant & Exemples de Saisies Regex (mIRC)"
  size -1 -1 680 440
  option pixels

  box "Exemples prêts à l'emploi (Double-clic pour insérer directement)", 1, 14 14 652 230
  list 10, 24 38 632 194, vsbar

  box "Détails & Explication de la sélection", 2, 14 252 652 130
  text "Motif Regex :", 20, 24 274 90 16
  edit "", 21, 120 272 532 22, read autohs
  text "Description :", 22, 24 302 90 16
  edit "", 23, 120 300 532 70, read multi vsbar

  button "Insérer dans le formulaire", 11, 330 394 180 28, default
  button "Fermer", 12, 522 394 144 28, cancel
}

on *:dialog:hl_regex_help:init:0: {
  var %p = $chr(124)
  did -a $dname 10 1. Variantes de pseudonyme : /(?i)\b(yannick $+ %p $+ yan $+ %p $+ yann)\b/
  did -a $dname 10 2. Mots de salutations : /(?i)\b(salut $+ %p $+ bonjour $+ %p $+ coucou $+ %p $+ hello $+ %p $+ hey $+ %p $+ yo)\b/
  did -a $dname 10 3. Question contenant votre pseudo : /(?i)\byannick\b.*\?/
  did -a $dname 10 4. Début de ligne (Mention directe) : /^yannick[:, ]/i
  did -a $dname 10 5. Liens HTTP / Liens Web : /https?:\/\/[^\s]+/i
  did -a $dname 10 6. Adresses IP (IPv4) : /\b(?:\d{1,3}\.){3}\d{1,3}\b/
  did -a $dname 10 7. Demandes d'aide / Urgences : /(?i)\b(aide $+ %p $+ help $+ %p $+ urgent $+ %p $+ sos $+ %p $+ bug)\b/
  did -a $dname 10 8. Répétition abusive de lettres : /(.)\1{3,}/
  did -a $dname 10 9. Pseudos avec suffixe joker IRC : /^yannick[0-9_]*/i
  did -a $dname 10 10. Mots sensibles & Modération : /(?i)\b(ban $+ %p $+ kick $+ %p $+ hack $+ %p $+ cheat $+ %p $+ spam)\b/

  did -c $dname 10 1
  hl_regex_help_update 1
}

on *:dialog:hl_regex_help:sclick:10: {
  var %sel = $did(10).sel
  if (%sel) hl_regex_help_update %sel
}

on *:dialog:hl_regex_help:dclick:10: {
  var %sel = $did(10).sel
  if (%sel) {
    hl_regex_help_update %sel
    hl_regex_help_insert
  }
}

on *:dialog:hl_regex_help:sclick:11: {
  hl_regex_help_insert
}

alias -l hl_regex_help_update {
  var %d = hl_regex_help
  var %idx = $1
  var %pat = $null
  var %desc = $null
  var %p = $chr(124)

  if (%idx == 1) {
    %pat = /(?i)\b(yannick $+ %p $+ yan $+ %p $+ yann)\b/
    %desc = Détecte le pseudo exact ainsi que ses diminutifs courants (ex: yannick, yan, yann), séparés par des frontières de mot (\b). Idéal pour ne rater aucun appel sous différentes abréviations.
  }
  elseif (%idx == 2) {
    %pat = /(?i)\b(salut $+ %p $+ bonjour $+ %p $+ coucou $+ %p $+ hello $+ %p $+ hey $+ %p $+ yo)\b/
    %desc = Alerte lorsque quelqu'un salue le salon (salut, bonjour, coucou, hello, hey, yo). Insensible à la casse grâce au modificateur (?i).
  }
  elseif (%idx == 3) {
    %pat = /(?i)\byannick\b.*\?/
    %desc = Déclenche une alerte quand une phrase contient votre pseudonyme ET se termine ou contient un point d'interrogation. Permet d'isoler les questions qui vous sont directement posées.
  }
  elseif (%idx == 4) {
    %pat = /^yannick[:, ]/i
    %desc = Détecte les messages où une personne s'adresse directement à vous en début de phrase (ex: 'Yannick: viens voir', 'Yannick, réponds').
  }
  elseif (%idx == 5) {
    %pat = /https?:\/\/[^\s]+/i
    %desc = Capture tous les liens web (adresses débutant par http:// ou https://) partagés sur le salon. Pratique pour être notifié de chaque lien envoyé.
  }
  elseif (%idx == 6) {
    %pat = /\b(?:\d{1,3}\.){3}\d{1,3}\b/
    %desc = Détecte le partage d'adresses IPv4 numériques (ex: 192.168.1.1). Utile pour surveiller les partages de serveurs, jeux ou connexions directes.
  }
  elseif (%idx == 7) {
    %pat = /(?i)\b(aide $+ %p $+ help $+ %p $+ urgent $+ %p $+ sos $+ %p $+ bug)\b/
    %desc = Détecte les appels à l'aide ou signalements de problèmes (aide, help, urgent, sos, bug). Parfait pour les administrateurs et modérateurs.
  }
  elseif (%idx == 8) {
    %pat = /(.)\1{3,}/
    %desc = Détecte les lettres ou caractères répétés au moins 4 fois d'affilée (ex: heeeeeelp, noooon, !!!!!!). Efficace pour détecter les cris ou le flood.
  }
  elseif (%idx == 9) {
    %pat = /^yannick[0-9_]*/i
    %desc = Détecte votre pseudo suivi de chiffres ou de tirets/underscores (ex: Yannick1, Yannick_afk, Yannick_work).
  }
  elseif (%idx == 10) {
    %pat = /(?i)\b(ban $+ %p $+ kick $+ %p $+ hack $+ %p $+ cheat $+ %p $+ spam)\b/
    %desc = Liste de mots clés de sécurité ou de modération. Alerte dès qu'un utilisateur évoque ces thèmes sur le canal.
  }

  did -ra %d 21 %pat
  did -ra %d 23 %desc
}

alias -l hl_regex_help_insert {
  var %pat = $did(hl_regex_help, 21).text
  if (%pat && $dialog(hl_dialog)) {
    did -ra hl_dialog 21 %pat
    did -c hl_dialog 24
    did -u hl_dialog 23
    dialog -x hl_regex_help
    did -f hl_dialog 21
    echo -a $chr(3) $+ 10*** Motif regex inséré dans le Highlight avec le Mode Regex activé !
  }
}

; ------------------------------------------------------------------------------
; COMMANDES CONSOLE (/hl ...)
; ------------------------------------------------------------------------------
alias hl {
  ; Sans argument : ouvre l'interface avec génération de la bannière si besoin
  if ($1 == $null) {
    if (!$dialog(hl_dialog)) {
      hl_assets
      dialog -m hl_dialog hl_dialog
    }
    return
  }
  
  ; /hl on : active le système global
  if ($1 == on) {
    writeini $hl_ini General enabled 1
    if ($dialog(hl_dialog)) {
      did -c hl_dialog 8
      hl_assets
      did -g hl_dialog 1 $shortfn($hl_dir $+ banner.bmp)
    }
    echo -a $chr(3) $+ 03*** Système de Highlights : ACTIVÉ
    return
  }
  
  ; /hl off : désactive le système global
  if ($1 == off) {
    writeini $hl_ini General enabled 0
    if ($dialog(hl_dialog)) {
      did -u hl_dialog 8
      hl_assets
      did -g hl_dialog 1 $shortfn($hl_dir $+ banner.bmp)
    }
    echo -a $chr(3) $+ 04*** Système de Highlights : DÉSACTIVÉ
    return
  }
  
  ; /hl toggle : bascule l'état
  if ($1 == toggle) {
    var %cur = $hl_get_cfg(enabled, 1)
    if (%cur == 1) hl off
    else hl on
    return
  }
  
  ; /hl win : ouvre la fenêtre @Highlights
  if ($1 == win) {
    hl_win
    return
  }
  
  ; /hl clear : vide la fenêtre @Highlights
  if ($1 == clear) {
    if ($window(@Highlights)) clear @Highlights
    echo -a $chr(3) $+ 10*** Journal de la fenêtre @Highlights vidé.
    return
  }
  
  ; /hl test <mot ou phrase>
  if ($1 == test) {
    var %txt = $2-
    if (!%txt) {
      %txt = $me Ceci est un message test pour vérifier le highlight !
    }
    var %chan = $iif($active ischan, $active, #Accueil)
    var %test_nick = $iif($me, $me, Yannick80)
    unset %hl_last_match
    hl_check_msg text %chan %test_nick %txt
    if (!%hl_last_match) {
      echo -a $chr(3) $+ 04*** Aucun mot clé Highlight détecté dans : $chr(15) $+ %txt
      echo -a $chr(3) $+ 14(Vérifiez que le mot est actif dans /hl et orthographié de la même manière)
    }
    else {
      echo -a $chr(3) $+ 03*** Test Highlight réussi ! Destination : %hl_last_match
    }
    return
  }
  
  ; /hl list : affiche la liste dans la console
  if ($1 == list) {
    var %f = $hl_file
    var %total = $readini(%f, General, count)
    echo -a $chr(3) $+ 10═════════ Liste des Highlights (%total mots) ═════════
    var %i = 1
    while (%i <= %total) {
      var %sec = $hl_sec(%i)
      var %w = $readini(%f, %sec, word)
      var %act = $iif($readini(%f, %sec, active) == 1, $chr(3) $+ 03ON $+ $chr(15), $chr(3) $+ 04OFF $+ $chr(15))
      var %tar = $readini(%f, %sec, target)
      var %snd = $iif($readini(%f, %sec, sound), $nopath($readini(%f, %sec, sound)), Sans son)
      var %is_reg = $iif($readini(%f, %sec, is_regex) == 1, [REG] , )
      echo -a $chr(3) $+ 14# $+ %i $chr(15) $+ %is_reg $+ %w - $chr(91) $+ %act $+ $chr(93) - Affichage: %tar - Son: %snd
      inc %i
    }
    echo -a $chr(3) $+ 10══════════════════════════════════════════════════════
    return
  }
  
  ; /hl add <mot> [active/fenetre/both] [chemin_du_son]
  if ($1 == add) {
    if ($2 == $null) {
      echo -a $chr(3) $+ 04Syntaxe : /hl add <mot> [active/fenetre/both] [chemin_du_son]
      return
    }
    var %w = $2
    var %f = $hl_file
    var %count = $readini(%f, General, count)
    if (!%count) %count = 0
    
    ; Vérification anti-doublon
    var %chk = 1
    while (%chk <= %count) {
      if ($lower(%w) == $lower($readini(%f, $hl_sec(%chk), word))) {
        echo -a $chr(3) $+ 04*** Erreur : Le mot ' $+ %w $+ ' existe déjà dans la liste des Highlights (# $+ %chk $+ ).
        return
      }
      inc %chk
    }
    
    var %target = $iif($3 isin active fenetre both, $3, both)
    if ($3 == salon) %target = active
    var %snd = $4-
    
    inc %count
    var %sec = $hl_sec(%count)
    
    writeini $hl_ini General count %count
    writeini $hl_ini %sec word %w
    writeini $hl_ini %sec active 1
    writeini $hl_ini %sec exact 1
    writeini $hl_ini %sec is_regex 0
    writeini $hl_ini %sec target %target
    writeini $hl_ini %sec sound %snd
    
    echo -a $chr(3) $+ 03*** Highlight ' $+ %w $+ ' ajouté avec succès (# $+ %count $+  - Affichage: %target $+ ).
    if ($dialog(hl_dialog)) hl_dialog_refresh_list %count
    return
  }
  
  ; /hl del <mot_ou_index>
  if ($1 == del) {
    if ($2 == $null) {
      echo -a $chr(3) $+ 04Syntaxe : /hl del <mot_ou_numéro>
      return
    }
    var %f = $hl_file
    var %total = $readini(%f, General, count)
    var %target_id = $null
    
    if ($2 isnum 1-%total) {
      %target_id = $2
    }
    else {
      var %i = 1
      while (%i <= %total) {
        if ($readini(%f, $hl_sec(%i), word) == $2) {
          %target_id = %i
          break
        }
        inc %i
      }
    }
    
    if (%target_id) {
      var %delw = $readini(%f, $hl_sec(%target_id), word)
      hl_del_entry %target_id
      echo -a $chr(3) $+ 04*** Highlight ' $+ %delw $+ ' supprimé.
      if ($dialog(hl_dialog)) {
        hl_dialog_refresh_list
        hl_dialog_clear_form
      }
    }
    else {
      echo -a $chr(3) $+ 04*** Mot ou index introuvable : $2
    }
    return
  }
  
  echo -a $chr(3) $+ 04Commande inconnue. Syntaxe : /hl, /hl on, /hl off, /hl win, /hl list, /hl test, /hl add <mot>, /hl del <mot>, /hl clear
}

; ------------------------------------------------------------------------------
; MENUS CONTEXTUELS
; ------------------------------------------------------------------------------
menu menubar {
  Highlights
  .Panneau de Configuration (/hl):hl
  .Ouvrir la fenêtre @Highlights:/hl win
  .-
  .Système ($iif($hl_get_cfg(enabled, 1) == 1,Activé,Désactivé))
  ..Activer:/hl on
  ..Désactiver:/hl off
  .-
  .Vider la fenêtre @Highlights:/hl clear
}

menu channel,status,query {
  Highlights
  .Ajouter un mot en Highlight...:{
    var %m = $input(Entrez le mot à ajouter en Highlight :, e, Nouveau Highlight)
    if (%m) hl add %m both
  }
  .Tester un Highlight (/hl test)...:{
    var %t = $input(Entrez une phrase pour tester la détection :, e, Tester un Highlight)
    if (%t) hl test %t
  }
  .Panneau de Configuration...:hl
  .Ouvrir la fenêtre @Highlights:hl win
}

menu nicklist {
  Highlights
  .Ajouter $$1 en Highlight (Les deux):hl add $$1 both
  .Ajouter $$1 en Highlight (Fenêtre active uniquement):hl add $$1 active
  .Ajouter $$1 en Highlight (Fenêtre @Highlights uniquement):hl add $$1 fenetre
  .-
  .Panneau de Configuration...:hl
  .Ouvrir la fenêtre @Highlights:hl win
}
