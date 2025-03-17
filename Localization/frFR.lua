local addonName, addonTable = ...
local L = addonTable.L or {}
addonTable.L = L

if GetLocale() ~= "frFR" then return end

L.PROFILES               = "Profils"
L.PROFILE_MANAGER        = "Gestion des profils"
L.CREATE_PROFILE         = "Créer un profil"
L.RENAME_PROFILE         = "Renommer le profil"
L.DELETE                 = "Supprimer"
L.SELECT                 = "Sélectionner"
L.RENAME                 = "Renommer"
L.CREATE                 = "Créer"
L.PROFILE_NAME           = "Nom du profil :"
L.NEW_NAME               = "Nouveau nom :"
L.PROFILE_NAME_EMPTY     = "Le nom du profil ne peut pas être vide."
L.PROFILE_EXISTS         = "Un profil avec ce nom existe déjà."
L.ADD_NOTE               = "Ajouter une note"
L.EDIT                   = "Modifier"
L.EDIT_NOTE              = "Modifier la note"
L.SAVE                   = "Enregistrer"
L.CANCEL                 = "Annuler"
L.CLOSE                  = "Fermer"
L.WOUND_DETAILS          = "Détails de la blessure - %s"
L.ADD_NOTE_TITLE         = "Ajouter une note - %s"
L.EDIT_NOTE_TITLE        = "Modifier la note - %s"
L.SEVERITY               = "Gravité :"
L.NO_NOTES               = "Aucune note n'a été ajoutée pour cette région."
L.NOTE_EMPTY             = "Le contenu de la note ne peut pas être vide."
L.NOTE_DUPLICATE         = "Une note avec ce contenu existe déjà."
L.ERROR                  = "Erreur : %s"
L.CHAR_LIMIT             = "Limite de caractères dépassée"
L.CHAR_COUNT             = "%d / %d"

-- Severities
L.SEVERITY_NONE          = "Aucune"
L.SEVERITY_UNKNOWN       = "Inconnue"
L.SEVERITY_BENIGN        = "Bénigne"
L.SEVERITY_MODERATE      = "Modérée"
L.SEVERITY_SEVERE        = "Sévère"
L.SEVERITY_CRITICAL      = "Critique"
L.SEVERITY_DEADLY        = "Mortelle"

-- Body Parts
L.HEAD                   = "Tête"
L.TORSO                  = "Torse"
L.LEFT_ARM               = "Bras gauche"
L.RIGHT_ARM              = "Bras droit"
L.LEFT_HAND              = "Main gauche"
L.RIGHT_HAND             = "Main droite"
L.LEFT_LEG               = "Jambe gauche"
L.RIGHT_LEG              = "Jambe droite"
L.LEFT_FOOT              = "Pied gauche"
L.RIGHT_FOOT             = "Pied droit"

L.CANNOT_OPEN_PM_WHILE_NOTE = "Impossible d'ouvrir le gestionnaire de profils pendant que la boîte de dialogue de note est ouverte."
L.CANNOT_OPEN_WOUND_WHILE_PM  = "Impossible d'ouvrir la boîte de dialogue de blessure pendant que le gestionnaire de profils est ouvert."
L.VIEWING_PROFILE        = "Profil de %s"
L.REQUEST_PROFILE        = "Afficher le profil"
L.CLICK_BANDAGE_REQUEST  = "Cliquez sur le bandage pour afficher."
L.THANK_YOU              = "Merci d'utiliser FleshWound %s ! Soyez prudent en ces lieux."

L.DELETE_PROFILE_CONFIRM = "Êtes-vous sûr de vouloir supprimer le profil '%s' ?"
L.DATA_INITIALIZED       = "Données initialisées. Profil chargé: %s"
L.CREATED_PROFILE        = "Nouveau profil créé : %s"
L.PROFILE_EXISTS_MSG     = "Le profil '%s' existe déjà."
L.CANNOT_DELETE_CURRENT  = "Impossible de supprimer le profil courant."
L.DELETED_PROFILE        = "Profil '%s' supprimé."
L.PROFILE_NOT_EXIST      = "Le profil '%s' n'existe pas."
L.RENAMED_PROFILE        = "Profil '%s' renommé en '%s'."

L.STATUS                 = "État :"
L.STATUS_NONE            = "Aucun"
L.STATUS_BANDAGED        = "Bandé"
L.STATUS_BLEEDING        = "Saignement"
L.STATUS_BROKEN_BONE     = "Fracture"
L.STATUS_BURN            = "Brûlure"
L.STATUS_SCARRED         = "Cicatrice"
L.STATUS_POISONED        = "Empoisonné"
L.STATUS_INFECTED        = "Infecté"

L.LEFT_CLICK_SHOW_HIDE   = "Clic gauche pour afficher/masquer l'interface de santé."
L.FLESHWOUND_FIRST_RELEASE_POPUP = [[
Merci d'avoir téléchargé FleshWound !

Pour ouvrir l'interface, cliquez sur l'icône de bandage sur votre boussole, ou entrez /fw.

Attendez-vous à des changements d'interface, des mises à jour visuelles et de nouvelles fonctionnalités à l'avenir.

Vous pouvez également rencontrer des erreurs, merci de les signaler sur Discord lorsqu'elles se produisent.

Vos commentaires sont précieux et aideront à façonner l'avenir de FleshWound. Merci pour votre soutien !
]]

L.DISCLAIMER = [[
FleshWound est un outil de jeu de rôle conçu pour vous permettre d’entrer n’importe quelle description ou texte de votre choix, y compris des descriptions détaillées ou graphiques de blessures et des sujets sombres.

En utilisant cet add-on, vous reconnaissez que tout le contenu que vous créez ou consultez relève de votre seule responsabilité et doit respecter en permanence les Conditions d’Utilisation de Blizzard Entertainment.

Les développeurs de FleshWound déclinent expressément toute responsabilité quant au contenu que vous saisissez ou consultez via l’add-on.

Utilisez cet outil de manière responsable et assurez-vous que votre contenu de jeu de rôle respecte toutes les directives et politiques applicables.
]]

L.I_AGREE = "J'accepte"

L.NEW_VERSION_AVAILABLE = "Une nouvelle version de FleshWound est disponible : %s (vous avez %s)."
L.USERS_ONLINE_OTHER = "Il y a %d autres utilisateurs de FleshWound en ligne."
L.USERS_ONLINE_NONE = "Vous êtes le seul utilisateur de FleshWound en ligne."
L.USERS_ONLINE_ONE = "Il y a 1 autre utilisateur de FleshWound en ligne."

return L
