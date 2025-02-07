local addonName, addonTable = ...
local L = addonTable.L or {}
addonTable.L = L

-- English localization keys
L.PROFILES               = "Profiles"
L.PROFILE_MANAGER        = "Profile Manager"
L.CREATE_PROFILE         = "Create Profile"
L.RENAME_PROFILE         = "Rename Profile"
L.DELETE                 = "Delete"
L.SELECT                 = "Select"
L.RENAME                 = "Rename"
L.CREATE                 = "Create"
L.PROFILE_NAME           = "Profile Name:"
L.NEW_NAME               = "New Name:"
L.PROFILE_NAME_EMPTY     = "Profile name cannot be empty."
L.PROFILE_EXISTS         = "A profile with this name already exists."
L.ADD_NOTE               = "Add Note"
L.EDIT                   = "Edit"
L.EDIT_NOTE              = "Edit Note"
L.SAVE                   = "Save"
L.CANCEL                 = "Cancel"
L.CLOSE                  = "Close"
L.WOUND_DETAILS          = "Wound Details - %s"
L.ADD_NOTE_TITLE         = "Add Note - %s"
L.EDIT_NOTE_TITLE        = "Edit Note - %s"
L.SEVERITY               = "Severity:"
L.NO_NOTES               = "No notes have been added for this region."
L.NOTE_EMPTY             = "Note content cannot be empty."
L.NOTE_DUPLICATE         = "A note with this content already exists."
L.ERROR                  = "Error: %s"
L.CHAR_LIMIT             = "Character Limit Exceeded"
L.CHAR_COUNT             = "%d / %d"

-- Severities
L.SEVERITY_NONE          = "None"
L.SEVERITY_UNKNOWN       = "Unknown"
L.SEVERITY_BENIGN        = "Benign"
L.SEVERITY_MODERATE      = "Moderate"
L.SEVERITY_SEVERE        = "Severe"
L.SEVERITY_CRITICAL      = "Critical"
L.SEVERITY_DEADLY        = "Deadly"

-- Body Parts
L.HEAD                   = "Head"
L.TORSO                  = "Torso"
L.LEFT_ARM               = "Left Arm"
L.RIGHT_ARM              = "Right Arm"
L.LEFT_HAND              = "Left Hand"
L.RIGHT_HAND             = "Right Hand"
L.LEFT_LEG               = "Left Leg"
L.RIGHT_LEG              = "Right Leg"
L.LEFT_FOOT              = "Left Foot"
L.RIGHT_FOOT             = "Right Foot"

L.CANNOT_OPEN_PM_WHILE_NOTE = "Cannot open Profile Manager while note dialog is open."
L.CANNOT_OPEN_WOUND_WHILE_PM  = "Cannot open wound dialog while Profile Manager is open."
L.VIEWING_PROFILE        = "Viewing %s's Profile"
L.REQUEST_PROFILE        = "Request Profile"
L.CLICK_BANDAGE_REQUEST  = "Click the bandage to request."
L.THANK_YOU              = "Thank you for using FleshWound %s! Be safe out there."

L.DELETE_PROFILE_CONFIRM = "Are you sure you want to delete the profile '%s'?"
L.DATA_INITIALIZED       = "Data initialized. Current Profile: %s"
L.CREATED_PROFILE        = "Created new profile: %s"
L.PROFILE_EXISTS_MSG     = "Profile '%s' already exists."
L.CANNOT_DELETE_CURRENT  = "Cannot delete the current profile."
L.DELETED_PROFILE        = "Deleted profile '%s'."
L.PROFILE_NOT_EXIST      = "Profile '%s' does not exist."
L.RENAMED_PROFILE        = "Renamed profile '%s' to '%s'."

L.STATUS                 = "Status:"
L.STATUS_NONE            = "None"
L.STATUS_BANDAGED        = "Bandaged"
L.STATUS_BLEEDING        = "Bleeding"
L.STATUS_BROKEN_BONE     = "Broken bone"
L.STATUS_BURN            = "Burn"
L.STATUS_SCARRED         = "Scarred"
L.STATUS_POISONED        = "Poisoned"
L.STATUS_INFECTED        = "Infected"

L.LEFT_CLICK_SHOW_HIDE   = "Left-click to show/hide the health frame."
L.FLESHWOUND_FIRST_RELEASE_POPUP = [[
Thank you for downloading FleshWound!

To open the interface, click on the bandage icon on your compass, or type /fw.

Expect UI changes, visual updates, and new features soon.

You may also encounter errors, so please report these in the Discord when they occur.

Your feedback is valuable and will help shape the future of FleshWound. Thank you for your support!
]]

L.NEW_VERSION_AVAILABLE = "A new version of FleshWound is available: %s (you have %s)."
L.USERS_ONLINE_OTHER = "There are %d other users with FleshWound online."
L.USERS_ONLINE_NONE = "You are the only user of FleshWound online."


return L