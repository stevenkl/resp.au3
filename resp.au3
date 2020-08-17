;*****************************************
;resp.au3 by Steven Kleist (stevenkl) <kleist.steven@gmail.com>
;Created with ISN AutoIt Studio v. 1.11
;*****************************************

#include-once

#include <AutoItConstants.au3>

#cs Redis Formats and Messages
	
	RESP_String    = "+"
	RESP_Error     = "-"
	RESP_Integer   = ":"
	RESP_BString   = "$"
	RESP_Array     = "*"

	RESP_Msg_OK    = "+OK\r\n"
	RESP_Msg_Err   = "-{{ERR_PREFIX}} {{ERR_MSG}}\r\n"
	RESP_Msg_Null  = "$-1\r\n"
	RESP_Msg_Str   = "+{{STR}}\r\n"
	RESP_Msg_BStr  = "${{count(STR)}}\r\n{{STR}}\r\n"
	RESP_Msg_Int   = ":{{INT}}\r\n"
	RESP_Msg_Array = "*{{array_length}}\r\n{{array_fields}}"
	
	RESP_Msg_Cmd   = "*{{count(CMD + PARAMS)}}\r\n"
					 "${{CMD.length}}\r\n{{CMD}}\r\n"
					 "${{PARAM[1].length}}\r\n{{PARAM[1]}}\r\n"
					 "${{PARAM[n].length}}\r\n{{PARAM[n]}}\r\n"
#ce

Global $DEBUG = True

Func _RESP_Encode($oInput)
	
	local $sResult = ""
	local $sType = VarGetType($oInput)
	
	If $sType = "String" Then
		If StringInStr($oInput, " ") Then
			$sType = "BString"
			$sResult = StringFormat("$%d\r\n%s\r\n", StringLen($oInput), $oInput)
		Else
			$sResult = StringFormat("+%s\r\n", $oInput)
		EndIf
	
	ElseIf $sType = "Int32" Then
		$sResult = StringFormat(":%d\r\n", Number($oInput, $NUMBER_32BIT))
		
	ElseIf $sType = "Int64" Then
		$sResult = StringFormat(":%d\r\n", Number($oInput, $NUMBER_64BIT))
	
	ElseIf $sType = "Object" Then
		Return SetError(1, 1, False)
		
	ElseIf $sType = "Array" Then
		local $arr_len = UBound($oInput)
		$sResult = StringFormat("*%d\r\n", $arr_len)
		For $i = 0 To $arr_len - 1
			$sResult &= _RESP_Encode($oInput[$i])
		Next
		
	EndIf
	
	If $DEBUG Then
		Local $msg = "[_RESP_Encode] VarGetType($oInput) = %s\r\n[_RESP_Encode] $sResult = %s\r\n"
		ConsoleWrite(StringFormat($msg, $sType, $sResult) & @CRLF)
	EndIf
	
	Return $sResult
	
EndFunc


Func _RESP_Decode($sInput)
	
EndFunc


Func _RESP_Error($sPrefix, $sMsg)
	return StringFormat("-%s %s\r\n", $sPrefix, $sMsg)
EndFunc


Func _RESP_Command($sCmd, $aParams)
	local $sResult = StringFormat("*%d\r\n", 1 + UBound($aParams))
	$sResult &= StringFormat("$%d\r\n%s\r\n", StringLen($sCmd), $sCmd)
	For $i = 0 To UBound($aParams) - 1
		$sResult &= StringFormat("$%d\r\n%s\r\n", StringLen($aParams[$i]), $aParams[$i])
	Next
	Return $sResult
EndFunc



#Region start

local $dict = ObjCreate("Scripting.Dictionary")
local $arr  = ["Hello", "Hello World", 123]
local $sCmd = "LLEN"
local $aCmd = ["mylist"]

_RESP_Encode("Hello") ; String
_RESP_Encode("Hello World!") ; BString
_RESP_Encode(123) ; Int32
_RESP_Encode(12345678955555) ; Int64
_RESP_Encode($dict) ; Object
_RESP_Encode($arr) ; Array

_RESP_Encode($aCmd)

ConsoleWrite(_RESP_Command($sCmd, $aCmd))
#EndRegion start