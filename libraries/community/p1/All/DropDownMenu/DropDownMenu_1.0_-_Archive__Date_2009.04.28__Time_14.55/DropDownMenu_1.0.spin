{{
'   DropDownMenu_1.0.spin
'
'   This is a Drop Down Menu system reminicient of older DOS programs
'   Edit.Com's Drop Down Menu's are specifically what I was going for.
'   This Code also includes a short demo of operation with sample menu data in the DAT section
'   
'   It uses a modified TV_Text driver "tv_text-mod" which contains the following changes:
'
'   locate(x,y)    may be used instead of:    out($0A), out(x), out($0B), out(y)
'   colorscheme(c) may be used instead of:    out($0C), out(c) 
'   cls            replaces out($00)          out($00) no longer clears the screen
'   screenbackup   makes a backup copy of the current screen for later use by screenrestore
'   screenrestore  restores the screen to the state of its last screenbackup
'
'   It uses the standard "keyboard" driver for keyboard input
'
'   Operation for use in your program "The Program":
'
'   Preparation:
'       1) The Program has a defined DAT section with menu information labeled "DropDownMenuData"
'       2) The Program calls DropDownMenuInit
'   Usage:
'       1) The variable "DDCurrentMenuTop" must be given a value > 0 pertaining to which top level menu to open 
'       2) The Program calls DropDownMenu
'          This will Open the top level menu from "DDCurrentMenuTop" and allow the end user to navigate via keyboard:
'                The user can exit the Menu system at any time (Esc Key)
'                The user can move to another Top Level Menu (Left & Right Arrow Keys) 
'                The user can move within the current Top Level Menu options (Up & Down Arrow Keys)
'                The user can select the highlighted menu option (Enter Key)
'                The user can select any Menu Option within the Current Top Level Menu by Hot-key (the Off-Color Letter in the Menu)
'
'       3) Once a selection has been made the variable "CurrentCommand" will have been populated with the value defined in DAT for that menu option
'       4) The Program can then make use of the value of "CurrentCommand" to react to menu selections 

'    NOTE: Due to the use of the ScreenBackUp/ScreenRestore Functions,
'    you should be able to use this in existing applications that use TV_Text without forcing the existing app to re-draw itself


}}
'
CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

OBJ

  text  : "tv_text-mod"
  kb    : "keyboard"

VAR

  word stroke
  
  'DDMenu Required Vars
  byte CurrentCommand
  byte DDHotkeys[10], DDHotkeyCommands[10]
  byte DDWidth, DDDat, DDIndex, DDNumOfChoices, DDAlignment, DDCtr, DDCtr2, DDMenuCount, DDCurrentMenuInside ,DDCurrentMenuTop, DDCurrentMenuCommand
  word DDTopIndexes[8]
  'PopUpWindow Required Vars
  byte PUWCtr, PUWCtr2
  
PUB start | i

  text.start(12)              ' Start tv_text-mod driver
  kb.start(10,11)             ' Start keyboard driver
  DropDownMenuInit            ' Initialize DropDownMenu Variables


    
  repeat
    stroke := kb.key
    if stroke <> 0
      case stroke
        1126:           'ALT+F  ..  for file menu
          DDCurrentMenuTop := 1
          DropDownMenu
        1125:           'ALT+E  ... for Edit Menu
          DDCurrentMenuTop := 2
          DropDownMenu                  
        1139:           'ALT+S  ..  for Search Menu
          DDCurrentMenuTop := 3
          DropDownMenu
        1129:           'ALT+I  ..  for Options Menu
          DDCurrentMenuTop := 4
          DropDownMenu
        1128:           'ALT+H  ..  for Help Menu
          DDCurrentMenuTop := 5
          DropDownMenu
      stroke := 0
    if CurrentCommand <> 0
      Text.Locate(1,3)
      Text.ColorScheme(0)
      Text.Str(String("CurrentCommand:"))
      Text.Dec(CurrentCommand)
      PopUpWindow (8,4,27,3,String(" You've Made a Selection "))
      CurrentCommand := 0


pub DropDownMenuInit

  CurrentCommand := 0
  DDMenuCount := 5
  DDCurrentMenuTop := 0
  DDCurrentMenuInside := 1
  DropDownMenuScan
  DrawDropDownMenu(0)

pub DropDownMenuScan 'This function peels through all the Menu Data to fill out DDTopIndexes[] so that we may hop around the menus

  DDIndex := 0
  DDDat:=5
  DDCtr:=0
  DDTopIndexes[1] := 0  'This should always be the case...saying that our first menu begins at the begining of our menudata

  repeat DDCtr from 2 to DDMenuCount
    DDDat:=5
    DDIndex := 0
    repeat until DDDat == 0
      DDDat := DropDownMenuData[DDTopIndexes[DDCtr-1]+DDIndex++]
    DDAlignment := DropDownMenuData[DDTopIndexes[DDCtr-1]+DDIndex++]
    DDNumOfChoices := DropDownMenuData[DDTopIndexes[DDCtr-1]+DDIndex++]
    DDWidth := DropDownMenuData[DDTopIndexes[DDCtr-1]+DDIndex++]
    DDTopIndexes[DDCtr] := ((DDWidth+2)*DDNumOfChoices)+DDIndex +  (DDTopIndexes[DDCtr-1])

pub DropDownMenu
  text.screenbackup
  DrawDropDownMenu(1)
  repeat
    stroke := kb.key
    if stroke <> 0
      'Lets check the hotkey array to see if we have a hit
      repeat DDCtr from 1 to 10  ' also reduces all to uppercase
        if DDHotKeys[DDCtr] < 90
          DDHotKeys[DDCtr] := DDHotKeys[DDCtr] + 32
        if DDHotKeys[DDCtr] == stroke or DDHotKeys[DDCtr]-32 == stroke
          CurrentCommand := DDHotKeyCommands[DDCtr]
          DDCurrentMenuTop := 0
          DDCurrentMenuInside := 1
          DrawDropDownMenu(1)
          return
      case stroke
        192:            ' Left Arrow Key
          DDCurrentMenuTop--
          DDCurrentMenuInside := 1 
          If DDCurrentMenuTop == 0
            DDCurrentMenuTop := DDMenuCount
          DrawDropDownMenu(1)
        193:            ' Right Arrow Key
          DDCurrentMenuTop++
          DDCurrentMenuInside := 1
          If DDCurrentMenuTop > DDMenuCount
            DDCurrentMenuTop := 1
          DrawDropDownMenu(1)
        194:            ' Up Arrow Key
          DDCurrentMenuInside--
          if DDCurrentMenuInside == 0
             DDCurrentMenuInside := DDNumOfChoices
          DrawDropDownMenu(0)
        195:            ' Down Arrow Key
          DDCurrentMenuInside++
          if DDCurrentMenuInside > DDNumOfChoices
             DDCurrentMenuInside := 1
          DrawDropDownMenu(0)
        13:             ' Enter Key  --- This is where we impregnate the CurrentCommand Variable
          CurrentCommand := DDCurrentMenuCommand  
          DDCurrentMenuTop := 0
          DDCurrentMenuInside := 1
          DrawDropDownMenu(1)
          Return                    
        203:            ' Esc Key
          DDCurrentMenuTop := 0
          DDCurrentMenuInside := 1
          DrawDropDownMenu(1)
          Return
          
pub DrawDropDownMenu (restore)
  if restore == 1
    text.screenrestore
  DDIndex := DDTopIndexes[DDCurrentMenuTop]
  DDCtr := 0
  DDCtr2 := 0
  DDDat:=5
  bytefill(@DDHotkeys,0,11)          ' Blank out The Hotkey array
  bytefill(@DDHotkeyCommands,0,11)   ' Blank out The HotkeyCommands array
  
  If DDCurrentMenuTop == 0           'If no Menu is Opened...just drawing the top bar
    repeat DDCtr from 1 to DDMenuCount
      DDIndex := DDTopIndexes[DDCtr]
      DDCtr2 := 0
      DDDat:=5
      'Collect Our Menu Info for Rendering
      repeat until DDDat == 0
        DDDat := DropDownMenuData[DDIndex++]
      DDAlignment := DropDownMenuData[DDIndex++]
      DDNumOfChoices := DropDownMenuData[DDIndex++]
      DDWidth := DropDownMenuData[DDIndex++]
      'Now we have all the info needed to Draw this Menu
      text.colorscheme(3)
      text.locate(DDAlignment,0)
      text.str(@DropDownMenuData[DDTopIndexes[DDCtr]])                                      
      text.colorscheme(0) 
  else    'A Menu has been selected from the menu bar

    'Collect Our Menu Info for Rendering
    repeat until DDDat == 0
      DDDat := DropDownMenuData[DDIndex++]
    DDAlignment := DropDownMenuData[DDIndex++]
    DDNumOfChoices := DropDownMenuData[DDIndex++]
    DDWidth := DropDownMenuData[DDIndex++]
    'Now we have all the info needed to Draw this Menu
    text.colorscheme(5)
    text.locate(DDAlignment,0)
    text.str(@DropDownMenuData[DDTopIndexes[DDCurrentMenuTop]])
    'little correction to menus that are on the far right
    if DDAlignment+DDWidth > 40
      DDAlignment := DDAlignment - (DDAlignment+DDWidth-36)

    text.colorscheme(3)
    text.locate(DDAlignment,1)
    text.str(string("┌"))
    repeat DDCtr from 0 to DDWidth
      text.str(string("─"))
    text.str(string("┐"))
    'Loop to display each Menu Choice
    repeat DDCtr from 1 to DDNumOfChoices
      text.locate(DDAlignment,DDCtr+1)
      'Checks to see if the Menu Choice is a Blank Line
      if DropDownMenuData[DDIndex] <> "+"
        text.str(string("│"))
        if DDCurrentMenuInside == DDCtr
          text.colorscheme(5)
        else
          text.colorscheme(3)
        text.str(string(" "))
        repeat DDCtr2 from 1 to DDWidth
          text.out(DropDownMenuData[DDIndex++])
        text.colorscheme(3)
        text.str(string("│"))
        text.colorscheme(5)   ' Shadow
        text.str(string(" ")) 'Shadow
        text.locate(DDAlignment+DropDownMenuData[DDIndex]+1,DDCtr+1)   'Locate(x,y) on top of which character should be the shortcut char
        if DDCurrentMenuInside == DDCtr                                'if true this means that this is the Menu Choice currently Highlited
          text.colorscheme(2)
          DDCurrentMenuCommand := DropDownMenuData[DDIndex+1]          ' This is where we impregnate the DDCurrentMenuCommand Variable
        else
          text.colorscheme(6)
        text.out(DropDownMenuData[DDIndex-DDWidth+DropDownMenuData[DDIndex]-1])            'Prints the character that is to be highlighted as a hotkey
        DDHotkeys[DDCtr] :=  DropDownMenuData[DDIndex-DDWidth+DropDownMenuData[DDIndex]-1] 'Save this hotkey in array for catching during KB Scans
        DDHotKeyCommands[DDCtr] :=  DropDownMenuData[DDIndex+1]                            ' Save the hotkeycommand incase the hotkey is pressed
        DDIndex++
        DDIndex++
        text.colorscheme(3) 
      else                                     'It is a Blank line or "+----+" choice seperator
        text.str(string("├"))
        repeat DDCtr2 from 0 to DDWidth
          text.str(string("─"))
        text.str(string("┤"))
        text.colorscheme(5)   ' Shadow
        text.str(string(" ")) 'Shadow
        text.colorscheme(3)
        DDIndex := DDIndex + DDWidth + 2
        
    text.locate(DDAlignment,DDCtr+1)
    text.str(string("└"))
    repeat DDCtr2 from 0 to DDWidth
      text.str(string("─"))
    text.str(string("┘"))     
    text.colorscheme(5)   'Shadow
    text.str(string(" ")) 'Shadow
    text.locate(DDAlignment+1,DDCtr+2)
    repeat DDCtr2 from 0 to DDWidth+2
      text.str(string(" "))
    text.colorscheme(0)

pub PopUpWindow (x,y,w,h,s)           'Sizable Window to display text with an <OK> button at the bottom
  text.screenbackup
  text.colorscheme(3)
  text.locate(x,y)

  ' Draw the Box
  text.str(string("┌"))
  repeat PUWCtr from 2 to w-1
    text.str(string("─"))
  text.str(string("┐"))

  repeat PUWCtr from 1 to h
    text.locate(x,y+PUWCtr)
    text.str(string("│"))
    repeat PUWCtr2 from 2 to w-1
      text.str(string(" "))
    text.str(string("│"))
    text.colorscheme(5)
    text.str(string(" "))
    text.colorscheme(3)
  text.locate(x,y+PUWCtr)

  text.str(string("└"))
  repeat PUWCtr from 2 to w-1
    text.str(string("─"))
  text.str(string("┘"))
  text.colorscheme(5)
  text.str(string(" "))
  text.locate(x+1,y+h+2)
  repeat PUWCtr from 2 to w+1
    text.str(string(" "))
  text.colorscheme(3)

  PUWCtr:=1
  text.locate(x+1,y+1)
  repeat until byte[s] == 0
    if byte[s] == 13
      text.locate(x+1,y+1+PUWCtr++)
      s++
    text.out(byte[s++])
  
  'put the < OK > in..try to center it Dynamicly
  text.locate(x+(w/2)-3,y+h)
  text.str(string("< "))
  text.colorscheme(6)
  text.str(string("O"))
  text.colorscheme(3)
  text.str(string("K >"))

  'wait for key
  repeat
    stroke := kb.key
    if stroke <> 0
      case stroke
        13,203,79,111:            ' Enter, Esc, o, O
          text.screenrestore
          return
 
DAT
'' Menu Data needs to provide the following:
'' 1) Name of the Drop Down Menu
'' 2) Zero Termination for that String
'' 3) X Location (Horizontal Alignment)
'' 4) How Many Choices in that menu..including blanks
'' 5) The Width of that Menu
''
'' Each Menu Choice of a drop down menu needs to provide the following:
'' 1) Name of the Choice
'' 2) Short-cut Character..counting from the first char, which one is it  ---Unintentional trick "0" if you dont want that choice to have a shortcut key
'' 3) What to do if Selected, these will be defined as constants

DropDownMenuData            byte " File ", 0, 1, 6, 10 
                            byte "New       ", 1, NewDocument
                            byte "Open...   ", 1, OpenOpenDialogBox
                            byte "Save      ", 1, SaveDocument
                            byte "Save As...", 6, SaveAs
                            byte "+--------+", 0, 0
                            byte "Exit      ", 2, ExitProgram

                            byte " Edit ", 0, 7, 4, 6 
                            byte "Cut   ", 3, CutCommand
                            byte "Copy  ", 1, CopyCommand
                            byte "Paste ", 1, PasteCommand
                            byte "Clear ", 3, ClearCommand

                            byte " Search ", 0, 13, 3, 10 
                            byte "Find      ", 1, FindCommand
                            byte "Last Find ", 1, LastFindCommand
                            byte "Replace   ", 1, ReplaceCommand

                            byte " Options ", 0, 21, 2, 9 
                            byte "Settings ", 1, SettingsCommand
                            byte "Colors   ", 1, ColorsCommand

                            byte " Help ", 0, 33, 2, 9 
                            byte "Commands ", 1, CommandsCommand
                            byte "About    ", 1, AboutCommand
CON
  NewDocument       =1
  OpenOpenDialogBox =2
  SaveDocument      =3
  SaveAs            =4
  ExitProgram       =5
  CutCommand        =6
  CopyCommand       =7
  PasteCommand      =8
  ClearCommand      =9
  FindCommand       =10
  LastFindCommand   =11
  ReplaceCommand    =12
  SettingsCommand   =13
  ColorsCommand     =14
  CommandsCommand   =15
  AboutCommand      =16

{
Copyright (c) 2008 Rick Cassidy 

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: 

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. 

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}