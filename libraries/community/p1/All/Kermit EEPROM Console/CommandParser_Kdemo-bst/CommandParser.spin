{{

┌───────────────────────────────────────────────────────┐
│ CommandParser, object to match indexed command list   │
│ and transform input to null terminated arg array      │
│ Author: Eric Ratliff                                  │
│ Copyright (c) 2009 Eric Ratliff                       │
│ See end of file for terms of use.                     │
└───────────────────────────────────────────────────────┘

2009.10.24 by Eric Ratliff
}}

CON
  null = 0
  CommandStringOffset = 1
  DummyByte = 0 ' filler value for command structure first member

VAR
  long pCommandList ' where command list array begins
  long NumCommands ' how many commans there are in the list

{PUB init(pTheCommandList,TheNumCommands)
'' this routine memorizes a prepared command list location and command quantity so that each parse call does not need to pass repeatedly
  pCommandList := pTheCommandList
  NumCommands := TheNumCommands }

PUB init(pTheCommandList)
'' this routine memorizes a list location and starts the command count at zero
  pCommandList := pTheCommandList
  NumCommands := 0

PUB AppendCommand(pCommandStruct)
'' helps in preperation of commmand list
  LONG[pCommandList][NumCommands] := pCommandStruct + CommandStringOffset
  BYTE[pCommandStruct] := NumCommands ' save assigned order to the command list structure
  NumCommands++

PUB parse(pCommandLine,LineLength,p_argc,p_argv):CommandIndex|CharIndex,LookingForText
'' command line is string with room for null termination at the end which contains the command and arguments separated by spaces
'' the length parameter does not include any null terminator that may be present
'' the argument count pointer shows where to put quantity of parsed elements (the command and args) that were found
'' the argument list pointer should be an array where as many as LineLenght/2 pointers to beginnings of parsed elements will be placed
'' the command and each argument will be terminated with a null
' nice to have: double quotes allow spaces within one argument and quotes are removed

  ' look for spaces as a way to separate arguments and the command
  LONG[p_argc] := 0 ' assume no command or arguments for now
  CharIndex := 0
  LookingForText := true
  repeat while CharIndex < LineLength
    if BYTE[pCommandLine][CharIndex] == 32 ' is this an ASCII space?
      if not LookingForText
        BYTE[pCommandLine][CharIndex] := null ' null terminate the command here by over writing the space
        LookingForText := true ' now we are looking for another element
    else
      if LookingForText
        ' we just found the first character of an element
        LONG[p_argv][LONG[p_argc]] := pCommandLine + CharIndex ' record where the command starts
        LONG[p_argc]++ ' cont this line element
        LookingForText := false ' now we are looking for an element separator
    CharIndex++
  if not LookingForText ' did we finish an element, but not find a space after it?
    BYTE[pCommandLine][CharIndex] := null ' null terminate the last element

  CommandIndex := 0 ' which command to look for first
  ' try to match first element to the command list
  repeat while CommandIndex < NumCommands ' check for all commands
    if STRCOMP(pCommandLine,LONG[pCommandList][CommandIndex]) ' is this comand matched?
      quit ' exit the loop directly, not looking for any more commands
    CommandIndex++
{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}
