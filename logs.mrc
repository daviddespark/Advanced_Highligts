; ==============================================================================
; LOG MANAGER v1.0 POUR mIRC
; Auteur : Paradoxe80
; Description : Gestionnaire de logs avancé multi-serveurs avec interface graphique,
;               archivage automatique classé par réseau, et visionneuse intégrée.
; ==============================================================================

; ------------------------------------------------------------------------------
; CHEMINS, DOSSIERS ET FICHIERS DE CONFIGURATION
; ------------------------------------------------------------------------------
alias -l log_ini {
  return $scriptdir $+ logs.ini
}

alias -l log_dir {
  return $scriptdir $+ logs_assets\
}

alias -l log_root {
  return $mircdir $+ logs\
}

alias -l log_sec {
  return Target_ $+ $1
}

alias -l log_get_cfg {
  var %val = $readini($log_ini, General, $1)
  if (%val != $null) return %val
  return $2
}

alias -l log_set_cfg {
  writeini $log_ini General $1 $2
}

; ------------------------------------------------------------------------------
; GÉNÉRATION DE LA BANNIÈRE GRAPHIQUE (DESIGN MODERNE EN PIXELS)
; ------------------------------------------------------------------------------
alias -l log_assets {
  var %dir = $log_dir
  if (!$isdir(%dir)) mkdir $qt(%dir)
  var %w = @log_draw
  if ($window(%w)) window -c %w
  
  ; Création d'une fenêtre hors écran pour dessiner la bannière (840x64 pixels)
  window -hpfB %w 0 0 840 64
  
  ; Dégradé sombre bleuté moderne
  drawrect -rfn %w $rgb(16,20,32) 1 0 0 840 64
  drawrect -rfn %w $rgb(26,34,54) 1 0 0 840 32
  
  ; Liseré multicolore moderne en bas de la bannière (dégradé Cyan -> Indigo -> Violet)
  var %k = 0
  while (%k < 14) {
    var %col = $rgb($calc(20 + %k * 14), $calc(130 + %k * 6), $calc(240 - %k * 8))
    drawrect -rfn %w %col 1 $calc(%k * 60) 60 60 4
    inc %k
  }
  
  ; Badge d'état global dynamique à droite
  var %sys_st = $log_get_cfg(enabled, 1)
  var %st_bg = $iif(%sys_st == 1, $rgb(36,160,82), $rgb(210,45,45))
  var %st_txt = $iif(%sys_st == 1, SYSTEME ACTIF, SYSTEME EN PAUSE)
  drawrect -rfn %w %st_bg 1 670 18 145 28
  drawrect -rn %w $rgb(255,255,255) 1 670 18 145 28
  drawtext -nro %w $rgb(255,255,255) Verdana 11 685 24 %st_txt
  
  ; Titre et sous-titre
  drawtext -nro %w $rgb(255,255,255) Verdana 17 20 8 Log Manager par Paradoxe80
  drawtext -nr %w $rgb(165,185,225) Verdana 10 22 36 Archivage automatique multi-serveurs, classe par reseau & visionneuse
  
  drawsave %w $qt(%dir $+ banner_logs.bmp)
  window -c %w
}

; ------------------------------------------------------------------------------
; INTERFACE GRAPHIQUE (DIALOG / GUI) - DESIGN HAUTE QUALITÉ EN PIXELS
; ------------------------------------------------------------------------------
dialog log_dialog {
  title "Log Manager v1.0 - Gestionnaire d'Archivage Multi-Serveurs"
  size -1 -1 840 516
  option pixels

  ; Bannière graphique d'en-tête (840x64)
  icon 1, 0 0 840 64, $mircexe, 0, noborder

  ; Panneau Gauche : Salons & Cibles configurés (w=380, h=390)
  box "Salons et Cibles configurés pour l'archivage", 2, 14 74 380 390
  list 10, 24 98 360 310, vsbar
  button "+ Ajouter salon actuel", 51, 24 422 145 28
  button "Activer / Pause", 52, 175 422 110 28
  button "Supprimer", 53, 291 422 93 28

  ; Panneau Droit : Paramètres de la cible sélectionnée (w=418, h=390)
  box "Paramètres de la cible sélectionnée", 3, 408 74 418 390
  text "Réseau / Serveur IRC :", 20, 424 96 170 16
  combo 21, 424 114 180 140, drop
  text "Salon ou Masque (ex: #salon ou *) :", 22, 614 96 200 16
  edit "", 23, 614 114 196 24, autohs
  
  check "Archivage actif pour cette cible", 24, 424 146 386 20
  
  box "Événements à enregistrer", 25, 424 172 386 100
  check "Messages texte (TEXT)", 26, 436 192 180 18
  check "Actions (/me)", 27, 626 192 170 18
  check "Entrées / Départs (JOIN / PART)", 28, 436 216 186 18
  check "Déconnexions (QUIT)", 29, 626 216 170 18
  check "Kicks & Changements de pseudo", 30, 436 240 186 18
  check "Modes & Topics", 31, 626 240 170 18

  text "Rotation et découpage des fichiers :", 32, 424 280 386 16
  radio "1 fichier par jour (ex: #salon_2026-11-01.log)", 33, 424 298 380 18, group
  radio "1 fichier par mois (ex: #salon_2026-11.log)", 34, 424 318 380 18
  radio "1 fichier continu (ex: #salon.log)", 35, 424 338 380 18

  text "Format d'horodatage :", 36, 424 364 160 16
  combo 37, 424 382 180 120, drop

  button "Enregistrer cible", 54, 424 422 180 28
  button "Nouvelle cible", 55, 614 422 196 28

  ; Barre inférieure globale
  check "Activer l'archivage global des logs", 8, 14 476 225 24
  check "Archiver aussi les Privés (PV)", 9, 245 476 195 24
  button "Ouvrir dossier logs", 60, 448 474 125 28
  button "Visionneuse @Logs", 61, 580 474 135 28
  button "Fermer", 70, 723 474 103 28, ok
}

; ------------------------------------------------------------------------------
; INITIALISATION DU DIALOGUE
; ------------------------------------------------------------------------------
on *:dialog:log_dialog:init:0: {
  ; Générer et appliquer la bannière graphique
  log_assets
  did -g $dname 1 $shortfn($log_dir $+ banner_logs.bmp)

  ; Charger les réglages généraux
  if ($log_get_cfg(enabled, 1) == 1) did -c $dname 8
  if ($log_get_cfg(log_pv, 1) == 1) did -c $dname 9

  ; Peupler la liste des réseaux dans le combo 21
  did -r $dname 21
  did -a $dname 21 Tous les réseaux (*)
  var %i = 1
  while (%i <= $scon(0)) {
    var %net = $scid(%i).network
    if (%net == $null) %net = $scid(%i).server
    if (%net != $null) {
      ; Ajouter si pas encore présent dans le combo
      var %idx = 1, %found = 0
      while (%idx <= $did($dname, 21).lines) {
        if ($did($dname, 21, %idx).text == %net) { %found = 1 | break }
        inc %idx
      }
      if (%found == 0) did -a $dname 21 %net
    }
    inc %i
  }
  did -c $dname 21 1

  ; Peupler les formats d'horodatage dans le combo 37
  did -r $dname 37
  did -a $dname 37 [HH:nn:ss]
  did -a $dname 37 [HH:nn]
  did -a $dname 37 (HH:nn:ss)
  did -a $dname 37 HH:nn:ss
  did -c $dname 37 1

  ; Valeurs par défaut du formulaire de droite
  log_dialog_clear_form

  ; Charger la liste des cibles configurées
  log_dialog_refresh_list
}

on *:dialog:log_dialog:close:0: {
  if ($window(@log_draw)) window -c @log_draw
}

; ------------------------------------------------------------------------------
; GESTIONNAIRES D'ÉVÉNEMENTS DU DIALOGUE
; ------------------------------------------------------------------------------

; Clic sur "Activer l'archivage global des logs"
on *:dialog:log_dialog:sclick:8: {
  log_set_cfg enabled $did(8).state
  log_assets
  did -g $dname 1 $shortfn($log_dir $+ banner_logs.bmp)
}

; Clic sur "Archiver aussi les Privés (PV)"
on *:dialog:log_dialog:sclick:9: {
  log_set_cfg log_pv $did(9).state
}

; Bouton "Ouvrir dossier logs" (Explorateur Windows)
on *:dialog:log_dialog:sclick:60: {
  var %p = $log_root
  if (!$isdir(%p)) mkdir $qt(%p)
  run explorer.exe $qt(%p)
}

; Bouton "Visionneuse @Logs"
on *:dialog:log_dialog:sclick:61: {
  log_viewer_open
}

; Sélection d'un élément dans la liste
on *:dialog:log_dialog:sclick:10: {
  var %sel = $did(10).sel
  if (%sel == $null) %sel = $log_extract_id($did(10).seltext)
  if (%sel != $null) {
    log_dialog_load_target %sel
  }
}

; Double-clic sur un élément dans la liste
on *:dialog:log_dialog:dclick:10: {
  var %sel = $did(10).sel
  if (%sel == $null) %sel = $log_extract_id($did(10).seltext)
  if (%sel != $null) {
    log_dialog_load_target %sel
    did -f $dname 23
  }
}

; Bouton "Nouvelle cible" (vider formulaire)
on *:dialog:log_dialog:sclick:55: {
  log_dialog_clear_form
  did -f $dname 23
}

; Bouton "+ Ajouter salon actuel" (détecte salon actif et réseau)
on *:dialog:log_dialog:sclick:51: {
  var %chan = $active
  var %net = $network
  if (%net == $null) %net = $server
  
  if ($left(%chan, 1) != #) {
    noop $input(Vous devez être positionné sur une fenêtre de salon pour ajouter le salon actuel. $+ $crlf $+ Salon détecté : %chan, o w, Salon invalide)
    return
  }

  ; Sélectionner le réseau dans le combo si possible
  var %idx = 1, %found = 0
  while (%idx <= $did(21).lines) {
    if ($did(21, %idx).text == %net) {
      did -c $dname 21 %idx
      %found = 1
      break
    }
    inc %idx
  }
  if (%found == 0) {
    did -a $dname 21 %net
    did -c $dname 21 $did(21).lines
  }

  did -ra $dname 23 %chan
  did -c $dname 24
  did -f $dname 54
  echo -a $chr(3) $+ 10*** Préparation de l'archivage pour %chan sur le réseau %net. Cliquez sur 'Enregistrer cible' pour confirmer.
}

; Bouton "Activer / Pause" (Bascule l'état de la cible)
on *:dialog:log_dialog:sclick:52: {
  var %sel = $did(10).sel
  if (%sel == $null) %sel = $log_extract_id($did(10).seltext)
  if (%sel == $null) {
    noop $input(Veuillez sélectionner un salon dans la liste pour modifier son état., o w, Aucune sélection)
    return
  }
  var %f = $log_ini
  var %sec = $log_sec(%sel)
  var %act = $readini(%f, %sec, active)
  var %nact = $iif(%act == 1, 0, 1)
  writeini %f %sec active %nact
  log_dialog_refresh_list %sel
}

; Bouton "Supprimer"
on *:dialog:log_dialog:sclick:53: {
  var %sel = $did(10).sel
  if (%sel == $null) %sel = $log_extract_id($did(10).seltext)
  if (%sel == $null) {
    noop $input(Veuillez sélectionner un salon dans la liste à supprimer., o w, Aucune sélection)
    return
  }
  var %f = $log_ini
  var %sec = $log_sec(%sel)
  var %tgt = $readini(%f, %sec, chan)
  
  var %rep = $input(Voulez-vous vraiment supprimer l'archivage configuré pour ' $+ %tgt $+ ' ?, y n q, Confirmation de suppression)
  if (%rep != yes) return

  log_delete_target %sel
  log_dialog_refresh_list
  log_dialog_clear_form
  echo -a $chr(3) $+ 04*** Salon %tgt supprimé des cibles d'archivage.
}

; Bouton "Enregistrer cible" (Ajout ou Modification)
on *:dialog:log_dialog:sclick:54: {
  var %d = $dname
  var %chan = $strip($did(23).text)
  if (%chan == $null) {
    noop $input(Veuillez spécifier un nom de salon (ex: #accueil ou * pour tous)., o w, Champ obligatoire)
    return
  }
  
  var %net = $did(21).text
  var %active = $did(24).state
  var %log_msg = $did(26).state
  var %log_act = $did(27).state
  var %log_joinpart = $did(28).state
  var %log_quit = $did(29).state
  var %log_kick = $did(30).state
  var %log_topic = $did(31).state

  var %rotation = daily
  if ($did(34).state == 1) %rotation = monthly
  elseif ($did(35).state == 1) %rotation = continuous

  var %timestamp = $did(37).text
  if (%timestamp == $null) %timestamp = [HH:nn:ss]

  var %f = $log_ini
  var %count = $readini(%f, General, count)
  if (%count == $null) %count = 0

  ; Vérifier si on modifie une entrée sélectionnée existante
  var %sel = $did(10).sel
  if (%sel == $null) %sel = $log_extract_id($did(10).seltext)

  ; Si le salon sélectionné correspond au formulaire, on met à jour
  var %target_id = $null
  if (%sel != $null) && (%sel <= %count) {
    var %cur_chan = $readini(%f, $log_sec(%sel), chan)
    var %cur_net = $readini(%f, $log_sec(%sel), network)
    if ($lower(%cur_chan) == $lower(%chan)) && ($lower(%cur_net) == $lower(%net)) {
      %target_id = %sel
    }
  }

  ; Sinon, vérification anti-doublon parmi tous les éléments
  if (%target_id == $null) {
    var %i = 1
    while (%i <= %count) {
      var %ex_c = $readini(%f, $log_sec(%i), chan)
      var %ex_n = $readini(%f, $log_sec(%i), network)
      if ($lower(%ex_c) == $lower(%chan)) && ($lower(%ex_n) == $lower(%net)) {
        var %upd = $input(Cette cible existe déjà (# $+ %i $+ ). Souhaitez-vous mettre à jour ses paramètres ?, y n q, Cible existante)
        if (%upd == yes) {
          %target_id = %i
          break
        }
        else return
      }
      inc %i
    }
  }

  ; Nouveau ou mise à jour
  if (%target_id == $null) {
    inc %count
    %target_id = %count
    writeini %f General count %count
  }

  var %sec = $log_sec(%target_id)
  writeini %f %sec network %net
  writeini %f %sec chan %chan
  writeini %f %sec active %active
  writeini %f %sec log_msg %log_msg
  writeini %f %sec log_act %log_act
  writeini %f %sec log_joinpart %log_joinpart
  writeini %f %sec log_quit %log_quit
  writeini %f %sec log_kick %log_kick
  writeini %f %sec log_topic %log_topic
  writeini %f %sec rotation %rotation
  writeini %f %sec timestamp %timestamp

  log_dialog_refresh_list %target_id
  noop $input(La cible d'archivage pour ' $+ %chan $+ ' ( $+ %net $+ ) a été enregistrée avec succès !, o i, Enregistrement réussi)
  echo -a $chr(3) $+ 03*** Configuration d'archivage enregistrée pour %chan sur %net (# $+ %target_id $+ ).
}

; ------------------------------------------------------------------------------
; ALIAS UTILITAIRES POUR LE DIALOGUE
; ------------------------------------------------------------------------------

alias -l log_extract_id {
  var %tok = $gettok($1, 1, 32)
  if (#* iswm %tok) return $remove(%tok, #)
  return $null
}

alias -l log_dialog_clear_form {
  if (!$dialog(log_dialog)) return
  var %d = log_dialog
  did -ra %d 23 $null
  did -c %d 24
  did -c %d 26
  did -c %d 27
  did -c %d 28
  did -c %d 29
  did -c %d 30
  did -c %d 31
  did -c %d 33
  did -u %d 34
  did -u %d 35
  did -c %d 37 1
}

alias -l log_dialog_refresh_list {
  if (!$dialog(log_dialog)) return
  var %d = log_dialog
  var %sel_id = $1
  var %f = $log_ini
  var %total = $readini(%f, General, count)
  if (%total == $null) %total = 0

  did -r %d 10

  var %i = 1
  while (%i <= %total) {
    var %sec = $log_sec(%i)
    var %chan = $readini(%f, %sec, chan)
    if (%chan != $null) {
      var %net = $readini(%f, %sec, network)
      if (%net == $null) %net = Tous
      var %act = $readini(%f, %sec, active)
      var %act_txt = $iif(%act == 1, ON, OFF)
      var %rot = $readini(%f, %sec, rotation)
      var %rot_txt = Jour
      if (%rot == monthly) %rot_txt = Mois
      elseif (%rot == continuous) %rot_txt = Continu

      var %line_txt = $chr(35) $+ %i $chr(91) $+ %act_txt $+ $chr(93) $chr(91) $+ %net $+ $chr(93) %chan ( $+ %rot_txt $+ )
      did -a %d 10 %line_txt

      if (%sel_id == %i) {
        did -c %d 10 %i
      }
    }
    inc %i
  }

  if (%sel_id != $null) && (%sel_id <= %total) {
    log_dialog_load_target %sel_id
  }
}

alias -l log_dialog_load_target {
  if (!$dialog(log_dialog)) return
  var %d = log_dialog
  var %id = $1
  if (%id !isnum) return
  var %f = $log_ini
  var %sec = $log_sec(%id)

  var %chan = $readini(%f, %sec, chan)
  if (%chan == $null) return

  var %net = $readini(%f, %sec, network)
  var %active = $readini(%f, %sec, active)
  var %log_msg = $readini(%f, %sec, log_msg)
  var %log_act = $readini(%f, %sec, log_act)
  var %log_joinpart = $readini(%f, %sec, log_joinpart)
  var %log_quit = $readini(%f, %sec, log_quit)
  var %log_kick = $readini(%f, %sec, log_kick)
  var %log_topic = $readini(%f, %sec, log_topic)
  var %rotation = $readini(%f, %sec, rotation)
  var %timestamp = $readini(%f, %sec, timestamp)

  ; Sélection réseau dans combo
  var %idx = 1, %found = 0
  while (%idx <= $did(21).lines) {
    if ($did(21, %idx).text == %net) {
      did -c %d 21 %idx
      %found = 1
      break
    }
    inc %idx
  }
  if (%found == 0) {
    did -a %d 21 %net
    did -c %d 21 $did(21).lines
  }

  did -ra %d 23 %chan
  if (%active == 1) did -c %d 24
  else did -u %d 24

  if (%log_msg == 1) did -c %d 26
  else did -u %d 26

  if (%log_act == 1) did -c %d 27
  else did -u %d 27

  if (%log_joinpart == 1) did -c %d 28
  else did -u %d 28

  if (%log_quit == 1) did -c %d 29
  else did -u %d 29

  if (%log_kick == 1) did -c %d 30
  else did -u %d 30

  if (%log_topic == 1) did -c %d 31
  else did -u %d 31

  ; Rotation
  did -u %d 33
  did -u %d 34
  did -u %d 35
  if (%rotation == monthly) did -c %d 34
  elseif (%rotation == continuous) did -c %d 35
  else did -c %d 33

  ; Timestamp
  var %t_idx = 1
  while (%t_idx <= $did(37).lines) {
    if ($did(37, %t_idx).text == %timestamp) {
      did -c %d 37 %t_idx
      break
    }
    inc %t_idx
  }
}

alias -l log_delete_target {
  var %del_id = $1
  var %f = $log_ini
  var %total = $readini(%f, General, count)
  if (%total == $null) return
  if (%del_id !isnum) || (%del_id > %total) return

  remini %f $log_sec(%del_id)

  var %i = $calc(%del_id + 1)
  while (%i <= %total) {
    var %prev = $calc(%i - 1)
    writeini %f $log_sec(%prev) network $readini(%f, $log_sec(%i), network)
    writeini %f $log_sec(%prev) chan $readini(%f, $log_sec(%i), chan)
    writeini %f $log_sec(%prev) active $readini(%f, $log_sec(%i), active)
    writeini %f $log_sec(%prev) log_msg $readini(%f, $log_sec(%i), log_msg)
    writeini %f $log_sec(%prev) log_act $readini(%f, $log_sec(%i), log_act)
    writeini %f $log_sec(%prev) log_joinpart $readini(%f, $log_sec(%i), log_joinpart)
    writeini %f $log_sec(%prev) log_quit $readini(%f, $log_sec(%i), log_quit)
    writeini %f $log_sec(%prev) log_kick $readini(%f, $log_sec(%i), log_kick)
    writeini %f $log_sec(%prev) log_topic $readini(%f, $log_sec(%i), log_topic)
    writeini %f $log_sec(%prev) rotation $readini(%f, $log_sec(%i), rotation)
    writeini %f $log_sec(%prev) timestamp $readini(%f, $log_sec(%i), timestamp)
    remini %f $log_sec(%i)
    inc %i
  }

  dec %total
  writeini %f General count %total
}

; ------------------------------------------------------------------------------
; MOTEUR D'ARCHIVAGE AUTOMATIQUE (CLASSIFICATION PAR SERVEUR / RÉSEAU)
; ------------------------------------------------------------------------------

alias -l log_format_line {
  var %fmt = $1
  var %text = $2-
  var %t_str = $asctime(%fmt)
  if (%t_str == $null) %t_str = $asctime([HH:nn:ss])
  return %t_str %text
}

alias -l log_sanitize_dir {
  var %s = $1
  %s = $remove(%s, :, *, ?, ", <, >, |, /)
  return %s
}

; Écriture sécurisée d'un événement dans le fichier log approprié
alias -l log_write_entry {
  ; Paramètres : 1=Réseau, 2=Cible/Salon, 3=TypeEvent, 4=Texte
  var %net = $1
  var %target = $2
  var %ev_type = $3
  var %msg = $4-

  if ($log_get_cfg(enabled, 1) != 1) return

  var %f = $log_ini
  var %total = $readini(%f, General, count)
  if (%total == $null) %total = 0

  ; Recherche d'une règle applicable
  var %i = 1, %matched = 0, %rule_id = 0
  while (%i <= %total) {
    var %sec = $log_sec(%i)
    if ($readini(%f, %sec, active) == 1) {
      var %r_net = $readini(%f, %sec, network)
      var %r_chan = $readini(%f, %sec, chan)
      
      var %net_match = 0
      if (%r_net == $null) || (%r_net == Tous les réseaux (*)) || (%r_net == *) || ($lower(%r_net) == $lower(%net)) {
        %net_match = 1
      }
      
      var %chan_match = 0
      if (%r_chan == *) || ($lower(%r_chan) == $lower(%target)) || (%r_chan iswm %target) {
        %chan_match = 1
      }

      if (%net_match == 1) && (%chan_match == 1) {
        ; Vérifier si ce type d'événement est coché
        var %allowed = 1
        if (%ev_type == msg) && ($readini(%f, %sec, log_msg) == 0) %allowed = 0
        if (%ev_type == act) && ($readini(%f, %sec, log_act) == 0) %allowed = 0
        if (%ev_type == joinpart) && ($readini(%f, %sec, log_joinpart) == 0) %allowed = 0
        if (%ev_type == quit) && ($readini(%f, %sec, log_quit) == 0) %allowed = 0
        if (%ev_type == kick) && ($readini(%f, %sec, log_kick) == 0) %allowed = 0
        if (%ev_type == topic) && ($readini(%f, %sec, log_topic) == 0) %allowed = 0

        if (%allowed == 1) {
          %matched = 1
          %rule_id = %i
          break
        }
      }
    }
    inc %i
  }

  ; Si aucun salon n'est explicitement configuré mais qu'il s'agit d'un PV et log_pv est actif
  if (%matched == 0) && ($left(%target, 1) != #) {
    if ($log_get_cfg(log_pv, 1) == 1) {
      %matched = 1
    }
  }

  if (%matched == 0) return

  ; Récupérer rotation et timestamp configurés (ou valeurs par défaut)
  var %rot = daily, %t_fmt = [HH:nn:ss]
  if (%rule_id > 0) {
    var %sec = $log_sec(%rule_id)
    if ($readini(%f, %sec, rotation) != $null) %rot = $readini(%f, %sec, rotation)
    if ($readini(%f, %sec, timestamp) != $null) %t_fmt = $readini(%f, %sec, timestamp)
  }

  ; Construire le chemin : logs\<Network>\<Target>\
  var %clean_net = $log_sanitize_dir(%net)
  var %clean_target = $log_sanitize_dir(%target)
  var %folder = $log_root $+ %clean_net $+ \ $+ %clean_target $+ \
  if (!$isdir(%folder)) mkdir $qt(%folder)

  ; Déterminer le nom du fichier selon la rotation
  var %fname = $null
  if (%rot == monthly) {
    %fname = %clean_target $+ _ $+ $asctime(yyyy-mm) $+ .log
  }
  elseif (%rot == continuous) {
    %fname = %clean_target $+ .log
  }
  else {
    %fname = %clean_target $+ _ $+ $asctime(yyyy-mm-dd) $+ .log
  }

  var %filepath = %folder $+ %fname
  var %line = $log_format_line(%t_fmt, %msg)
  write $qt(%filepath) %line
}

; ------------------------------------------------------------------------------
; CAPTUREURS D'ÉVÉNEMENTS IRC
; ------------------------------------------------------------------------------

on *:TEXT:*:#: {
  var %net = $network
  if (%net == $null) %net = $server
  log_write_entry %net $chan msg $chr(60) $+ $nick $+ $chr(62) $1-
}

on *:ACTION:*:#: {
  var %net = $network
  if (%net == $null) %net = $server
  log_write_entry %net $chan act * %nick $1-
}

on *:INPUT:#: {
  if ($left($1, 1) != /) || ($ctrlenter) {
    var %net = $network
    if (%net == $null) %net = $server
    log_write_entry %net $chan msg $chr(60) $+ $me $+ $chr(62) $1-
  }
}

on *:JOIN:#: {
  var %net = $network
  if (%net == $null) %net = $server
  log_write_entry %net $chan joinpart *** $nick ( $+ $address $+ ) a rejoint %chan
}

on *:PART:#: {
  var %net = $network
  if (%net == $null) %net = $server
  var %reason = $iif($1-, ( $+ $1- $+ ), )
  log_write_entry %net $chan joinpart *** $nick ( $+ $address $+ ) a quitté %chan %reason
}

on *:QUIT: {
  var %net = $network
  if (%net == $null) %net = $server
  ; Enregistrer le quit sur chaque salon partagé
  var %i = 1
  while (%i <= $comchan($nick, 0)) {
    var %c = $comchan($nick, %i)
    log_write_entry %net %c quit *** $nick a quitté IRC ( $+ $1- $+ )
    inc %i
  }
}

on *:KICK:#: {
  var %net = $network
  if (%net == $null) %net = $server
  log_write_entry %net $chan kick *** $knick a été éjecté par $nick ( $+ $1- $+ )
}

on *:NICK: {
  var %net = $network
  if (%net == $null) %net = $server
  var %i = 1
  while (%i <= $comchan($newnick, 0)) {
    var %c = $comchan($newnick, %i)
    log_write_entry %net %c kick *** $nick s'appelle maintenant $newnick
    inc %i
  }
}

on *:MODE:#: {
  var %net = $network
  if (%net == $null) %net = $server
  log_write_entry %net $chan topic *** $nick a défini les modes : $1-
}

on *:TOPIC:#: {
  var %net = $network
  if (%net == $null) %net = $server
  log_write_entry %net $chan topic *** $nick a changé le topic pour : $1-
}

; Messages Privés (PV)
on *:TEXT:*:?: {
  var %net = $network
  if (%net == $null) %net = $server
  log_write_entry %net $nick msg $chr(60) $+ $nick $+ $chr(62) $1-
}

on *:ACTION:*:?: {
  var %net = $network
  if (%net == $null) %net = $server
  log_write_entry %net $nick act * %nick $1-
}

on *:INPUT:?: {
  if ($left($1, 1) != /) || ($ctrlenter) {
    var %net = $network
    if (%net == $null) %net = $server
    log_write_entry %net $target msg $chr(60) $+ $me $+ $chr(62) $1-
  }
}

; ------------------------------------------------------------------------------
; VISIONNEUSE DE LOGS INTÉGRÉE (@Logs)
; ------------------------------------------------------------------------------
alias log_viewer_open {
  if (!$window(@Logs)) {
    window -e @Logs
    titlebar @Logs - Visionneuse des Logs
    aline @Logs $chr(3) $+ 03*** Visionneuse de Logs ouverte ***
    aline @Logs $chr(3) $+ 14Faites un clic droit dans cette fenêtre pour sélectionner un salon et une date à consulter.
    aline @Logs $chr(3) $+ 14════════════════════════════════════════════════════════════════════════════════
  }
  else {
    window -a @Logs
  }
}

menu @Logs {
  Ouvrir le dossier des logs:run explorer.exe $qt($log_root)
  -
  Rechercher du texte (Ctrl+F):{
    var %txt = $input(Texte à rechercher dans les logs affichés :, e, Recherche de texte)
    if (%txt != $null) findtext %txt
  }
  -
  Vider l'affichage de cette fenêtre:clear @Logs
  Configurer Log Manager...:log_open
  Fermer:window -c @Logs
}

; ------------------------------------------------------------------------------
; COMMANDES PUBLIQUES ET MENUS mIRC
; ------------------------------------------------------------------------------
alias log {
  log_open
}

alias logs {
  log_open
}

alias log_open {
  if ($dialog(log_dialog)) dialog -v log_dialog
  else dialog -m log_dialog log_dialog
}

menu menubar {
  -
  Log Manager: {
    log_open
  }
}

menu channel {
  -
  Log Manager: {
    log_open
  }
}

menu status {
  -
  Log Manager: {
    log_open
  }
}

; Initialisation au chargement du script
on *:LOAD: {
  echo -a $chr(3) $+ 03════════════════════════════════════════════════════════════
  echo -a $chr(3) $+ 09 Log Manager v1.0 par Paradoxe80 chargé avec succès !
  echo -a $chr(3) $+ 14 Tapez $chr(3) $+ 04/log $chr(3) $+ 14pour ouvrir la fenêtre de configuration.
  echo -a $chr(3) $+ 03════════════════════════════════════════════════════════════
  log_assets
}
