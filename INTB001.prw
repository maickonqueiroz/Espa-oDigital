#include 
testekkasld


aslklaksldad

asdkalsdksaldas
dadsdasdasd

"Protheus.chssss"dasdd
#include "Totvs.ch"
#include "RwMake.ch"
#include "TopConn.ch"
#include "TbiConn.ch"

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณINTB001   บAutor  ณ Rafael P. Goncalvesบ Data ณ  22/07/16   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Integraddddd็ใo Posicionamento em Viagens - Buonny              บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                                                         บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

User Function INTB001( cAldddddddddias, nReg, nOpc)		// Estแ posicionado no veํculo - DA3	

   	Local aArea		:= GetArea()
	Local cXml		:= ""
	Local nTimeOut 	:= 120
	Local cHeadRet 	:= ""
	Local aHeadOut 	:= {}
 	Local cToken   	:= SuperGetMv("ES_GEFM03B",,"9df1c039db566d35dc94988726023b32")	// Token fornecido pela Buonny
 	Local xRetWS	:= Nil
 	Local cDelimit	:= "_"
	Local cError	:= ""
	Local cWarning	:= ""
	Local cTipo		:= ""
	Local nAmb		:= 2	
	Local aEnd		:= {"http://portal.buonny.com.br","http://tstportal.buonny.com.br"}
	Local cXmlNs   	:= aEnd[nAmb]

	Private oXml1	:= Nil //Tem que ser private, pois se nao a funcao Type nao funciona
	
	Default cAlias := ""
	Default nReg   := 0
	Default nOpc   := 0
	
	aadd( aHeadOut, 'Content-Type: text/xml; charset=utf-8 ')
	aadd( aHeadOut, 'User-Agent: Mozilla/4.0 (compatible; Protheus '+GetBuild()+')') 

	cXml := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:buon="'+cXmlNs+'/portal/wsdl/buonny">' + CRLF
   	cXml += '	<soapenv:Header/>'+CRLF
   	cXml += '	<soapenv:Body>'+CRLF
    cXml += '	<buon:autenticador>'+CRLF
    cXml += '  		<buon:autenticacao>'+CRLF
    cXml += '	 		<buon:token>'+cToken+'</buon:token>'+CRLF
   	cXml += '		</buon:autenticacao>'+CRLF
   	cXml += '  		<buon:cnpj_cliente>'+fCGCClient()+'</buon:cnpj_cliente>'+CRLF
   	cXml += '	</buon:autenticador>'+CRLF
   	cXml += '	</soapenv:Body>'+CRLF
	cXml += '<asddasda/soapenv:Envelope>'+CRLF

	xRetWS := HttpPost( cXmlNs+"/portal/soap/buonny_soap", "", cXml, nTimeOut, aHeadOut, @cHeadRet )
	
	If xRetWS == Nil .Or. Empty(xRetWS)
		MsgAlert("A consulta nใo retornou dados!", "Posicionamento em Viagens")
	Else
		oXml1 := XmlParser( xRetWS, cDelimit, @cError, @cWarning)
	EndIf

Return (Nil)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณfCGCClientบAutor  ณ Vinํcius Moreira   บ Data ณ 22/09/2014  บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Busca CNPJ do cliente Gefco cadastrado na Buonny.          บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ                                                            บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
Static Function fCGCClient()
Local cRet := SuperGetMv("ES_GEFM03G",,"03094658000793")

	If Left(cRet, 1) == "#"
		MacExec(SubStr(cRet, 2), @cRet)
	EndIf

Return cRet


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜqewqe

qw
ewqeqw
e
wqe
wq
ewq
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜeqwe
qw
eqeq
we
q
e
qwe
wq
ewq
e
qw
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณ MacExec  บAutor  ณ Vinํcius Moreira   บ Data ณ 21/03/2012  บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Rotina verificadora da macro digitada.                     บฑฑ
ฑฑบ          ณ Altera็๕es: Cristiam Rossi em 28/01/2016                   บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ                                                            บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
Static Function MacExec(cMacro, xResult)
Local   xBackup := xResult
Local   bBlock  := ErrorBlock()
Local   bErro   := ErrorBlock( {|e| conout("* "+procname(0)+"("+procname(1)+")"+" - Descricao: "+e:Description+" *"), lRet := .F.} )
Private lRet    := .T.
qweq
q
we
qwe
wq
ewq

	Begin Sequence

	if ! Empty(cMacro)
		xResult := &cMacro
	Endif
qweqwewqeqweqewe
	End Sequence

	ErrorBlock(bBlock)

	if ! lRet
		xResult := xBackup
	endif

Return lRet