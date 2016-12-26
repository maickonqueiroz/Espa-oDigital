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
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �INTB001   �Autor  � Rafael P. Goncalves� Data �  22/07/16   ���
�������������������������������������������������������������������������͹��
���Desc.     � Integraddddd��o Posicionamento em Viagens - Buonny              ���
���          �                                                            ���
�������������������������������������������������������������������������͹��
���Uso       � AP                                                         ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/

User Function INTB001( cAldddddddddias, nReg, nOpc)		// Est� posicionado no ve�culo - DA3	

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
		MsgAlert("A consulta n�o retornou dados!", "Posicionamento em Viagens")
	Else
		oXml1 := XmlParser( xRetWS, cDelimit, @cError, @cWarning)
	EndIf

Return (Nil)

/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �fCGCClient�Autor  � Vin�cius Moreira   � Data � 22/09/2014  ���
�������������������������������������������������������������������������͹��
���Desc.     � Busca CNPJ do cliente Gefco cadastrado na Buonny.          ���
���          �                                                            ���
�������������������������������������������������������������������������͹��
���Uso       �                                                            ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/
Static Function fCGCClient()
Local cRet := SuperGetMv("ES_GEFM03G",,"03094658000793")

	If Left(cRet, 1) == "#"
		MacExec(SubStr(cRet, 2), @cRet)
	EndIf

Return cRet


/*
�������������qewqe

qw
ewqeqw
e
wqe
wq
ewq
������������������������������������������eqwe
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
����������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  � MacExec  �Autor  � Vin�cius Moreira   � Data � 21/03/2012  ���
�������������������������������������������������������������������������͹��
���Desc.     � Rotina verificadora da macro digitada.                     ���
���          � Altera��es: Cristiam Rossi em 28/01/2016                   ���
�������������������������������������������������������������������������͹��
���Uso       �                                                            ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
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