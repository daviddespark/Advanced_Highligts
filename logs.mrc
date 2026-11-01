; ==============================================================================
; LOG MANAGER v1.0 POUR mIRC
; Auteur : Paradoxe80
; Description : Gestionnaire de logs avancé multi-serveurs avec interface graphique,
;               détection automatique des salons rejoints, archivage classé par
;               réseau et visionneuse complète intégrée (@Logs & Dialog).
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
  var %p = $mircdirlogs
  var %s = $shortfn(%p)
  if (%s != $null) return %s
  return %p
}

alias -l log_net_dir {
  var %p = $log_root $+ \ $+ $1
  var %s = $shortfn(%p)
  if (%s != $null) return %s
  return %p
}

alias -l log_chan_dir {
  var %p = $log_net_dir($1) $+ \ $+ $2
  var %s = $shortfn(%p)
  if (%s != $null) return %s
  return %p
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
; GÉNÉRATION DES BANNIÈRES GRAPHIQUES (DESIGN MODERNE EN PIXELS)
; ------------------------------------------------------------------------------
alias -l log_assets {
  var %dir = $log_dir
  if (!$isdir(%dir)) mkdir $qt(%dir)
  var %w = @log_draw
  if ($window(%w)) window -c %w
  
  window -hpfB %w 0 0 840 64
  drawrect -rfn %w $rgb(16,20,32) 1 0 0 840 64
  drawrect -rfn %w $rgb(26,34,54) 1 0 0 840 32
  
  var %k = 0
  while (%k < 14) {
    var %col = $rgb($calc(20 + %k * 14), $calc(130 + %k * 6), $calc(240 - %k * 8))
    drawrect -rfn %w %col 1 $calc(%k * 60) 60 60 4
    inc %k
  }
  
  var %sys_st = $log_get_cfg(enabled, 1)
  var %st_bg = $iif(%sys_st == 1, $rgb(36,160,82), $rgb(210,45,45))
  var %st_txt = $iif(%sys_st == 1, SYSTEME ACTIF, SYSTEME EN PAUSE)
  drawrect -rfn %w %st_bg 1 670 18 145 28
  drawrect -rn %w $rgb(255,255,255) 1 670 18 145 28
  drawtext -nro %w $rgb(255,255,255) Verdana 11 685 24 %st_txt
  
  drawtext -nro %w $rgb(255,255,255) Verdana 17 20 8 Log Manager par Paradoxe80
  drawtext -nr %w $rgb(165,185,225) Verdana 10 22 36 Configuration de l'archivage automatique multi-serveurs
  
  drawsave %w $qt(%dir $+ banner_logs.bmp)
  window -c %w
}

alias -l log_viewer_assets {
  var %dir = $log_dir
  if (!$isdir(%dir)) mkdir $qt(%dir)
  var %w = @log_vdraw
  if ($window(%w)) window -c %w
  
  window -hpfB %w 0 0 840 64
  drawrect -rfn %w $rgb(16,24,36) 1 0 0 840 64
  drawrect -rfn %w $rgb(24,38,60) 1 0 0 840 32
  
  var %k = 0
  while (%k < 14) {
    var %col = $rgb($calc(20 + %k * 10), $calc(150 + %k * 6), $calc(220 - %k * 10))
    drawrect -rfn %w %col 1 $calc(%k * 60) 60 60 4
    inc %k
  }
  
  drawrect -rfn %w $rgb(30,130,200) 1 670 18 145 28
  drawrect -rn %w $rgb(255,255,255) 1 670 18 145 28
  drawtext -nro %w $rgb(255,255,255) Verdana 11 680 24 VISIONNEUSE
  
  drawtext -nro %w $rgb(255,255,255) Verdana 17 20 8 Visionneuse de Logs par Paradoxe80
  drawtext -nr %w $rgb(165,195,235) Verdana 10 22 36 Exploration des historiques, lecture complete & recherche de texte
  
  drawsave %w $qt(%dir $+ banner_viewer.bmp)
  window -c %w
}

; ------------------------------------------------------------------------------
; INTERFACE PRINCIPALE (LOG MANAGER)
; ------------------------------------------------------------------------------
dialog log_dialog {
  title "Log Manager v1.0 - Gestionnaire d'Archivage Multi-Serveurs"
  size -1 -1 840 520
  option pixels

  ; Bannière graphique d'en-tête (840x64)
  icon 1, 0 0 840 64, $mircexe, 0, noborder

  ; Panneau Gauche : Salons & Cibles détectés et configurés (w=380, h=390)
  box "Salons et Cibles à archiver (Multi-Serveurs)", 2, 14 74 380 395
  list 10, 24 98 360 280, vsbar
  button "Consulter ce log", 57, 24 384 175 28
  button "Activer / Pause", 52, 209 384 175 28
  button "Tout activer", 51, 24 422 110 28
  button "Actualiser", 56, 144 422 115 28
  button "Supprimer", 53, 269 422 115 28

  ; Panneau Droit : Paramètres de la cible sélectionnée (w=418, h=390)
  box "Paramètres de la cible sélectionnée", 3, 408 74 418 395
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
  check "Activer l'archivage global des logs", 8, 14 480 225 24
  check "Archiver aussi les Privés (PV)", 9, 245 480 195 24
  button "Ouvrir dossier logs", 60, 448 478 125 28
  button "Visionneuse complète...", 61, 580 478 145 28
  button "Fermer", 70, 733 478 93 28, ok
}

on *:dialog:log_dialog:init:0: {
  log_assets
  did -g $dname 1 $shortfn($log_dir $+ banner_logs.bmp)

  if ($log_get_cfg(enabled, 1) == 1) did -c $dname 8
  if ($log_get_cfg(log_pv, 1) == 1) did -c $dname 9

  did -r $dname 21
  did -a $dname 21 Tous les réseaux (*)
  var %i = 1
  while (%i <= $scon(0)) {
    var %net = $scid(%i).network
    if (%net == $null) %net = $scid(%i).server
    if (%net != $null) {
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

  did -r $dname 37
  did -a $dname 37 [HH:nn:ss]
  did -a $dname 37 [HH:nn]
  did -a $dname 37 (HH:nn:ss)
  did -a $dname 37 HH:nn:ss
  did -c $dname 37 1

  log_dialog_clear_form
  log_dialog_refresh_list
}

on *:dialog:log_dialog:close:0: {
  if ($window(@log_draw)) window -c @log_draw
}

on *:dialog:log_dialog:sclick:8: {
  log_set_cfg enabled $did(8).state
  log_assets
  did -g $dname 1 $shortfn($log_dir $+ banner_logs.bmp)
}

on *:dialog:log_dialog:sclick:9: {
  log_set_cfg log_pv $did(9).state
}

on *:dialog:log_dialog:sclick:60: {
  var %p = $log_root
  if (!$isdir(%p)) mkdir $qt(%p)
  run explorer.exe $qt(%p)
}

on *:dialog:log_dialog:sclick:61: {
  log_viewer_open
}

on *:dialog:log_dialog:sclick:10: {
  log_dialog_load_selected_line
}

on *:dialog:log_dialog:dclick:10: {
  log_dialog_toggle_selected
}

on *:dialog:log_dialog:sclick:52: {
  log_dialog_toggle_selected
}

; Bouton "Consulter ce log" (affiche directement le log du salon sélectionné dans @Logs)
on *:dialog:log_dialog:sclick:57: {
  var %sel = $did(10).sel
  if (%sel == $null) return
  var %text = $did(10, %sel).text
  var %net = $null, %chan = $null
  if ($regex(%text, /^\[([^\]]+)\]\s+([^\s]+)/)) {
    %net = $regml(1)
    %chan = $regml(2)
  }
  if (%chan == $null) return

  var %file = $log_find_latest_file(%net, %chan)
  if (%file != $null) && ($isfile(%file)) {
    if ($dialog(log_dialog)) dialog -x log_dialog
    log_display_file %file
  }
  else {
    echo -a $chr(3) $+ 04*** [Log Manager] Aucun fichier log trouvé pour ' $+ %chan $+ ' sur ' $+ %net $+ '.
  }
}

on *:dialog:log_dialog:sclick:51: {
  var %f = $log_ini
  var %s = 1
  var %count_act = 0
  while (%s <= $scon(0)) {
    scon %s
    var %net = $network
    if (%net == $null) %net = $server
    if (%net == $null) %net = Serveur_ $+ %s
    var %c = 1
    while (%c <= $chan(0)) {
      var %chan = $chan(%c)
      var %cfg_id = $log_find_entry(%net, %chan)
      if (%cfg_id != $null) {
        writeini %f $log_sec(%cfg_id) active 1
      }
      else {
        var %count = $readini(%f, General, count)
        if (%count == $null) %count = 0
        inc %count
        writeini %f General count %count
        var %sec = $log_sec(%count)
        writeini %f %sec network %net
        writeini %f %sec chan %chan
        writeini %f %sec active 1
        writeini %f %sec log_msg 1
        writeini %f %sec log_act 1
        writeini %f %sec log_joinpart 1
        writeini %f %sec log_quit 1
        writeini %f %sec log_kick 1
        writeini %f %sec log_topic 1
        writeini %f %sec rotation daily
        writeini %f %sec timestamp [HH:nn:ss]
      }
      inc %count_act
      inc %c
    }
    inc %s
  }
  scon -r
  log_dialog_refresh_list
  echo -a $chr(3) $+ 03*** [Log Manager] Tous vos salons actifs ( $+ %count_act $+ ) ont été configurés et activés pour l'archivage !
}

on *:dialog:log_dialog:sclick:56: {
  log_dialog_refresh_list
  echo -a $chr(3) $+ 10*** [Log Manager] Liste des salons et réseaux actualisée.
}

on *:dialog:log_dialog:sclick:55: {
  log_dialog_clear_form
  did -f $dname 23
}

on *:dialog:log_dialog:sclick:53: {
  var %sel = $did(10).sel
  if (%sel == $null) {
    noop $input(Veuillez sélectionner un salon dans la liste à supprimer., o w, Aucune sélection)
    return
  }
  var %text = $did(10, %sel).text
  var %net = $null, %chan = $null
  if ($regex(%text, /^\[([^\]]+)\]\s+([^\s]+)/)) {
    %net = $regml(1)
    %chan = $regml(2)
  }
  if (%chan == $null) return

  var %cfg_id = $log_find_entry(%net, %chan)
  if (%cfg_id == $null) {
    noop $input(Ce salon n'est pas encore enregistré dans votre fichier de configuration., o i, Info)
    return
  }

  var %rep = $input(Voulez-vous vraiment supprimer la configuration d'archivage pour ' $+ %chan $+ ' ( $+ %net $+ ) ?, y n q, Confirmation)
  if (%rep != yes) return

  log_delete_target %cfg_id
  log_dialog_refresh_list
  log_dialog_clear_form
  echo -a $chr(3) $+ 04*** Salon %chan ( $+ %net $+ ) supprimé de la configuration d'archivage.
}

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

  var %cfg_id = $log_find_entry(%net, %chan)
  if (%cfg_id == $null) {
    inc %count
    %cfg_id = %count
    writeini %f General count %count
  }

  var %sec = $log_sec(%cfg_id)
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

  log_dialog_refresh_list
  echo -a $chr(3) $+ 03*** [Log Manager] Configuration enregistrée pour %chan sur %net.
}

; ------------------------------------------------------------------------------
; NOUVELLE VISIONNEUSE DE LOGS GRAPHIQUE (LOG VIEWER DIALOG)
; ------------------------------------------------------------------------------
dialog log_viewer_dialog {
  title "Log Viewer v1.0 - Exploration et Consultation des Archives"
  size -1 -1 840 520
  option pixels

  ; Bannière graphique d'en-tête (840x64)
  icon 1, 0 0 840 64, $mircexe, 0, noborder

  ; Colonne 1 : Réseaux / Dossiers
  box "1. Réseau / Serveur", 10, 14 74 210 392
  list 11, 24 98 190 356, vsbar, sort

  ; Colonne 2 : Salons & Cibles
  box "2. Salons & Cibles", 20, 234 74 230 392
  list 21, 244 98 210 356, vsbar, sort

  ; Colonne 3 : Fichiers et Dates disponibles
  box "3. Fichiers & Dates de logs", 30, 474 74 352 392
  list 31, 484 98 332 265, vsbar, sort
  
  button "Afficher dans @Logs (Plein écran)", 41, 484 374 220 30
  button "Bloc-notes", 42, 712 374 104 30
  button "Ouvrir dossier", 44, 484 414 110 28
  button "Rechercher (Ctrl+F)", 45, 602 414 125 28
  button "Suppr.", 43, 735 414 81 28

  ; Barre inférieure globale
  text "Sélectionnez un réseau, un salon et une date à consulter.", 50, 14 480 670 20
  button "Fermer", 70, 710 476 116 28, ok
}

on *:dialog:log_viewer_dialog:init:0: {
  log_viewer_assets
  did -g $dname 1 $shortfn($log_dir $+ banner_viewer.bmp)
  log_viewer_populate_networks
}

on *:dialog:log_viewer_dialog:close:0: {
  if ($window(@log_vdraw)) window -c @log_vdraw
  if ($window(@log_temp_ch)) window -c @log_temp_ch
  if ($hget(log_chan_h)) hfree log_chan_h
  if ($hget(log_files_h)) hfree log_files_h
  unset %log_v_net %log_v_chan %log_v_file
}

; Helpers robustes pour l'extraction de texte des listes
alias -l log_did_seltext {
  var %d = $1, %id = $2
  var %t = $did(%d, %id).seltext
  if (%t != $null) return %t
  var %s = $did(%d, %id).sel
  if (%s isnum 1-) {
    %t = $did(%d, %id, %s).text
    if (%t != $null) return %t
    %t = $did(%d, %id, %s)
    if (%t != $null) return %t
  }
  return $null
}

alias -l log_did_line {
  var %d = $1, %id = $2, %n = $3
  if (%n !isnum 1-) return $null
  var %t = $did(%d, %id, %n).text
  if (%t != $null) return %t
  return $did(%d, %id, %n)
}

; Clic sur un réseau dans la colonne 1
on *:dialog:log_viewer_dialog:sclick:11: {
  var %net = $log_did_seltext($dname, 11)
  if (%net != $null) {
    set %log_v_net %net
    log_viewer_populate_channels %net
  }
}

; Clic sur un salon dans la colonne 2
on *:dialog:log_viewer_dialog:sclick:21: {
  var %chan = $log_did_seltext($dname, 21)
  if (%chan != $null) {
    set %log_v_chan %chan
    log_viewer_populate_files %chan
  }
}

; Clic sur un fichier dans la colonne 3
on *:dialog:log_viewer_dialog:sclick:31: {
  var %file = $log_did_seltext($dname, 31)
  if (%file != $null) {
    set %log_v_file %file
    log_viewer_update_file_info
  }
}

; Double-clic sur un fichier dans la colonne 3 : affichage direct dans @Logs
on *:dialog:log_viewer_dialog:dclick:31: {
  var %file = $log_did_seltext($dname, 31)
  if (%file != $null) set %log_v_file %file
  log_viewer_display_selected
}

; Bouton "Afficher dans @Logs"
on *:dialog:log_viewer_dialog:sclick:41: {
  log_viewer_display_selected
}

; Bouton "Bloc-notes"
on *:dialog:log_viewer_dialog:sclick:42: {
  var %f = $log_viewer_get_selected_filepath
  if (%f != $null) && ($isfile(%f)) {
    run notepad.exe $qt(%f)
  }
}

; Bouton "Ouvrir dossier"
on *:dialog:log_viewer_dialog:sclick:44: {
  var %f = $log_viewer_get_selected_filepath
  if (%f != $null) && ($isfile(%f)) {
    run explorer.exe /select, $qt(%f)
  }
  else {
    run explorer.exe $qt($log_root)
  }
}

; Bouton "Rechercher (Ctrl+F)"
on *:dialog:log_viewer_dialog:sclick:45: {
  var %f = $log_viewer_get_selected_filepath
  if (%f != $null) && ($isfile(%f)) {
    log_display_file %f
    var %txt = $input(Texte à rechercher dans ce log :, e, Recherche de texte)
    if (%txt != $null) findtext %txt
  }
}

; Bouton "Supprimer ce log"
on *:dialog:log_viewer_dialog:sclick:43: {
  var %f = $log_viewer_get_selected_filepath
  if (%f == $null) || (!$isfile(%f)) return
  var %rep = $input(Voulez-vous vraiment supprimer définitivement ce fichier log ? $+ $crlf $+ $nopath(%f), y n q, Confirmation)
  if (%rep == yes) {
    .remove $qt(%f)
    log_viewer_populate_files
  }
}

; ------------------------------------------------------------------------------
; ALIASES INTERNES DE LA VISIONNEUSE
; ------------------------------------------------------------------------------

alias log_viewer_open {
  if ($dialog(log_viewer_dialog)) dialog -v log_viewer_dialog
  else dialog -m log_viewer_dialog log_viewer_dialog
}

alias -l log_viewer_populate_networks {
  if (!$dialog(log_viewer_dialog)) return
  var %d = log_viewer_dialog
  did -r %d 11
  did -r %d 21
  did -r %d 31

  ; Trouver tous les sous-dossiers réseaux dans $log_root
  var %root = $log_root
  if (!$isdir(%root)) mkdir $qt(%root)

  var %tot = $finddir(%root, *, 0, 1)
  var %i = 1
  var %cur_net = $network
  var %first_net = $null
  var %target_net = $null

  while (%i <= %tot) {
    var %dpath = $finddir(%root, *, %i, 1)
    var %net_name = $nopath(%dpath)
    if (%net_name != $null) {
      did -a %d 11 %net_name
      if (%first_net == $null) %first_net = %net_name
      if (%net_name == %cur_net) %target_net = %net_name
    }
    inc %i
  }

  if ($did(%d, 11).lines > 0) {
    if (%target_net == $null) %target_net = %first_net
    var %sel = 1
    var %k = 1
    while (%k <= $did(%d, 11).lines) {
      if ($log_did_line(%d, 11, %k) == %target_net) { %sel = %k | break }
      inc %k
    }
    did -c %d 11 %sel
    set %log_v_net %target_net
    log_viewer_populate_channels %target_net
  }
  else {
    did -a %d 11 (Aucun dossier réseau)
    did -ra %d 50 Dossier logs vide: %root
  }
}

alias -l log_viewer_populate_channels {
  var %d = log_viewer_dialog
  if (!$dialog(%d)) return
  did -r %d 21
  did -r %d 31

  var %net = $1
  if (%net == $null) %net = $log_did_seltext(%d, 11)
  if (%net == $null) %net = %log_v_net
  if ((%net == $null) || ($left(%net, 1) == $chr(40))) return
  set %log_v_net %net

  var %net_dir = $log_net_dir(%net)
  if (!$isdir(%net_dir)) {
    %net_dir = $mircdirlogs\ $+ %net
  }
  if (!$isdir(%net_dir)) {
    did -a %d 21 (Dossier réseau absent)
    did -ra %d 50 [ $+ %net $+ ] Dossier introuvable : %net_dir
    return
  }

  ; Table de hachage temporaire pour unicité instantanée O(1)
  if ($hget(log_chan_h)) hfree log_chan_h
  hmake log_chan_h 200

  var %first_chan = $null

  ; 1. Trouver les sous-dossiers de salons
  var %tot_dirs = $finddir(%net_dir, *, 0, 1)
  var %i = 1
  while (%i <= %tot_dirs) {
    var %ch_dir = $nopath($finddir(%net_dir, *, %i, 1))
    if (%ch_dir != $null) && (!$hget(log_chan_h, %ch_dir)) {
      hadd log_chan_h %ch_dir 1
      did -a %d 21 %ch_dir
      if (%first_chan == $null) %first_chan = %ch_dir
    }
    inc %i
  }

  ; 2. Ajouter les salons actuellement rejoints sur ce réseau
  var %sc = 1
  while (%sc <= $scon(0)) {
    scon %sc
    if (($network == %net) || ($server == %net)) {
      var %c = 1
      while (%c <= $chan(0)) {
        var %cn = $chan(%c)
        if (!$hget(log_chan_h, %cn)) {
          hadd log_chan_h %cn 1
          did -a %d 21 %cn
          if (%first_chan == $null) %first_chan = %cn
        }
        inc %c
      }
    }
    inc %sc
  }
  scon -r

  ; 3. Si aucun salon trouvé par sous-dossier, scanner les fichiers logs directs
  if ($did(%d, 21).lines == 0) {
    var %tot_files = $findfile(%net_dir, *.log, 0, 1)
    var %max_scan = $iif(%tot_files > 500, 500, %tot_files)
    var %j = 1
    while (%j <= %max_scan) {
      var %fn = $nopath($findfile(%net_dir, *.log, %j, 1))
      var %ch_name = $null
      if ($regex(%fn, /^([#&][^._]+)/)) {
        %ch_name = $regml(1)
      }
      elseif ($regex(%fn, /^([^._]+)/)) {
        %ch_name = $regml(1)
      }
      if (%ch_name != $null) && (!$hget(log_chan_h, %ch_name)) {
        hadd log_chan_h %ch_name 1
        did -a %d 21 %ch_name
        if (%first_chan == $null) %first_chan = %ch_name
      }
      inc %j
    }
  }
  if ($hget(log_chan_h)) hfree log_chan_h

  if ($did(%d, 21).lines > 0) {
    did -c %d 21 1
    var %sel_c = $log_did_line(%d, 21, 1)
    if (%sel_c == $null) %sel_c = %first_chan
    set %log_v_chan %sel_c
    log_viewer_populate_files %sel_c
  }
  else {
    set %log_v_chan $null
    set %log_v_file $null
    did -a %d 21 (Aucun salon trouvé)
    did -a %d 31 (Aucun fichier log)
    did -ra %d 50 [ $+ %net $+ ] Aucun salon ni log trouvé dans ce réseau.
  }
}

alias -l log_viewer_populate_files {
  var %d = log_viewer_dialog
  if (!$dialog(%d)) return
  did -r %d 31

  var %chan = $1
  if (%chan == $null) %chan = $log_did_seltext(%d, 21)
  if (%chan == $null) %chan = %log_v_chan

  var %net = %log_v_net
  if (%net == $null) %net = $log_did_seltext(%d, 11)

  if ((%net == $null) || (%chan == $null) || ($left(%chan, 1) == $chr(40))) return
  set %log_v_net %net
  set %log_v_chan %chan

  var %net_dir = $log_net_dir(%net)
  if (!$isdir(%net_dir)) %net_dir = $mircdirlogs\ $+ %net
  var %chan_dir = $log_chan_dir(%net, %chan)
  if (!$isdir(%chan_dir)) %chan_dir = %net_dir $+ \ $+ %chan

  if ($hget(log_files_h)) hfree log_files_h
  hmake log_files_h 200

  ; 1. Chercher dans le sous-dossier dédié (s'il existe)
  if ($isdir(%chan_dir)) {
    var %tot_cf = $findfile(%chan_dir, *.log, 0, 1)
    var %i = 1
    while (%i <= %tot_cf) {
      var %fp = $findfile(%chan_dir, *.log, %i, 1)
      var %fn = $nopath(%fp)
      if (%fn != $null) && (!$hget(log_files_h, %fn)) {
        hadd log_files_h %fn 1
        did -a %d 31 %fn
      }
      inc %i
    }
  }

  ; 2. Chercher aussi dans le dossier réseau direct (%chan*.log)
  if ($isdir(%net_dir)) {
    var %tot_nf = $findfile(%net_dir, %chan $+ *.log, 0, 1)
    var %k = 1
    while (%k <= %tot_nf) {
      var %fp2 = $findfile(%net_dir, %chan $+ *.log, %k, 1)
      var %fn2 = $nopath(%fp2)
      if (%fn2 != $null) && (!$hget(log_files_h, %fn2)) {
        hadd log_files_h %fn2 1
        did -a %d 31 %fn2
      }
      inc %k
    }

    ; Si rien trouvé et commence par # ou &, chercher aussi sans le symbole
    if ($did(%d, 31).lines == 0) && ($regex(%chan, /^[#&]/)) {
      var %raw_name = $mid(%chan, 2)
      var %tot_nf2 = $findfile(%net_dir, %raw_name $+ *.log, 0, 1)
      var %m = 1
      while (%m <= %tot_nf2) {
        var %fp3 = $findfile(%net_dir, %raw_name $+ *.log, %m, 1)
        var %fn3 = $nopath(%fp3)
        if (%fn3 != $null) && (!$hget(log_files_h, %fn3)) {
          hadd log_files_h %fn3 1
          did -a %d 31 %fn3
        }
        inc %m
      }
    }
  }

  if ($hget(log_files_h)) hfree log_files_h

  if ($did(%d, 31).lines > 0) {
    var %last = $did(%d, 31).lines
    did -c %d 31 %last
    var %sel_f = $log_did_line(%d, 31, %last)
    set %log_v_file %sel_f
    log_viewer_update_file_info
  }
  else {
    set %log_v_file $null
    did -a %d 31 (Aucun fichier log)
    did -ra %d 50 [ $+ %chan $+ ] Aucun fichier log trouvé pour ce salon.
  }
}

alias -l log_viewer_get_selected_filepath {
  var %d = log_viewer_dialog
  if (!$dialog(%d)) return $null

  var %net = %log_v_net
  if (%net == $null) %net = $log_did_seltext(%d, 11)

  var %chan = %log_v_chan
  if (%chan == $null) %chan = $log_did_seltext(%d, 21)

  var %file = %log_v_file
  if (%file == $null) %file = $log_did_seltext(%d, 31)

  if ((%net == $null) || (%chan == $null) || (%file == $null)) return $null
  if ($left(%file, 1) == $chr(40)) return $null

  ; 1. Tester chemin dans le sous-dossier
  var %p1 = $log_chan_dir(%net, %chan) $+ \ $+ %file
  if ($isfile(%p1)) return %p1
  if ($isfile($shortfn(%p1))) return $shortfn(%p1)

  var %net_dir = $log_net_dir(%net)
  if (!$isdir(%net_dir)) %net_dir = $mircdirlogs\ $+ %net
  var %p0 = %net_dir $+ \ $+ %chan $+ \ $+ %file
  if ($isfile(%p0)) return %p0
  if ($isfile($shortfn(%p0))) return $shortfn(%p0)

  ; 2. Tester chemin direct dans le réseau
  var %p2 = %net_dir $+ \ $+ %file
  if ($isfile(%p2)) return %p2
  if ($isfile($shortfn(%p2))) return $shortfn(%p2)

  return $null
}

alias -l log_viewer_update_file_info {
  var %d = log_viewer_dialog
  if (!$dialog(%d)) return
  var %f = $log_viewer_get_selected_filepath
  if (%f != $null) && ($isfile(%f)) {
    var %sz = $file(%f).size
    var %sz_str = %sz octets
    if (%sz > 1048576) %sz_str = $round($calc(%sz / 1048576), 2) Mo
    elseif (%sz > 1024) %sz_str = $round($calc(%sz / 1024), 2) Ko
    var %mtime = $asctime($file(%f).mtime, dd/mm/yyyy à HH:nn:ss)
    did -ra %d 50 Fichier : $nopath(%f) $chr(124) Taille : %sz_str $chr(124) Modifié le : %mtime
  }
  else {
    var %cur_chan = %log_v_chan
    if (%cur_chan == $null) %cur_chan = $log_did_seltext(%d, 21)
    did -ra %d 50 [ $+ %cur_chan $+ ] $did(%d, 31).lines fichier(s) log répertorié(s).
  }
}

alias -l log_viewer_display_selected {
  var %f = $log_viewer_get_selected_filepath
  if (%f != $null) && ($isfile(%f)) {
    log_display_file %f
  }
  else {
    noop $input(Veuillez sélectionner un fichier log dans la colonne 3., ow, Fichier requis)
  }
}

; Recherche le fichier log le plus récent pour un réseau et un salon donnés
alias -l log_find_latest_file {
  var %net = $1
  var %chan = $2
  var %net_dir = $log_net_dir(%net)
  if (!$isdir(%net_dir)) %net_dir = $mircdirlogs\ $+ %net
  var %chan_dir = $log_chan_dir(%net, %chan)
  if (!$isdir(%chan_dir)) %chan_dir = %net_dir $+ \ $+ %chan

  var %best_file = $null
  var %best_time = 0

  ; Chercher dans le sous-dossier
  if ($isdir(%chan_dir)) {
    var %tot_cf = $findfile(%chan_dir, *.log, 0, 1)
    var %i = 1
    while (%i <= %tot_cf) {
      var %fp = $findfile(%chan_dir, *.log, %i, 1)
      var %mt = $file(%fp).mtime
      if (%mt > %best_time) {
        %best_time = %mt
        %best_file = %fp
      }
      inc %i
    }
  }

  ; Chercher aussi en direct dans le dossier réseau (%chan*.log)
  if ($isdir(%net_dir)) {
    var %tot_nf = $findfile(%net_dir, %chan $+ *.log, 0, 1)
    var %k = 1
    while (%k <= %tot_nf) {
      var %fp2 = $findfile(%net_dir, %chan $+ *.log, %k, 1)
      var %mt2 = $file(%fp2).mtime
      if (%mt2 > %best_time) {
        %best_time = %mt2
        %best_file = %fp2
      }
      inc %k
    }
  }

  return %best_file
}

; Affiche un fichier log dans la fenêtre @Logs avec loadbuf ultra-rapide
alias log_display_file {
  var %f = $1-
  if (%f == $null) || (!$isfile(%f)) {
    echo -a $chr(3) $+ 04*** [Log Viewer] Fichier introuvable : %f
    return
  }

  set %log_current_file %f

  if (!$window(@Logs)) {
    window -e @Logs
  }
  window -a @Logs
  window -w2 @Logs

  var %sz = $file(%f).size
  var %sz_str = %sz octets
  if (%sz > 1048576) %sz_str = $round($calc(%sz / 1048576), 2) Mo
  elseif (%sz > 1024) %sz_str = $round($calc(%sz / 1024), 2) Ko

  titlebar @Logs - [ $+ $nopath($nofile(%f)) $+ ] $nopath(%f) ( $+ %sz_str $+ )
  clear @Logs
  aline @Logs $chr(3) $+ 03*** Affichage du log : $nopath(%f) ***
  aline @Logs $chr(3) $+ 14Réseau / Dossier : $nofile(%f)
  aline @Logs $chr(3) $+ 14════════════════════════════════════════════════════════════════════════════════
  
  ; Chargement ultra-rapide de l'intégralité du fichier avec couleurs
  loadbuf -p @Logs $qt(%f)
  
  aline @Logs $chr(3) $+ 14════════════════════════════════════════════════════════════════════════════════
  aline @Logs $chr(3) $+ 03*** Fin du log (Total lignes affichées : $line(@Logs, 0)) ***
}

; ------------------------------------------------------------------------------
; MENU CONTEXTUEL CLIC-DROIT SUR LA FENÊTRE @Logs
; ------------------------------------------------------------------------------
menu @Logs {
  Parcourir d'autres logs (Visionneuse)...:log_viewer_open
  -
  Recharger ce log: {
    if ($isfile(%log_current_file)) log_display_file %log_current_file
  }
  Ouvrir dans le Bloc-notes (Notepad): {
    if ($isfile(%log_current_file)) run notepad.exe $qt(%log_current_file)
  }
  Ouvrir le dossier dans l'Explorateur: {
    if ($isfile(%log_current_file)) run explorer.exe /select, $qt(%log_current_file)
    else run explorer.exe $qt($log_root)
  }
  -
  Rechercher du texte (Ctrl+F): {
    var %txt = $input(Texte à rechercher dans les logs affichés :, e, Recherche de texte)
    if (%txt != $null) findtext %txt
  }
  -
  Vider cette fenêtre:clear @Logs
  Configurer Log Manager...:log_open
  Fermer:window -c @Logs
}

; ------------------------------------------------------------------------------
; ALIAS UTILITAIRES POUR LOG MANAGER
; ------------------------------------------------------------------------------
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

alias -l log_find_entry {
  var %net = $1
  var %chan = $2
  var %f = $log_ini
  var %count = $readini(%f, General, count)
  if (%count == $null) return $null
  var %i = 1
  while (%i <= %count) {
    var %sec = $log_sec(%i)
    var %c_chan = $readini(%f, %sec, chan)
    var %c_net = $readini(%f, %sec, network)
    if ($lower(%c_chan) == $lower(%chan)) {
      if (%c_net == $null) || (%c_net == Tous les réseaux (*)) || (%c_net == *) || ($lower(%c_net) == $lower(%net)) {
        return %i
      }
    }
    inc %i
  }
  return $null
}

alias -l log_dialog_refresh_list {
  if (!$dialog(log_dialog)) return
  var %d = log_dialog
  var %sel_idx = $1
  var %f = $log_ini

  did -r %d 10

  var %total_displayed = 0
  var %s = 1
  while (%s <= $scon(0)) {
    scon %s
    var %net = $network
    if (%net == $null) %net = $server
    if (%net == $null) %net = Serveur_ $+ %s
    
    var %c = 1
    while (%c <= $chan(0)) {
      var %chan = $chan(%c)
      var %cfg_id = $log_find_entry(%net, %chan)
      var %status = [NON ARCHIVE]
      
      if (%cfg_id != $null) {
        var %sec = $log_sec(%cfg_id)
        var %act = $readini(%f, %sec, active)
        var %rot = $readini(%f, %sec, rotation)
        if (%act == 1) {
          var %rot_txt = $iif(%rot == monthly, Mois, $iif(%rot == continuous, Continu, Jour))
          %status = [ACTIF - %rot_txt $+ ]
        }
        else {
          %status = [PAUSE]
        }
      }
      
      inc %total_displayed
      var %item_text = $chr(91) $+ %net $+ $chr(93) %chan  --  %status
      did -a %d 10 %item_text
      
      inc %c
    }
    inc %s
  }
  scon -r

  var %count = $readini(%f, General, count)
  if (%count == $null) %count = 0
  var %k = 1
  while (%k <= %count) {
    var %sec = $log_sec(%k)
    var %c_chan = $readini(%f, %sec, chan)
    var %c_net = $readini(%f, %sec, network)
    if (%c_chan != $null) {
      var %already = 0
      var %chk = 1
      while (%chk <= %total_displayed) {
        var %t_line = $did(%d, 10, %chk).text
        if ($chr(91) $+ %c_net $+ $chr(93) isin %t_line) && (%c_chan isin %t_line) {
          %already = 1
          break
        }
        inc %chk
      }
      if (%already == 0) {
        var %act = $readini(%f, %sec, active)
        var %rot = $readini(%f, %sec, rotation)
        var %rot_txt = $iif(%rot == monthly, Mois, $iif(%rot == continuous, Continu, Jour))
        var %st = $iif(%act == 1, [ACTIF - %rot_txt $+ ], [PAUSE])
        did -a %d 10 $chr(91) $+ %c_net $+ $chr(93) %c_chan  --  %st
        inc %total_displayed
      }
    }
    inc %k
  }

  if (%total_displayed == 0) {
    did -a %d 10 (Aucun salon rejoint sur vos serveurs - Rejoignez un salon ou ajoutez-en un à droite)
  }

  if (%sel_idx != $null) && (%sel_idx <= %total_displayed) {
    did -c %d 10 %sel_idx
    log_dialog_load_selected_line
  }
}

alias -l log_dialog_load_selected_line {
  var %d = log_dialog
  if (!$dialog(%d)) return
  var %sel = $did(%d, 10).sel
  if (%sel == $null) return
  var %text = $did(%d, 10, %sel).text
  if ((%text == $null) || ($left(%text, 1) != $chr(91))) return

  var %net = $null, %chan = $null
  if ($regex(%text, /^\[([^\]]+)\]\s+([^\s]+)/)) {
    %net = $regml(1)
    %chan = $regml(2)
  }
  if (%chan == $null) return

  var %cfg_id = $log_find_entry(%net, %chan)
  if (%cfg_id != $null) {
    log_dialog_load_target %cfg_id
  }
  else {
    var %idx = 1
    while (%idx <= $did(%d, 21).lines) {
      if ($did(%d, 21, %idx).text == %net) {
        did -c %d 21 %idx
        break
      }
      inc %idx
    }
    did -ra %d 23 %chan
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
}

alias -l log_dialog_toggle_selected {
  var %d = log_dialog
  if (!$dialog(%d)) return
  var %sel = $did(%d, 10).sel
  if (%sel == $null) return
  var %text = $did(%d, 10, %sel).text
  if ((%text == $null) || ($left(%text, 1) != $chr(91))) return

  var %net = $null, %chan = $null
  if ($regex(%text, /^\[([^\]]+)\]\s+([^\s]+)/)) {
    %net = $regml(1)
    %chan = $regml(2)
  }
  if (%chan == $null) return

  var %f = $log_ini
  var %cfg_id = $log_find_entry(%net, %chan)
  if (%cfg_id != $null) {
    var %sec = $log_sec(%cfg_id)
    var %act = $readini(%f, %sec, active)
    var %nact = $iif(%act == 1, 0, 1)
    writeini %f %sec active %nact
  }
  else {
    var %count = $readini(%f, General, count)
    if (%count == $null) %count = 0
    inc %count
    writeini %f General count %count
    var %sec = $log_sec(%count)
    writeini %f %sec network %net
    writeini %f %sec chan %chan
    writeini %f %sec active 1
    writeini %f %sec log_msg 1
    writeini %f %sec log_act 1
    writeini %f %sec log_joinpart 1
    writeini %f %sec log_quit 1
    writeini %f %sec log_kick 1
    writeini %f %sec log_topic 1
    writeini %f %sec rotation daily
    writeini %f %sec timestamp [HH:nn:ss]
  }
  log_dialog_refresh_list %sel
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

  var %idx = 1
  while (%idx <= $did(%d, 21).lines) {
    if ($did(%d, 21, %idx).text == %net) {
      did -c %d 21 %idx
      break
    }
    inc %idx
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

  did -u %d 33
  did -u %d 34
  did -u %d 35
  if (%rotation == monthly) did -c %d 34
  elseif (%rotation == continuous) did -c %d 35
  else did -c %d 33

  var %t_idx = 1
  while (%t_idx <= $did(%d, 37).lines) {
    if ($did(%d, 37, %t_idx).text == %timestamp) {
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

alias -l log_write_entry {
  var %net = $1
  var %target = $2
  var %ev_type = $3
  var %msg = $4-

  if ($log_get_cfg(enabled, 1) != 1) return

  var %f = $log_ini
  var %total = $readini(%f, General, count)
  if (%total == $null) %total = 0

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

  if (%matched == 0) && ($left(%target, 1) != #) {
    if ($log_get_cfg(log_pv, 1) == 1) {
      %matched = 1
    }
  }

  if (%matched == 0) return

  var %rot = daily, %t_fmt = [HH:nn:ss]
  if (%rule_id > 0) {
    var %sec = $log_sec(%rule_id)
    if ($readini(%f, %sec, rotation) != $null) %rot = $readini(%f, %sec, rotation)
    if ($readini(%f, %sec, timestamp) != $null) %t_fmt = $readini(%f, %sec, timestamp)
  }

  var %clean_net = $log_sanitize_dir(%net)
  var %clean_target = $log_sanitize_dir(%target)
  var %folder = $log_root $+ %clean_net $+ \ $+ %clean_target $+ \
  if (!$isdir(%folder)) mkdir $qt(%folder)

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

alias logview {
  log_viewer_open
}

alias log_viewer {
  log_viewer_open
}

menu menubar {
  -
  Log Manager: {
    log_open
  }
  Visionneuse de Logs: {
    log_viewer_open
  }
}

menu channel {
  -
  Log Manager: {
    log_open
  }
  Lire le log de ce salon: {
    var %net = $network
    if (%net == $null) %net = $server
    var %f = $log_find_latest_file(%net, $chan)
    if (%f != $null) && ($isfile(%f)) {
      log_display_file %f
    }
    else {
      echo -a $chr(3) $+ 04*** Aucun log trouvé pour $chan sur %net.
    }
  }
}

menu status {
  -
  Log Manager: {
    log_open
  }
  Visionneuse de Logs: {
    log_viewer_open
  }
}

; Initialisation au chargement du script
on *:LOAD: {
  echo -a $chr(3) $+ 03════════════════════════════════════════════════════════════
  echo -a $chr(3) $+ 09 Log Manager v1.0 par Paradoxe80 chargé avec succès !
  echo -a $chr(3) $+ 14 Tapez $chr(3) $+ 04/log $chr(3) $+ 14pour la configuration ou $chr(3) $+ 04/logview $chr(3) $+ 14pour la visionneuse.
  echo -a $chr(3) $+ 03════════════════════════════════════════════════════════════
  log_assets
  log_viewer_assets
}
