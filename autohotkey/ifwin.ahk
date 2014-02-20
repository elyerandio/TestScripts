#IfWinActive ahk_class Notepad
^!a::MsgBox You pressed Ctrl-Alt-A while Notepad is active.
#c::MsgBox You pressed Win-C while Notepad is active.
::btw::This replacement text for 'btw' will occur only in Notepad.
#IfWinActive
#c::MsgBox You pressed Win-C in a window other than Notepad.
