-- frFR.lua
local addonName, addonTable = ...
local L = addonTable.L or {}
addonTable.L = L

if GetLocale() ~= "frFR" then return end

-- French localization
L["Add Note"] = "Ajouter"
L["Edit"] = "Modifier"
L["Delete"] = "Supprimer"
L["Save"] = "Enregistrer"
L["Cancel"] = "Annuler"
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
L["None"] = "Aucun"
L["Unknown"] = "Inconnu"
L["Benign"] = "Bénin"
L["Moderate"] = "Modéré"
L["Severe"] = "Sévère"
L["Critical"] = "Critique"
L["Deadly"] = "Mortel"
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
