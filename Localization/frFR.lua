-- Localization\frFR.lua

local addonName, addonTable = ...
local L = addonTable.L or {}
addonTable.L = L

if GetLocale() ~= "frFR" then return end

-- French localization
L["Profiles"] = "Profils"
L["Profile Manager"] = "Gestion des profils"
L["Create Profile"] = "Créer un profil"
L["Rename Profile"] = "Renommer le profil"
L["Delete"] = "Supprimer"
L["Select"] = "Sélectionner"
L["Rename"] = "Renommer"
L["Create"] = "Créer"
L["Profile Name:"] = "Nom du profil :"
L["New Name:"] = "Nouveau nom :"
L["Profile name cannot be empty."] = "Le nom du profil ne peut pas être vide."
L["A profile with this name already exists."] = "Un profil avec ce nom existe déjà."
L["Add Note"] = "Ajouter une note"
L["Edit"] = "Modifier"
L["Edit Note"] = "Modifier la note"
L["Save"] = "Enregistrer"
L["Cancel"] = "Annuler"
L["Close"] = "Fermer"
L["Wound Details - %s"] = "Détails de la blessure - %s"
L["Add Note - %s"] = "Ajouter une note - %s"
L["Edit Note - %s"] = "Modifier la note - %s"
L["Severity:"] = "Gravité :"
L["No notes have been added for this region."] = "Aucune note n'a été ajoutée pour cette région."
L["Note content cannot be empty."] = "Le contenu de la note ne peut pas être vide."
L["A note with this content already exists."] = "Une note avec ce contenu existe déjà."
L["Error: %s"] = "Erreur : %s"
L["Character Limit Exceeded"] = "Limite de caractères dépassée"
L["%d / %d"] = "%d / %d"
-- Severities
L["None"] = "Aucune"
L["Unknown"] = "Inconnue"
L["Benign"] = "Bénigne"
L["Moderate"] = "Modérée"
L["Severe"] = "Sévère"
L["Critical"] = "Critique"
L["Deadly"] = "Mortelle"
-- Body Parts
L["Head"] = "Tête"
L["Torso"] = "Torse"
L["Left Arm"] = "Bras gauche"
L["Right Arm"] = "Bras droit"
L["Left Hand"] = "Main gauche"
L["Right Hand"] = "Main droite"
L["Left Leg"] = "Jambe gauche"
L["Right Leg"] = "Jambe droite"
L["Left Foot"] = "Pied gauche"
L["Right Foot"] = "Pied droit"


L["Cannot open Profile Manager while note dialog is open."] = "Impossible d'ouvrir le gestionnaire de profils pendant que la boîte de dialogue de note est ouverte."
L["Cannot open wound dialog while Profile Manager is open."] = "Impossible d'ouvrir la boîte de dialogue de blessure pendant que le gestionnaire de profils est ouvert."

L["Viewing %s's Profile"] = "Profil de %s"

L["Request Profile"] = "Afficher le profil"
L["Click the bandage to request."] = "Cliquez sur le bandage pour afficher."

L["Thank you for using FleshWound %s! Be safe out there."] = "Merci d'utiliser FleshWound %s ! Soyez prudent en ces lieux."