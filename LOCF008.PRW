#INCLUDE "Totvs.CH"
#INCLUDE "RWMake.CH" 
#INCLUDE "TopConn.ch" 
#INCLUDE "PCOTRYEXCEPTION.CH"

#IfNDef	METODO_PASCOA_GAUSS		
	#Define METODO_PASCOA_MEEUS                                                             
#EndIf                                            


/*                                                                                           
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³008  ºAutor  ³Sergio Celestino    º Data ³  04/25/08   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Gera Pedido de Venda,Libera Pedido e Gera Nota C.T.R.C      º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³                                                       º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±             
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
User Function Locf008(nTipo)
Local aAreaDTQ 	:= DTQ->(GetArea())
Local _aAreaZA6 := ZA6->(GetArea())
Local _aAreaZA7 := ZA7->(GetArea()) 
Local cAlias   	:= ALIAS()
Local _aTemX   
Local _nDT8Pas	:= 0  // Apos a geracao da nota verificamos a integridade entre DT8_VALPAS e DT6_VALPAS
Local _nDT8Imp  := 0  // Apos a geracao da nota verificamos a integridade entre DT8_VALIMP e DT6_VALIMP
Local _nDT8Tot  := 0  // Apos a geracao da nota verificamos a integridade entre DT8_VALTOT e DT6_VALTOT
Local _nDT6Pas  := 0  // Apos a geracao da nota verificamos a integridade entre DT8_VALPAS e DT6_VALPAS
Local _nDT6Imp  := 0  // Apos a geracao da nota verificamos a integridade entre DT8_VALIMP e DT6_VALIMP
Local _nDT6Tot  := 0  // Apos a geracao da nota verificamos a integridade entre DT8_VALTOT e DT6_VALTOT
Local _cMensag  := "" // Mensagem de integridade entre DT8 e DT6
Local bError := { |oError| MyError( oError ) }
Local oError

Private cViagem	:= DTQ->DTQ_VIAGEM   
Private cCC		:= DTQ->DTQ_CCC   
Private cProjet := DTQ->DTQ_SOT
Private nRegDTQ := 0
Private aDTC    := {} 
Private aDTC2   := {} 
Private cValor	:= 0
Private cTpCTRC	:= DTQ->DTQ_TPCTRC
Private _nOutros, _nAdvalo, _nPedagi, _nFrete, _n01Base, _n02Base, _n03Base, _n01Aliq, _n02Aliq, _n03Aliq, _n01VlrI, _n02VlrI, _n03VlrI

Private nTipoPed	:= nTipo // 1= Pedido de venda; 2=Pedido de serviço. 

Private	_numSol := ""
Private _cPcCli  := ""
Private _cPlanId := ""
Private _cNumAst := ""
Private _cFatCli := ""
Private _dDatAst := stod("")

If	cFilAnt != DTQ->DTQ_FILORI
	MsgStop("A T E N Ç Ã O: Para emitir CT-e para a Viagem:"+cViagem+" logar na Filial "+DTQ->DTQ_FILORI)
	Return .F.
EndIf

DTQ->(DBSETORDER(1))  // FILIAL + VIAGEM

if DTQ->(!DbSeek(xFilial("DTQ")+cViagem)) 
 MsgStop("A T E N Ç Ã O: Viagem não foi cadastrada !! "+cViagem)
 Return(.f.)
Else
  while !eof() .and. cViagem == DTQ->DTQ_VIAGEM
     If cProjet == DTQ->DTQ_SOT
        EXIT
     Endif 
     dbskip()  
  Enddo
endif

If !Empty(DTQ->DTQ_NUMCTR) .AND. DTQ->DTQ_NUMCTR <> '-'
	MsgAlert("Já foi gerada a Nota Fiscal CT-e de número " + AllTrim(DTQ->DTQ_NUMCTR) + ", série " + AllTrim(DTQ->DTQ_SERCTR) + ", pedido de venda número " + AllTrim(DTQ->DTQ_NUMPV) + ". Impossível gerar novo CT-e para esta viagem." )
	Return .F.
EndIf

IF !MSGYESNO(Iif(nTipoPed == 2,"Confirma a geração do pedido de serviço","Confirma a geração do CT-e")+" para a viagem "+cViagem+" ?" )
    DBSELECTAREA( cAlias )
    DTQ->(RestArea(aAreaDTQ))
    RETURN .F.
ENDIF
                          

// -------------------------------------------------------------------------------------------
// Forcar o recalculo dos impostos da DT8, Atualiza DTQ e ZA7 - Frank Zwarg Fuga em 04/08/2016
// -------------------------------------------------------------------------------------------
_aTempX := GetArea()
AtuDT8L()
RestArea(_aTempX)
// -------------------------------------------------------------------------------------------

nRegDTQ := DTQ->(RECNO() )

DBSELECTAREA("DTP")
DBSETORDER(3)  // FILIAL + FILORI + VIAGEM 

DBSEEK(XFILIAL("DTP")+DTQ->DTQ_FILORI+DTQ->DTQ_VIAGEM , .T. )

DBSELECTAREA("DTC")
DBORDERNICKNAME("DTCIND09")  // FILIAL + VIAGEM + NUMNFC + SERNFC + CLIREM + LOJREM 
/*
DTC->(DBSEEK(XFILIAL("DTC")+ cViagem)) // JBS 31/01/2007

While DTC->(!EOF()) .AND. DTC_VIAGEM = cViagem
   AADD( aDTC , RECNO() )                 // JBS 31/01/2007
   DTC->(DbSkip())
Enddo  

If Len(aDTC) = 0
	MsgStop("Não Foi Possivél Encontrar as NF's do Cliente!","Atenção")
	Return .F.
EndIF                                     // JBS 31/01/2007

GRV_PV ( aDTC )
GRV_DT6( aDTC[1],nRegDTQ )
*/        

If DTC->(DBSEEK(XFILIAL("DTC")+ cViagem)) .or. nTipoPed == 2 // JBS 31/01/2007    // Frank Z Fuga DTC2
	_cPlanId := cViagem
	_aAreaOld := GetArea()
	_aAreaZA6 := ZA6->(GetArea())
	_aAreaZA7 := ZA7->(GetArea())
	dbSelectArea("ZA7")
//	ZA7->(dbOrderNIckName("ITUPZA7003")) //dbSetOrder(3)
//	If ZA7->(dbSeek(DTQ->DTQ_VIAGEM))
	ZA7->(dbSetOrder(1))
	If ZA7->(dbSeek( DTQ->(DTQ_FILORI+DTQ_SOT+DTQ_OBRA+DTQ_SEQVIA+DTQ_SEQCAR) ))
		_cNumAst := ZA7->ZA7_AS
		If ZA7->ZA7_DEVEMB == "R"	// inverte
			cCodRem := Iif(!Empty(ZA7->ZA7_CLIDES),ZA7->ZA7_CLIDES,U_ZA6ZA7( "ZA6_CLIDES" ))//U_ZA6ZA7( "ZA6_CLIDES" )	// ZA6->ZA6_CLIDES
			cLojRem := Iif(!Empty(ZA7->ZA7_LOJDES),ZA7->ZA7_LOJDES,U_ZA6ZA7( "ZA6_LOJDES" ))//U_ZA6ZA7( "ZA6_LOJDES")	// ZA6->ZA6_LOJDES
			cCodDes := ZA7->ZA7_CODCLI
			cLojDes := ZA7->ZA7_LOJCLI
		Else
			cCodRem := ZA7->ZA7_CODCLI
			cLojRem := ZA7->ZA7_LOJCLI
			cCodDes := Iif(!Empty(ZA7->ZA7_CLIDES),ZA7->ZA7_CLIDES,U_ZA6ZA7( "ZA6_CLIDES" ))//U_ZA6ZA7( "ZA6_CLIDES" )	// ZA6->ZA6_CLIDES
			cLojDes := Iif(!Empty(ZA7->ZA7_LOJDES),ZA7->ZA7_LOJDES,U_ZA6ZA7( "ZA6_LOJDES" ))//U_ZA6ZA7( "ZA6_LOJDES")	// ZA6->ZA6_LOJDES
		EndIf
		dbSelectArea("ZA6")
		ZA6->(dbSetOrder(1))
		If ZA6->(dbSeek(xFilial("ZA6") + ZA7->ZA7_PROJET + ZA7->ZA7_OBRA + ZA7->ZA7_SEQTRA))
			_dDatAst := ZA6->ZA6_DTINI
			If ZA6->ZA6_TPFRET == "F"	// FOB
				cCodCon := iif( !Empty(DTC->DTC_CLICON), DTC->DTC_CLICON, cCodDes )
				cLojCon := iif( !Empty(DTC->DTC_LOJCON), DTC->DTC_LOJCON, cLojDes )
			Else						// CIF
				cCodCon := iif( !Empty(DTC->DTC_CLICON), DTC->DTC_CLICON, cCodRem )
				cLojCon := iif( !Empty(DTC->DTC_LOJCON), DTC->DTC_LOJCON, cLojRem )
			EndIf
		EndIf    
		
	EndIf
	RestArea( _aAreaZA6 )
	RestArea( _aAreaZA7 )
	RestArea( _aAreaOld )
   AADD( aDTC , RECNO() )                 // JBS 31/01/2007             
	
	if Empty( DTC->DTC_CLIEXP )			// Não tem expedidor... apagar a Solicitação
		if !Empty(DTC->DTC_NUMSOL)
			_numSol := DTC->DTC_NUMSOL
		endif
		DTC->( RECLOCK("DTC", .F. ) )
		DTC->DTC_NUMSOL := ""
		DTC->( MsUnlock() )
	endif         
	   
   AADD( aDTC2 , {RECNO(), DTC->DTC_NUMSOL} )                 // JBS 31/01/2007

       
	// caso tenha Expedidor, criamos relação DT5-DUL-DUE. Cristiam Rossi em 18/02/2016
	if !Empty( DTC->DTC_CLIEXP )
	
		_numSol := ""						// obtendo número da solicitação
		for nI := 1 to len( aDTC2 )
			if ! empty( aDTC2[nI][2] )
				_numSol := aDTC2[nI][2]
				exit
			endif
		next
	
		_numSol	:= U_GERDT5(DTC->DTC_CLIEXP,DTC->DTC_LOJEXP, cCodDes,cLojDes, cCodCon,cLojCon, _numSol)
	
		if ! Empty(_numSol)					// caso Exista número de solicitação
			for nI := 1 to len( aDTC2 )
				//if empty( aDTC2[nI][2] )				// se tiver linha em branco, atualiza
					DTC->( DbGoto( aDTC2[nI][1] ) )
					DTC->( RECLOCK("DTC", .F. ) )
					DTC->DTC_NUMSOL := _numSol
            		DTC->DTC_SELORI := StrZero( iif( Empty(DTC->DTC_CLIEXP) , 2, 3 ) , Len(DTC->DTC_SELORI) )	// se tem Expedidor é 3, senão é 2					
					DTC->( MsUnlock() )
				//endif
			next
		endif                                                                            
	else
		if ! Empty(_numSol)				// Tem Número da Solicitação e deve ser excluída
			DT5->( dbSetOrder(3) )
			if DT5->( dbSeek( xFilial("DT5") + _numSol ) )
				RecLock("DT5", .F.)
				DT5->DT5_DATCAN := dDatabase
				DT5->DT5_STATUS := '9'
				DT5->( dbDelete() )
				DT5->( MsUnlock() )
			endif
		endif                                    
	endif
	   
	   
   //GRV_PV( aDTC ) // alterado por Frank Zwarg Fuga 30/11/15     
   GRV_PV2( aDTC ) 
   _cMensag := "" // Frank Zwarg Fuga - 04/08/2016 - valida inconsistencias entre DT8 e DT6
   If nTipoPed <> 2
	   	GRV_DT6( aDTC[1], nRegDTQ )
	   	//Adicionado Joni Chamada do EDI
		DTQ->(DbGoto(nRegDTQ))
	   
		// -------------------------------------------------------------------------------------
	    // Frank Zwarg Fuga - 04/08/2016
	    // Verificacao quanto a integridade dos dados gerados na DT8 e DT6
	    // -------------------------------------------------------------------------------------
		_nDT8Pas  := 0 
		_nDT8Imp  := 0 
		_nDT8Tot  := 0 
		_nDT6Pas  := DT6->DT6_VALFRE
		_nDT6Imp  := DT6->DT6_VALIMP 
		_nDT6Tot  := DT6->DT6_VALTOT
		cQuery := "SELECT DT8_VALPAS, DT8_VALIMP, DT8_VALTOT FROM " + RetSqlName("DT8") + " "
		cQuery += "WHERE  D_E_L_E_T_ = '' AND DT8_CODPAS = 'TF' AND "
		cQuery += "DT8_FILDOC = '"+DTQ->DTQ_FILORI+"' AND "
		cQuery += "DT8_DOC = '"+DTQ->DTQ_NUMCTR+"' AND "
		cQuery += "DT8_SERIE = '"+DTQ->DTQ_SERCTR+"' AND "
		cQuery += "DT8_XVIAGE = '"+DTQ->DTQ_VIAGEM+"' "
		If Select("TRBX") > 0
			TRBX->(dbCloseArea())	 
		EndIf
		TCQUERY cQuery NEW ALIAS "TRBX"
		If !TRBX->(Eof())
			_nDT8Pas  := TRBX->DT8_VALPAS
			_nDT8Imp  := TRBX->DT8_VALIMP
			_nDT8Tot  := TRBX->DT8_VALTOT
		EndIf
		TRBX->(dbCloseArea())	             
		_cMensag := ""
		If _nDT6Pas - _nDT8Pas > 0.05 .or. _nDT8Pas - _nDT6Pas > 0.05
			_cMensag += "DT6_VALFRE = "+alltrim(str(_nDT6Pas))+" diferente de DT8_VALPAS = "+alltrim(str(_nDT8Pas))+" "
		EndIF
		If _nDT6Imp - _nDT8Imp > 0.05 .or. _nDT8Imp - _nDT6Imp > 0.05
			_cMensag += "DT6_VALIMP = "+alltrim(str(_nDT6Imp))+" diferente de DT8_VALIMP = "+alltrim(str(_nDT8Imp))+" "
		EndIf
		If _nDT6Tot - _nDT8Tot > 0.05 .or. _nDT8Tot - _nDT6Tot > 0.05
			_cMensag += "DT6_VALTOT = "+alltrim(str(_nDT6Tot))+" diferente de DT8_VALTOT = "+alltrim(str(_nDT8Tot))+" "
		EndIf	   
		// -------------------------------------------------------------------------------------	   
	   
		U_GERML3EDI()
		

		If !empty(_cMensag) .and. !empty( SuperGetMV("IT_AVISDT8",,"")  )     
			_lProcE := .F.
			BEGIN SEQUENCE
			TRYEXCEPTION USING bError        
				If &(SuperGetMV("IT_REGRDT8",,.T.)) // Regra do cliente
					_lProcE := .T.
					_cAviso := "ATENÇÃO! Identificado divergências referente aos valores de impostos e a geração do CTE foi estornada automaticamente."      
					_cAviso += "Viagem: "+alltrim(DTQ->DTQ_VIAGEM)+". Inconsistência encontrada: "+_cMensag
					_cAviso += " Favor entrar em contato com a equipe de Suporte."
					If !empty( SuperGetMV("IT_AVISDT8",,"")  )     
						U_OrcMail( AllTrim(GetMV("MV_RELFROM")), SuperGetMV("IT_AVISDT8",,"carina.fleicher@gefco.com.br"), , "Divergencias nos impostos. Viagem: "+DTQ->DTQ_VIAGEM, _cAviso, , )
					EndIf
					U_LOCF015()                                                                                                                      
					MsgAlert(_cAviso,"Atenção!")
				EndIF
			CATCHEXCEPTION USING oError         	
			ENDEXCEPTION         
			RECOVER
			END SEQUENCE 	
			
			If !_lProcE
				msgstop("Houve falhas na aplicação da fórmula do parâmetro IT_REGRDT8, ocorreu uma divergência na viagem: "+DTQ->DTQ_VIAGEM+" e os impostos foram gerados de forma indevida.","ERRO GRAVE!")
			EndIf
			
		Else
			_cMensag := "" // forcar em branco quando o IT_AVISDT8 estiver zerado
		EndIf

   EndIF
   
   // Atualizar o registro da DTC com o status 3
   If empty(_cMensag) // If inserido por Frank Z Fuga para controlar as inconsistencias dos impostos 04/08/2016
	   dbSelectArea("DTP")
	   If DTP_FILORI == DTQ->DTQ_FILORI .and. DTP_VIAGEM == DTQ->DTQ_VIAGEM
	   		RecLock("DTP")
	   		DTP->DTP_STATUS := "3"
	   		MsUnlock()
	   EndIF
	EndIf
   
Else
	MsgStop("Não foi Possivél encontrar as NF's do Cliente!","Atenção")
	Return .F.
EndIF  

Return .T.


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³008  ºAutor  ³Microsiga           º Data ³  04/20/11   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³                                                            º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ AP                                                        º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function GRV_DT6( nRecDTC, nRecDTQ)
Local cDtqOri := ""
Local aDtqOri := {}	
Local nLinhas := 0	 
Local cObs    := ""
Local cCodMsg := ""

dbSelectArea("DTQ")
dbGoto(nRecDTQ)

dbSelectArea("DTC")
dbGoto(nRecDTC)

dbSelectArea("SF2")
dbSetOrder(1)
dbSeek(xFilial("SF2")+DTQ->DTQ_NUMCTR+DTQ->DTQ_SERCTR)

dbSelectArea("DT6")
dbSetOrder(1)     

nLinhas := MlCount(DTQ->DTQ_OBSCTR)

For nX := 1 To nLinhas
	cObs += MemoLine(DTQ->DTQ_OBSCTR,,nX)
Next nX                    

If Posicione("SA1",1,xFilial("SA1")+DTC->(DTC_CLIDES+DTC_LOJDES),"A1_EST" ) == 'EX' //SUBSTR(DTQ->DTQ_ORIGEM,LEN(TRIM(DTQ->DTQ_ORIGEM))-1,2) == "EX"
	cCodMsg := "010986" //Icms isento exportação
Else
	cCodMsg := GetCodMsg()
EndIf

// ------- Acumular Valor, Peso e Volumes da DTC p/ gravar na DT6 - Cristiam Rossi em 21/09/2015
	_aAcmDTC := {0,0,0}		// Valor, Peso e Volumes
	aAreaDTC := DTC->( getArea() )
	DTC->( dbSetOrder(10) )
	DTC->( dbSeek( xFilial("DTC") + DTQ->(DTQ_SOT + DTQ_OBRA + DTQ_VIAGEM) ) )
	while ! DTC->( EOF() ) .and. DTC->( DTC_FILIAL+DTC_SOT+DTC_OBRA+DTC_VIAGEM ) == xFilial()+DTQ->(DTQ_SOT+DTQ_OBRA+DTQ_VIAGEM)
		_aAcmDTC[1] += DTC->DTC_VALOR
		_aAcmDTC[2] += DTC->DTC_PESO
		_aAcmDTC[3] += DTC->DTC_QTDVOL
		DTC->( dbSkip() )
	end
	DTC->( restArea( aAreaDTC ) )
//--------------------------------------------------
                
	RecLock("DT6", !dbSeek(xFilial("DT6")+SF2->F2_DOC+SF2->F2_SERIE))
	DT6->DT6_FILDOC	:=	SF2->F2_FILIAL
	DT6->DT6_DOC		:=	SF2->F2_DOC
	DT6->DT6_SERIE	:=	SF2->F2_SERIE
	DT6->DT6_DATEMI	:=	SF2->F2_EMISSAO	
	DT6->DT6_VALFRE	:=	SF2->F2_VALMERC//_aAcmDTC[1]		// DTC->DTC_VALOR
	DT6->DT6_VALIMP	:=	SF2->F2_VALBRUT - SF2->F2_VALMERC//SF2->F2_VALICM
	DT6->DT6_VALTOT	:=	SF2->F2_VALBRUT
	DT6->DT6_VALFAT	:=	SF2->F2_VALBRUT
	DT6->DT6_VALMER	:=	_aAcmDTC[1]	// DTQ->DTQ_BASADV   <---- solicitação Anderson em 28/02/2016
	//DT6_SERTMS	:=	DTQ->DTQ_SERTMS by Frank Zwarg Fuga
	DT6->DT6_SERTMS	:= "3"
	DT6->DT6_TIPTRA	:=	DTQ->DTQ_TIPTRA
	//IF COMPL.ICMS OU COMPL.VALOR 8 || SENAO 2
	DT6->DT6_DOCTMS	:=	StrZero( Iif(cTpCTRC $ "1|2",8,2), Len(DT6->DT6_DOCTMS))	// Documento de Transporte Cadastrado
	DT6->DT6_CDRORI	:=	'' // Cod. Região de Origem
	DT6->DT6_CDRDES	:=	'' // Cod. Região de Destino
	DT6->DT6_CDRCAL	:=	'' // Cod. Região do Calculo
	DT6->DT6_TIPFRE	:=	DTC->DTC_TIPFRE
	DT6->DT6_PRZENT	:=	SF2->F2_EMISSAO
	DT6->DT6_FILORI	:=	DTQ->DTQ_FILORI//DTC->DTC_FILORI
	DT6->DT6_FILDES	:=	DTQ->DTQ_FILORI//DTC->DTC_FILORI
	DT6->DT6_BLQDOC	:=	'2'	//	Bloqueado 1=Sim 2=Não 3=Descarregando
	DT6->DT6_PRIPER	:=	'2' // Primeiro Percurso 1=Sim 2=Não
	DT6->DT6_CLIREM	:=	DTC->DTC_CLIREM
	DT6->DT6_LOJREM	:=	DTC->DTC_LOJREM
	DT6->DT6_CLIDES	:=	DTC->DTC_CLIDES
	DT6->DT6_LOJDES	:=	DTC->DTC_LOJDES
	DT6->DT6_CLIDEV	:=	DTC->DTC_CLIDEV
	DT6->DT6_LOJDEV	:=	DTC->DTC_LOJDEV
	DT6->DT6_CLICAL	:=	DTC->DTC_CLICAL
	DT6->DT6_LOJCAL	:=	DTC->DTC_LOJCAL
	DT6->DT6_CLICON	:=	DTC->DTC_CLICON
	DT6->DT6_LOJCON	:=	DTC->DTC_LOJCON
	DT6->DT6_CCUSTO := 	DTQ->DTQ_CCC
	DT6->DT6_CCONT	:=	DTC->DTC_CCONT
	DT6->DT6_OI     :=  DTC->DTC_OI 
	DT6->DT6_CONTA  :=	DTC->DTC_CONTA
	DT6->DT6_TIPDES :=	DTC->DTC_TIPDES
    DT6->DT6_REFGEF :=	DTC->DTC_REFGEF
    DT6->DT6_XORICT := 'GPO'
                          
	//Tomador do serviço
	If DTC->(DTC_CLICON+DTC_LOJCON) == DTC->(DTC_CLIREM+DTC_LOJREM)//remetente
		DT6->DT6_DEVFRE := "1"
	ElseIf DTC->(DTC_CLICON+DTC_LOJCON) == DTC->(DTC_CLIDES+DTC_LOJDES)//destinatario
		DT6->DT6_DEVFRE := "2"
	Else//Outros
		DT6->DT6_DEVFRE := "3"
	EndIf
	//DT6_DEVFRE	:=	Iif(DTC->DTC_CLIDEV+DTC->DTC_LOJDEV = DTC->DTC_CLIDES+DTC->DTC_LOJDES,'1','2')
	DT6->DT6_SERVIC	:=	'010'	//
	DT6->DT6_CODMSG	:=	cCodMsg
	DT6->DT6_STATUS	:=	'7'		//
	DT6->DT6_PESO	:=	_aAcmDTC[2]		//DTC->DTC_PESO
	DT6->DT6_VOLORI	:=	_aAcmDTC[3]		//DTC->DTC_QTDVOL
	DT6->DT6_QTDVOL	:=	_aAcmDTC[3]
	DT6->DT6_HOREMI	:=	RetHora(SF2->F2_HORA) 
	DT6->DT6_CLIDPC	:=  DTC->DTC_CLIDPC
	DT6->DT6_LOJDPC	:=  DTC->DTC_LOJDPC
	//_cPcCli     := DTQ->DTQ_NUMPV
	
	// Alterado por Frank Zwarg Fuga em 11/08/2016
	_cPcCli     := ""	
	cQueryX 	:= "SELECT ZA6.ZA6_PEDCLI AS PEDCLI "
	cQueryX 	+= "FROM ZA6010 ZA6, ZA7010 ZA7, DTQ010 DTQ "
	cQueryX 	+= "WHERE ZA6.D_E_L_E_T_ = '' AND ZA7.D_E_L_E_T_ = '' AND DTQ.D_E_L_E_T_ = '' AND "
	cQueryX 	+= "ZA6.ZA6_PROJET = ZA7.ZA7_PROJET AND ZA6.ZA6_OBRA = ZA7.ZA7_OBRA AND	ZA6.ZA6_SEQTRA = ZA7.ZA7_SEQTRA AND "
	cQueryX 	+= "ZA7.ZA7_VIAGEM = DTQ.DTQ_VIAGEM AND "
	cQueryX 	+= "DTQ.DTQ_VIAGEM = '"+DTQ->DTQ_VIAGEM+"' "
	If Select("TRBX") > 0
		TRBX->(dbCloseArea())	 
	endif
	TCQUERY cQueryX NEW ALIAS "TRBX"              
	_cPcCli     :=  TRBX->PEDCLI
	TRBX->(dbCloseArea())
	
	_cFatCli 	:= DTQ->DTQ_NUMCTR
	//DT6_HOREMI	:=	StrTransF(SF2->F2_HORA,":","")
	If Empty(StrTran(Alltrim(GetMv("IT_RPJFIAT")),".","")) .or.;
	   Substr(Alltrim(Posicione("SA1",1,xFilial("SA1") + SF2->F2_CLIENTE+SF2->F2_LOJA, "A1_CGC")),1,8) $ StrTran(Alltrim(GetMv("IT_RPJFIAT")),".","")
		DT6->DT6_XPCCLI := _cPcCli
		DT6->DT6_PLANID := _cPlanId
		DT6->DT6_NUMAST := _cNumAst
		DT6->DT6_FATCLI := _cFatCli
		DT6->DT6_DTEDIC := _dDatAst
	EndIf
	
	// Gravacao do campo MEMO
	_cTexto := DTQ->DTQ_OBSCTR
	MSMM(DT6->DT6_CODOBS,,,_cTexto,1,,,"DT6","DT6_CODOBS")
    // O msmm esta liberando a trava de gravacao da DT6.    
    // -------------------------------------------------
	DT6->(MsUnlock())


	_areaDTC := DTC->( getArea() )
	_Viagem  := DTC->DTC_VIAGEM
	DTC->( dbOrderNickName("DTCIND09") )
	DTC->( dbSeek( xFilial("DTC") + _Viagem ) )
	while ! DTC->( EOF() ) .and. xFilial("DTC")+_Viagem == DTC->( DTC_FILIAL + DTC_VIAGEM )
		RecLock("DTC", .F. )
		MSMM(DTC->DTC_CODOBS,,,_cTexto,1,,,"DTC","DTC_CODOBS")
		DTC->( MsUnlock() )
		DTC->( dbSkip() ) 
	end
	DTC->( restArea( _areaDTC ) )


	dbSelectArea("DT6")
	RecLock("DT6",.F.)                                  
	// -------------------------------------------------
	
	If !Empty(cTpCTRC)//Gravar doc e serie para o CTRC complementar do CTRC original
		cDtqOri := GetDTQOri(DTQ->DTQ_SOT,DTQ->DTQ_AS,DTQ->DTQ_CTRORI)
		aDtqOri := StrTokArr(cDtqOri,";")
		DT6->DT6_FILDCO := SF2->F2_FILIAL
		DT6->DT6_DOCDCO := aDtqOri[1]
		DT6->DT6_SERDCO := aDtqOri[2]
	EndIf

	// Alterado por Frank Zwarg Fuga - 01/12/2015      
	DT6->DT6_USRGER := RetCodUsr()	
	dbSelectArea("SX5")
	dbSetOrder(1)
	dbSeek(xFilial("SX5")+"_C"+"000000") // Posicionar no primeiro item das categorias
	_cTemp := substr(X5_DESCRI,1,2)
	dbSelectArea("DT8")
	dbOrderNickName("ITUPDT8001") // xviage+codpas
	dbSeek(DTQ->DTQ_VIAGEM+_cTemp)
	If !eof()
		DT6->DT6_CDRORI := DT8->DT8_CDRORI
		DT6->DT6_CDRDES := DT8->DT8_CDRDES 
		DT6->DT6_CDRCAL := DT8->DT8_CDRDES
		DT6->DT6_LOTNFC := DTC->DTC_LOTNFC 
		DT6->DT6_XORICT := "GPO"
	EndIF 
	
	// Alterado por Frank Zwarg Fuga - 01/12/2015
	SE1->( dbSeek( xFilial("SE1") + SF2->(F2_PREFIXO + F2_DUPL), .T. ) )
	while ! SE1->( EOF() ) .and. SE1->(E1_FILIAL+E1_PREFIXO+E1_NUM)==xFilial("SE1")+SF2->(F2_PREFIXO + F2_DUPL)
       if SE1->E1_TIPO == "NF "
	   		DT6->DT6_VENCTO := SE1->E1_VENCREA
	   		DT6->DT6_FILDEB := SE1->E1_FILDEB
	   		DT6->DT6_PREFIX := SE1->E1_PREFIXO
	   		DT6->DT6_NUM    := SE1->E1_NUM
	   		DT6->DT6_TIPO   := SE1->E1_TIPO
	   		DT6->DT6_MOEDA  := SE1->E1_MOEDA                      
	   		Exit
       endif
       SE1->( dbSkip() )
   end

	DT6->(MsUnLock())

	DbSelectArea("DT8")

	RecLock("DT8", .T.)
	DT8->DT8_FILIAL	:=	xFilial("DT8")
	DT8->DT8_CODPAS	:=	'TF'
	DT8->DT8_VALTOT	:=	SF2->F2_VALBRUT//DTQ->DTQ_TOTFRE
	DT8->DT8_VALPAS	:=	SF2->F2_VALMERC//DTQ->DTQ_XFRETE	//DTQ->DTQ_VALICM
	DT8->DT8_VALIMP	:=	SF2->F2_VALBRUT - SF2->F2_VALMERC//DTQ->DTQ_TOTFRE	- DTQ->DTQ_XFRETE//DTQ->DTQ_VALICM
	DT8->DT8_FILDOC	:=	DT6->DT6_FILDOC
	DT8->DT8_DOC	:=	DT6->DT6_DOC
	DT8->DT8_SERIE	:=	DT6->DT6_SERIE
	DT8->DT8_FILORI	:=	DT6->DT6_FILORI
	DT8->DT8_CDRORI	:=	DT6->DT6_CDRORI
	DT8->DT8_CDRDES	:=	DT6->DT6_CDRDES
	DT8->DT8_CODPRO	:=	DTC->DTC_CODPRO
	DT8->DT8_XVIAGE	:=	DTQ->DTQ_VIAGEM
	DT8->DT8_CALMIN	:=  "2"
MsUnLock()
     
/* by Frank Zwarg Fuga a pedido do Anderson
RecLock("DT8", .T.)
	DT8_FILIAL	:=	xFilial("DT8")
	DT8_CODPAS	:=	'FR'
	DT8_VALTOT	:=	DTQ->DTQ_VALADV
	DT8_VALPAS	:=	DTQ->DTQ_TOTFRE	-	DTQ->DTQ_VALICM
	DT8_VALIMP	:=	DTQ->DTQ_VALICM
	DT8_FILDOC	:=	DT6->DT6_FILDOC
	DT8_DOC		:=	DT6->DT6_DOC
	DT8_SERIE	:=	DT6->DT6_SERIE
	DT8_FILORI	:=	DT6->DT6_FILORI
	DT8_CDRORI	:=	DT6->DT6_CDRORI
	DT8_CDRDES	:=	DT6->DT6_CDRDES
	DT8_CODPRO	:=	DTC->DTC_CODPRO
MsUnLock()
 */
DbSelectArea("DUD")   //13012016PEDRASSI

	RecLock("DUD", .T.)   
	
		DUD->DUD_FILIAL	:=	xFilial("DUD")
		DUD->DUD_FILORI	:=	DT6->DT6_FILORI
		DUD->DUD_FILDOC	:=	DT6->DT6_FILDOC
		DUD->DUD_DOC	:=	DT6->DT6_DOC
		DUD->DUD_SERIE	:=	DT6->DT6_SERIE
		DUD->DUD_SERTMS	:=	DT6->DT6_SERTMS
		DUD->DUD_TIPTRA := 	'1'      
		DUD->DUD_CDRDES	:=	DT6->DT6_CDRDES
		DUD->DUD_VIAGEM	:=	DTQ->DTQ_VIAGEM
		DUD->DUD_FILDCA	:=	DT6->DT6_FILORI
		DUD->DUD_SEQUEN	:=	'001'
		DUD->DUD_GERROM :=	'1'
		DUD->DUD_SERVIC	:=	''
		DUD->DUD_CDRCAL	:=	DT6->DT6_CDRCAL
		DUD->DUD_FILDCA	:=	DT6->DT6_FILORI
		DUD->DUD_ENDERE	:=	'0'
		DUD->DUD_STATUS	:=	'2'
		DUD->DUD_STROTA	:=	'3'
		DUD->DUD_DOCTRF	:=	'2'
		DUD->DUD_SEQENT	:=	'001'
		DUD->DUD_FILATU	:=	DT6->DT6_FILORI
		              
	DUD->(MsUnLock())
	
Return .T.                               

//-----------------function--------------
Static Function RetHora(cHora)
Local cEst		:=	SM0->M0_ESTCOB
Local cNHVEst	:=	GetMv('LC_ESTFORA',,'BA')
Local cHoraNew	:=  cHora

//Valida se o estada deve ter redução de uma hora 
If cEst $ cNHVEst

	//Valida se o mes esta dentro do periodo do horario de verão 
	If Month(dDataBase) >= 10 .Or. Month(dDataBase) <= 2         

		//Valida se esta dentro do horario de verão desse ano (Mes > 1 e menor ou igual à 2)  ou do ano passado (Mes > 10 e menor ou igual à 12)	
		If (dDataBase >= HorVerao(dDataBase)[1]  .And. dDataBase <= HorVerao(dDataBase)[2]) .Or. (dDataBase >= HorVerao(dDataBase-365)[1]  .And. dDataBase <= HorVerao(dDataBase-365)[2])
		
		//Subtrai uma hora do horario atual
			cHoraNew := __TimeSub(cHora, '01:00')
		EndIf
		
	EndIf		
	
EndIf

Return(Replace(cHoraNew,':',''))

Static Function Pascoa(dDate)
Local nVarLen		:=	SetVarNameLen(100)
Local cAno			:=	Left(DToS(dDate),4)
Local cDia			:=	Space(2)
Local cMes			:=	Space(2)
Local dRet
Local A
Local B
Local C
Local D
Local E


#IFDEF METODO_PASCOA_GAUSS
	Local X					
	Local Y
	Local nFaixa		:=	aScan(aFaixasAnos, {|Ano|  cAno >= Ano[1] .And. cAno <= Ano[2]} )

	Static aFaixasAnos	:=	{	{'1600','1699',22	,2},;
								{'1700','1799',23	,3},;
								{'1800','1899',23	,4},;
								{'1900','1999',24	,5},;
								{'2000','2099',24	,5},;
								{'2100','2199',24	,6},;
								{'2200','2299',25	,7}}	
								
									
	
	If nFaixa == 0 
		Return 
	EndIf  
	
	
	//Algoritimo de Gauss para Calculo da Pascoa
	X := aFaixasAnos[nFaixa][3]
	Y := aFaixasAnos[nFaixa][4]
	
	
	A	:=	Mod(Val(cAno),19)
	B	:=	Mod(Val(cAno),04)
	C	:=	Mod(Val(cAno),07)
	D	:=	Mod((19*A)+X,30)
	E	:=	Mod(((2*B)+(4*C)+(6*D)+Y),7)
	
	//o domingo de pascoa sempre vai ser entre 22 de março a 25 de abril
	If	(D+E) < 10	
		cDia	:=	StrZero(D+E+22,2)
		cMes	:=	'03'
	Else
		cDia	:=	StrZero(D+E-9,2)
		//Exceções a Regra
		Do Case
			Case cDia == '26' 
				cDia	:=	'19'
			Case cDia == '25' .And. D == 28 .And. A > 10
				cDia	:=	'18'
		EndCase
		
		cMes	:=	'04'
	EndIf
		


#Else
	#IfDef METODO_PASCOA_MEEUS
		
		Local F
		Local G
		Local H
		Local I
		Local J
		Local K
		Local L
		
		
		A	:=	Mod(Val(cAno), 19)
		B	:=	Int(Val(cAno)/100)
		C	:=	Mod(Val(cAno),100)
		D	:=	Int(B/4)
		E	:=	Mod(B,4)
		F	:=	Int( (B + 8) / 25 )
		G	:=	Int( (B - F + 1) / 3)
		H	:=	Mod(19 * A + B - D - G + 15, 30)
		I	:=	Int(C/4)
		J	:=	MOD(C,4)
		K	:=	MOD( (32 + 2 * E + 2 * I - H - J), 7 )
		L	:=	Int( (A + 11 * H + 22 * K) / 451 )
		
		cMes	:=	cValToChar( Int( ( H +  K - 7 * L + 114 ) / 31 ) )
		cDia	:=	cValToChar( Mod( (H + K - 7 * L + 114), 31 ) + 1 )
		
		
	#Else	
		cAno	:=	Space(2)
	#EndIf
#EndIf


Set(4,"dd/mm/"+If(__SetCentury(),"yyyy","yy"))

dRet := CToD(cDia+'/'+cMes+'/'+cAno)

SetVarNameLen(nVarLen)		

Return( dRet )



Static Function Carnaval(dDate)
Local dPascoa	:=	Pascoa(dDate)

If ValType(dPascoa) == 'U'
	Return
EndIf

Return(dPascoa-47)


Static Function HorVerao(dDate)
Local nCount	:=	0
Local cAno		:=	Left(DtoS(dDate),4)
Local lBissexto	:=	Mod(Val(Soma1(cAno)),4) == 0 .And. (Mod(Val(Soma1(cAno)),400) == 0 .And. Mod(Val(Soma1(cAno)),100) <> 0)  // Calcula se o ano é bissexto
Local dIni		
Local dFim	

//Calcula o 3º domingo do mes de outubro sendo esse o dia inicial do horario de verão
For nX :=	SToD(cAno+'1001') To SToD(cAno+'1031')
	If Dow(nX) == 1
		nCount++
		If nCount == 3		// 3º Domingo
			dIni	:=	nX
			Exit
		EndIf		
	EndIf
Next nX

//Zera o Contador
nCount	:=	0
//Incrementa 1 ao ano para calculo de termino do horario de verão
cAno	:=	Soma1(cAno)

//Calcula o 3º domingo de fevereiro do proximo ano caso o mesmo seja o carnaval pegar o proximo domingo
For nX :=	SToD(cAno+'0201') To SToD(cAno+'02'+Iif(lBissexto,'29','28'))
	If Dow(nX) == 1
		nCount++
		If nCount == 3 .And. Empty(dFim) // 3º Domingo
			dFim	:=	nX
			If !dFim == Carnaval(dFim)	//Se não for carnaval finaliza
				Exit
			EndIf
		Else
			If !Empty(dFim)	//Somente quando é carnaval
				dFim	:=	nX	
				Exit
			EndIf
		EndIf		
	EndIf
Next nX

Return({dIni,dFim})

Static Function GetDTQOri(cSot,cAs,cCtrOri)
	Local aArea	 := GetArea()
	Local cQuery := ""  
	Local cRet   := ""             
	
	cQuery := "SELECT DTQ.DTQ_NUMCTR, DTQ.DTQ_SERCTR "
	cQuery += " FROM " + RetSqlName('DTQ') + " DTQ "
	cQuery += " WHERE DTQ.DTQ_FILIAL = '"+xFilial("DTQ")+"' "
	cQuery += " AND DTQ.D_E_L_E_T_ <> '*' "
	cQuery += " AND DTQ.DTQ_SOT = '"+cSot+"' "
	cQuery += " AND DTQ.DTQ_AS = '"+cAs+"' "
	cQuery += " AND DTQ.DTQ_VIAGEM = '"+cCtrOri+"' "
	
	cQuery := ChangeQuery(cQuery)

	If Select("TRB01") > 0
		TRB01->(DbCloseArea())
	EndIf  
	                                                                  
	TcQuery cQuery New Alias "TRB01"    
	
	DbSelectArea("TRB01") 
	cRet := TRB01->DTQ_NUMCTR+";"+TRB01->DTQ_SERCTR              
	
	RestArea(aArea)
Return(cRet)

Static Function AcertoICMS(cNota,cSerie,cOpc) 
	Local aArea	 	:= GetArea()
	Local aAreaSD2	:= SD2->(GetArea())
	Local aAreaSFT	:= SFT->(GetArea())	
	Local aAreaSF3	:= SF3->(GetArea())	
	Local aAreaSF2	:= SF2->(GetArea())	
	Local nValICM   := 0
	Local aRecSFT	:= {}
	Local aRecSD2	:= {}             
	Local aRecSF3	:= {}
	Local aRecSF2	:= {}
    
    DbSelectArea("DTQ")
    DbSetOrder(1)
    DbGoto(nRegDTQ)
    
    nAliqIcm := DTQ->DTQ_PERICM
    
    If !DTQ->DTQ_DESICM //Se não destaca icms, não faz o acerto.
    	Return
    EndIf
    
	If cOpc == "I"	
		DbSelectArea("SD2")
		DbSetOrder(3) //Doc+Serie
		DbSeek(xFilial("SD2")+cNota+cSerie)
		
		While !SD2->(Eof()) .And. SD2->(D2_FILIAL+D2_DOC+D2_SERIE) == xFilial("SD2")+cNota+cSerie 
			nValICM := (SD2->D2_TOTAL * SD2->D2_ALIQSOL)/100
			aAdd(aRecSD2,{SD2->(Recno()),nValICM,SD2->D2_TOTAL})		
			DbSelectArea("SFT")
		   	DbSetOrder(1)//Tipo mov+serie+nota+cliEfor+loja+item+produto
		   	If DbSeek(xFilial("SFT")+"S"+SD2->D2_SERIE+SD2->D2_DOC+SD2->D2_CLIENTE+SD2->D2_LOJA+SD2->D2_ITEM)
		   		aAdd(aRecSFT,{SFT->(Recno()),SD2->D2_ALIQSOL,SD2->D2_TOTAL,nValICM})
		   	EndIf
			
			SD2->(DbSkip())
		EndDo
	    
	    //==================================
	    //Atualiza as tabelas SD2  e SFT   
	 	For nX := 1 To Len(aRecSD2)
	 		DbSelectArea("SD2")
	 		DbGoTo(aRecSD2[nX,1])
	 		RecLock("SD2", .F.)
	   		SD2->D2_VALICM  := aRecSD2[nX,2]
	   		SD2->D2_BASEICM := aRecSD2[nX,3]
	   		MsUnlock()	
	 	Next nX
	 	
	 	For nX := 1 To Len(aRecSFT)
	 		DbSelectArea("SFT")
	 		DbGoTo(aRecSFT[nX,1])
	 		RecLock("SFT", .F.)
	   		SFT->FT_ALIQICM := aRecSFT[nX,2]
	   		SFT->FT_BASEICM := aRecSFT[nX,3]
	   		SFT->FT_VALICM	:= aRecSFT[nX,4]
	   		MsUnlock()	
	 	Next nX
   		//==================================
   	Else
   		DbSelectArea("SD2")
		DbSetOrder(3) //Doc+Serie
		DbSeek(xFilial("SD2")+cNota+cSerie)
		
		While !SD2->(Eof()) .And. SD2->(D2_FILIAL+D2_DOC+D2_SERIE) == xFilial("SD2")+cNota+cSerie 
			nValICM := (SD2->D2_TOTAL * nAliqIcm)/100
			aAdd(aRecSD2,{SD2->(Recno()),nValICM})		
			DbSelectArea("SFT")
		   	DbSetOrder(1)//Tipo mov+serie+nota+cliEfor+loja+item+produto
		   	If DbSeek(xFilial("SFT")+"S"+SD2->D2_SERIE+SD2->D2_DOC+SD2->D2_CLIENTE+SD2->D2_LOJA+SD2->D2_ITEM)
		   		aAdd(aRecSFT,{SFT->(Recno()),nValICM})
		   	EndIf
			
			SD2->(DbSkip())
		EndDo    
		
		DbSelectArea("SF2")
		DbSetOrder(1)
		DbSeek(xFilial("SF2")+cNota+cSerie)
		While !SF2->(Eof()) .And. SF2->(F2_FILIAL+F2_DOC+F2_SERIE) == xFilial("SF3")+cNota+cSerie
		    nValICM := (SF2->F2_BASEICM * nAliqIcm)/100 
		    aAdd(aRecSF2,{SF2->(Recno()),nValICM})
			SF2->(DbSkip())
		EndDo
		
		DbSelectArea("SF3")
		DbSetOrder(6)
		DbSeek(xFilial("SF3")+cNota+cSerie)
		While !SF3->(Eof()) .And. SF3->(F3_FILIAL+F3_NFISCAL+F3_SERIE) == xFilial("SF3")+cNota+cSerie
		    nValICM := (SF3->F3_BASEICM * nAliqIcm)/100 
		    aAdd(aRecSF3,{SF3->(Recno()),nValICM})
			SF3->(DbSkip())
		EndDo
		
		//==================================
	    //Atualiza as tabelas SD2, SFT e SF3  
	 	For nX := 1 To Len(aRecSD2)
	 		DbSelectArea("SD2")
	 		DbGoTo(aRecSD2[nX,1])
	 		RecLock("SD2", .F.)
	   		SD2->D2_VALICM  := aRecSD2[nX,2]
	   		SD2->D2_PICM	:= nAliqIcm
	   		MsUnlock()	
	 	Next nX
	 	
	 	For nX := 1 To Len(aRecSFT)
	 		DbSelectArea("SFT")
	 		DbGoTo(aRecSFT[nX,1])
	 		RecLock("SFT", .F.)
	   		SFT->FT_VALICM	:= aRecSFT[nX,2]
	   		SFT->FT_ALIQICM := nAliqIcm
	   		MsUnlock()	
	 	Next nX      
	 	
	 	For nX := 1 To Len(aRecSF2)
	 		DbSelectArea("SF2")
	 		DbGoTo(aRecSF2[nX,1])
	 		RecLock("SF2", .F.)
	   		SF2->F2_VALICM	:= aRecSF2[nX,2]
	   		MsUnlock()	
	 	Next nX
	 	
	 	For nX := 1 To Len(aRecSF3)
	 		DbSelectArea("SF3")
	 		DbGoTo(aRecSF3[nX,1])
	 		RecLock("SF3", .F.)
	   		SF3->F3_VALICM	:= aRecSF3[nX,2]
	   		SF3->F3_ALIQICM := nAliqIcm
	   		MsUnlock()	
	 	Next nX      
	 	//===========================
   	EndIf
   	                  
   	RestArea(aAreaSF2)
	RestArea(aAreaSF3)
	RestArea(aAreaSFT)
	RestArea(aAreaSD2)
	RestArea(aArea)
Return

Static Function GetCodMsg()
	Local aArea	:= GetArea()	
	Local cRet	:= ""
	Local cQuery:= ""
	
	cQuery := "SELECT DUG_CODMSG AS CODMSG "
	cQuery += "FROM "+RetSqlName("DUG")+" "
	cQuery += "WHERE DUG_FILIAL = '"+xFilial("DUG")+"' "
	cQuery += "AND D_E_L_E_T_ <> '*' "
	cQuery += "AND DUG_TES = '"+DTQ->DTQ_TES+"' "
	cQuery += "AND DUG_ESTORI = '"+SUBSTR(DTQ->DTQ_ORIGEM,LEN(TRIM(DTQ->DTQ_ORIGEM))-1,2)+"' "     
	
	TcQuery cQuery New Alias "TRB"

	dbSelectArea("TRB")
	TRB->(dbGoTop())     
	
	Do While !TRB->(Eof())
	   
	   cRet := TRB->CODMSG
	   Exit
	EndDo
	
	TRB->(dbCloseArea())
	
	RestArea(aArea)
	
Return(cRet)





/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³GRV_PV2   ºAutor  ³Frank Zwarg Fuga    º Data ³  04/25/08   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Gera Pedido de Venda por componente                        º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³                                                            º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function GRV_PV2( aDTC )
Local _aCompo 		:= {}, _nX
Local _aItens 		:= {}    
Local _aArea  		:= GetArea()
Local _cDescr 		:= ""
Local i
Local cALIAS        := alias()
Local cProdNfs		:= GetMv("LC_PROSERV") // Produto Serviço
Local cNaturez      := GetMv("MV_CTRCNAT",,"E010201")
Local aCamposSC5    := {}
Local aCamposSC6    := {}            
Local aItens        := {}                                  
Local cNumSC5       := CriaVar("C5_NUM")
Local nPeso         := 0
Local nQtdVol       := 0
Local cItem         := "00"  
Local aNotas        := {}
Local aPvlNfs 	    := {}
Local nPrcVen 	    := 0
Local lCredito		:= .T.
Local lEstoque		:= .T.
Local lAvCred		:= .F.
Local lAvEst		:= .F.
Local lLiber		:= .T.
Local lTransf    	:= .F.
Local lRetEnv		:= .F.
Local cTipo			:= ""  
Local cVendedor		:= ""
Local cCCG			:= ""
Local nComissao		:= 0 
Local aAreaZA0		:= ZA0->(GetArea())
Local aAreaSA3		:= SA3->(GetArea())
Local lRndSOB   	:= getMV("MV_RNDSOBR")
Local lRndICM   	:= getMV("MV_RNDICM")
Local cProduto      := GetMv("MV_CTRCPRO",,"999912")
Local _aNotas       := {}
Local _cTexto		:= ""

Local cCCZA7        := ""	// responsável para gravar o CC na SE1 após faturamento do CT-e - Cristiam Rossi

//Local cProFreP      := GetMv("LC_CTRCFPE")   //FRETE PESO                                        
//Local cProFreV      := GetMv("LC_CTRCFVA")   //FRETE VALOR                                       
//Local cProSegC      := GetMv("LC_CTRCICM")   //SEGURO CTRC                                       
//Local cProIcmct     := GetMv("LC_CTRCSEG")   //ICMS SOBRE CTRC 

Private cnumero     := "" 
Private lMsErroAuto := .F.
Private lMsHelpAuto := .F.     
Private cSerie      := GetMv("MV_SERIECT" ,, "U  ")

// ----------------------------------------------------
// Passo 1 - encontrar na tabela os componentes validos
// ----------------------------------------------------
dbSelectArea("SX5")
dbSetOrder(1)
dbSeek(xFilial("SX5")+"_C") 
If !Eof()
	While !Eof() .and. X5_TABELA == "_C"   
		If !empty(DTQ->DTQ_CTRORI) .and. X5_CHAVE == "000000" // Frank Z Fuga - aceitar somente o 000000 quando for complementar
			aadd(_aCompo,{substr(X5_DESCRI,1,2),X5_CHAVE})
		Else  
			If empty(DTQ->DTQ_CTRORI)
				aadd(_aCompo,{substr(X5_DESCRI,1,2),X5_CHAVE})
			EndIF
		EndIF
		dbSkip()
	EndDo
Else
	MsgStop("Não foram encontrados componentes validos na Tabela SX5.","Atenção!")
	RestArea(_aArea)
	Return .F.
EndIF                                                  
                   
// ---------------------------------------------------------------------------------------
// PASSO 2 - Alimentar o array dos itens com o conteudo da DT8 que possui valor preenchido
// ---------------------------------------------------------------------------------------
For _nX := 1 to Len(_aCompo)
	_cDescr := ""
	dbSelectArea("DT8")
	dbOrderNickName("ITUPDT8001") // xviage+codpas
	dbSeek(DTQ->DTQ_VIAGEM+_aCompo[_nX][01])
	If !Eof() .and. DT8_VALTOT > 0
	    
        dbSelectArea("SX5")
        dbSetOrder(1)
		dbSeek(xFilial("SX5")+"_C"+_aCompo[_nX][02])       
	    dbSelectArea("DT8")
		    
    	dbSelectARea("DT3")
		dbSetOrder(1)
		dbSeek(xFilial("DT3")+_aCompo[_nX][01])          
		If !Eof()    
			_cDescr := alltrim(DT3->DT3_DESCRI)
			aadd(_aItens,{DTQ->DTQ_VIAGEM, DT8->DT8_FILORI, DT8->DT8_CODPAS, DT8->DT8_VALPAS, DT8->DT8_CDRORI, DT8->DT8_CDRDES, DT8->DT8_VALIMP, DT8->DT8_VALTOT, DT8->DT8_XTES, _aCompo[_nX][01], _aCompo[_nX][02], _cDescr, DT3->DT3_XCODPR})
		EndIF
	EndIF
Next

If len(_aItens) == 0
	MsgStop("Houve uma falha na geração do registro, não foi encontrado um vínculo na tabela da composição do frete.","Atenção!")
	RestArea(_aArea)
	Return .F.
EndIF

DTC->(DBGOTO( aDTC[1] ) )  // posiciona no DTC ( PRIMEIRO REGISTRO ) PARA PEGAR O TES E A CONDICAO DE PAGAMENTO

cCondPag := DTQ->DTQ_CONDPG
cTES     := DTQ->DTQ_TES     
cCCG	 := DTQ->DTQ_CCC

If nTipoPed <> 2
	cNumnota:=sx5numNota(cSerie)
EndIf

aAreaSC5 := SC5->(GetArea()) 

Dbselectarea("SC5")
DbSetorder(1)

cNumSC5 := GetSxeNum("SC5","C5_NUM")
cMay := "SC5"+Alltrim(xFilial("SC5"))+cNumSC5

While (MsSeek(xFilial("SC5")+cNumSC5)) //.OR. !MayIUseCode(cMay))
	cNumSC5 := Soma1(cNumSC5,Len(cNumSC5))
EndDo                                                             

RestArea(aAreaSC5)

For i := 1 To Len(aDTC)

	nQtdVol += DTC->DTC_QTDVOL
	nPeso   += DTC->DTC_PESO                 
	
Next

nValTot := DTQ->DTQ_XFRETE+DTQ->DTQ_VRPEDA+DTQ->DTQ_VROUTR
nValPre := DTQ->DTQ_VALADV  // / (1-(DTQ->DTQ_PERICM / 100)) //Embuti icms no advalorem 
nValInf := DTQ->DTQ_VLRINF 
//cTipoF := DTC->DTC_TIPFRE
cCTROri:= DTQ->DTQ_CTRORI
//cTipoF := IIF(cTipoF=="1","C","F")
cCfop  := DTQ->DTQ_CFOP

If Empty(DTQ->DTQ_TPCTRC)
	cTipo := "N"//Normal
ElseIf DTQ->DTQ_TPCTRC == "1"
	cTipo := "C"//Compl.Preco
ElseIf DTQ->DTQ_TPCTRC == "2"
    cTipo := "I"//Compl.ICMS
EndIf   
dbSelectArea("SC7")
dbSetOrder(1)


DbSelectArea("ZA0")
DbSetOrder(1)
DbSeek(xFilial("ZA0")+DTQ->DTQ_SOT)

cTipoF := If( empty(DTC->DTC_TIPFRE),  ZA0->ZA0_TPFRET    ,DTC->DTC_TIPFRE ) // Frank Z Fuga DTC2
cTipoF := IIF(cTipoF=="1","C","F")


DbSelectArea("SA3")
DbSetOrder(1)
DbSeek(xFilial("SA3")+ZA0->ZA0_VENDED)

cVendedor := SA3->A3_COD
nComissao := SA3->A3_COMIS

RestArea(aAreaSA3)
RestArea(aAreaZA0)

For f:= 1 To Len( aDTC )                                                          
	DTC->(DBGOTO( aDTC[f] ) )  // posiciona no DTC
	
	// Frank Z Fuga DTC2
	// Tratamento especifico quando nao houver a DTC
	If empty(DTC->DTC_CLIDEV)
		_cCli := ZA0->ZA0_CLI
		_cLoj := ZA0->ZA0_LOJA
	Else
		_cCli := DTC->DTC_CLIDEV
		_cLoj := DTC->DTC_LOJDEV
	EndIf
	
	
	If Empty( aCamposSC5 )
		_cTexto := DTQ->DTQ_OBSCTR
		_cTexto := StrTran(_cTexto,CHAR(10)," ")
		_cTexto	:= StrTran(_cTexto,CHAR(13)," ")
		_cTexto	:= StrTran(_cTexto,"  "," ")   
		
		If !Empty(DTC->DTC_CLIREC)
			_FrCli := DTC->DTC_CLIREC 
			_FrLoj := DTC->DTC_LOJREC 
		Else
			If empty(DTC->DTC_CLIDES)
				_FrCli := _cCli
				_FrLoj := _cLoj
			Else
				_FrCli := DTC->DTC_CLIDES    
				_FrLoj := DTC->DTC_LOJDES
			EndIf
		EndIf
			

// Cristiam Rossi - alterado para pegar as ZA7 pelo índice 1 (filial+projeto+obra+seqtra+seqcar
//						{"C5_CCUSTO"	, Posicione('ZA7',3,If(empty(DTQ->DTQ_CTRORI),DTQ->DTQ_VIAGEM,DTQ->DTQ_CTRORI),'ZA7_CCGEFC')	, Nil },;//Centro de Custo GEFCO 
//		cCCZA7     := Posicione('ZA7',1,DTQ->(DTQ_FILORI+DTQ_SOT+DTQ_OBRA+DTQ_SEQVIA+DTQ_SEQCAR),'ZA7_CCGEFC')
		cCCZA7     := Posicione('ZA7',3, iif( empty(DTQ->DTQ_CTRORI), DTQ->DTQ_VIAGEM, DTQ->DTQ_CTRORI ),'ZA7_CCGEFC')
		aCamposSC5 :=  {{"C5_FILIAL"	, xFilial("SC5")	, Nil },;//Pedido Venda Base GEFCO N:100246
						{"C5_NUM"		, cNumSC5			, Nil },;
						{"C5_TIPO" 		, cTipo				, Nil },;//Tipo de Pedido Normal
						{"C5_CLIENTE"	, if( empty(DTC->DTC_CLIDEV) , _cCli  , DTC->DTC_CLIDEV )	, Nil },;//Cod Cliente
						{"C5_LOJACLI"	, if( empty(DTC->DTC_LOJDEV) , _cLoj  , DTC->DTC_LOJDEV )	, Nil },;//Loja Cliente 
						{"C5_CLIENT"	, _FrCli, Nil },;//Cod Cliente Entrega
						{"C5_LOJAENT"	, _FrLoj, Nil },;//Loja Cliente Entrega
						{"C5_XTIPONF"	, Iif(nTipoPed <> 2,"CTE","NFS"), Nil },;//Tipo de Documento						
						{"C5_TIPOCLI"	, Posicione('SA1',1,xFilial('SA1') + _cCli + _cLoj,'A1_TIPO'), Nil },;//Tipo de Cliente Frank Z Fuga DTC2
						{"C5_CONDPAG"	, cCondPag			, Nil },;//Condição de Pagamento //
						{"C5_CCUSTO"	, cCCZA7											, Nil },;//Centro de Custo GEFCO 
		   				{"C5_REFGEFC"	, Iif(ZA7->ZA7_TIPDES == "O","",ZA7->ZA7_REFGEF)	, Nil },;//Referencia GEFCO       
						{"C5_CTAPSA"    , ZA7->ZA7_CONTA									, Nil },;//Conta Contabil Cliente												
						{"C5_CCUSPSA"	, ZA7->ZA7_CCCLIE									, Nil },;//Cetro de Custo Cliente
						{"C5_TPDESP"	, ZA7->ZA7_TIPDES									, Nil },;//Tipo de Despesa
						{"C5_OIPSA"   	, ZA7->ZA7_OI										, Nil },;//Ordem Interna
						{"C5_DESC1"		, 0					, Nil },;
						{"C5_DESC2"		, 0					, Nil },;
						{"C5_DESC3"		, 0					, Nil },;
						{"C5_DESC4"		, 0					, Nil },;
						{"C5_TPFRETE"	, cTipoF			, Nil },;
						{"C5_VOLUME1"	, nQtdVol			, Nil },;
						{"C5_PESOL"		, nPeso				, Nil },;
						{"C5_PBRUTO"	, nPeso				, Nil },;
						{"C5_VEND1"     , cVendedor			, Nil },;
						{"C5_VIAGEM"    , DTQ->DTQ_VIAGEM	, Nil },;
						{"C5_XOBS"      , DTQ->DTQ_OBSCTR	, Nil },;
						{"C5_MENNOTA"   , _cTexto			, Nil },;
						{"C5_COMIS1"    , nComissao        	, Nil }} 

	EndIf

	If nTipoPed == 2 //Ped Servico
		_aItens := {}
		//aadd( _aItens, DTQ->DTQ_XFRETE )
		//_aItens[1] += DTQ->(DTQ_VRPEDA + DTQ_VROUTR + DTQ_VALADV)
		
		// Buscar da DT8            
		aadd( _aItens, 0 )

		For _nX := 1 to Len(_aCompo)
			_cDescr := ""
			dbSelectArea("DT8")
			dbOrderNickName("ITUPDT8001") // xviage+codpas
			dbSeek(DTQ->DTQ_VIAGEM+_aCompo[_nX][01])
			If !Eof() .and. DT8_VALTOT > 0
		    	_aItens[1] += DT8->DT8_VALPAS
			EndIF
		Next
		
	EndIF
	
	//Else
	//	If DTQ->DTQ_VRPEDA > 0 
	//	aadd( _aItens, DTQ->DTQ_VRPEDA )
	//	Endif
	//	If DTQ->DTQ_VROUTR > 0 
	//		aadd( _aItens, DTQ->DTQ_VROUTR )
	//	Endif
	//	If DTQ->DTQ_VALADV > 0 
	//		aadd( _aItens, DTQ->DTQ_VALADV )
	//	Endif
	//EndIf

	//if ! cTipo $ "N|C"                            
	//	_aItens := { DTQ->DTQ_VALICM }
	//endif

	/*
	_aItens
	1 - DTQ->DTQ_VIAGEM		= Código da viagem
	2 - DT8_FILORI			= Filial origem
	3 - DT8_CODPAS			= Codigo do componente. Ex: G0, G1, G2...
	4 - DT8->DT8_VALPAS     = Valor do componente. Ex: Vlr do frete R$ 1.000,00
	5 - DT8->DT8_CDRORI     = Codigo da origem da viagem
	6 - DT8->DT8_CDRDES     = Codigo do destino da viagem
	7 - DT8->DT8_VALIMP     = Valor do imposto
	8 - DT8->DT8_VALTOT     = Valor total (componente + imposto)
	9 - DT8->DT8_XTES       = TES associada
	10- _aCompo[_nX][01]    = Codigo do componente G0, G1...
	11- _aCompo[_nX][02]    = Codigo interno do sistema 000000, 000001
	12- _cDescr				= Descricao do componente (Frete Peso, Frete Valor, Pedagio...)
	13- DT3->DT3_XCODPR		= Codigo do produto associado
	*/
	
	
	For i := 1 to len( _aItens )

        aItens 		:= {}
		If nTipoPed == 1
	   		cProduto 	:= _aItens[i][13]     
	   		nValTot  	:= _aItens[i][4]
	   		cTes		:= _aItens[i][9]       
	   		                  
	   				    // Produto      CODPAS         VIAGEM        ITEM DA NOTA
	   		aadd(_aNotas,{_aItens[i][13],_aItens[i][3], _aItens[i][1]} )
	    Else
	   		cProduto 	:= GetMv("MV_CTRCPRO",,"999912")
	   		nValTot  	:= _aItens[i]      
	   		cTes		:= GetMV("LC_TESNFSE",,"511") //Incluído por Cauê Poltronieri em 04/03/2016
	    EndIf 
   		
	    AADD(aItens,{"C6_ITEM"		, StrZero(I,2)   		, Nil}) // Itens 
	   	AADD(aItens,{"C6_FILIAL"	, xFilial("SC6") 		, Nil}) // Filial 
		AADD(aItens,{"C6_NUM"		, cNumSC5		 		, Nil}) // Numero do Pedido
		AADD(aItens,{"C6_PRODUTO"	, cProduto		  		, Nil}) // Material
		AADD(aItens,{"C6_DESCRI"	, Posicione('SB1',1,xFilial('SB1')+cProduto,'B1_DESC'), Nil}) // Descrição do Material
		AADD(aItens,{"C6_UM"		, Posicione('SB1',1,xFilial('SB1')+cProduto,'B1_UM'), Nil}) // Unidade de medida  
		AADD(aItens,{"C6_QTDVEN"	, 1				 		, Nil}) // Quantidade
		AADD(aItens,{"C6_PRCVEN"	, nValTot 				, Nil}) // Preco de Venda / Valor Frete
		AADD(aItens,{"C6_VALOR"	    , nValTot			    , Nil}) // Valor total do item
		AADD(aItens,{"C6_TES"		, cTes					, Nil})//TES   
		AADD(aItens,{"C6_LOCAL"		, Posicione('SB1',1,xFilial('SB1')+cProduto,'B1_LOCPAD'), Nil}) // Armazem padrao        
		AADD(aItens,{"C6_QTDLIB"	, 0						, Nil}) // Quantidade liberada
		AADD(aItens,{"C6_DESCONT"	, 0              		, Nil}) // Percentual de Desconto	   
		AADD(aItens,{"C6_ENTREG"	, dDataBase		 		, Nil}) // Data da entrega
		AADD(aItens,{"C6_COMIS1"	, 0              		, Nil}) // Comissao Vendedor
		AADD(aItens,{"C6_PRUNIT"	, nValTot 				, Nil}) // Preco Unitário / Valor Frete
		AADD(aItens,{"C6_CLI"		, _cCli		, Nil}) // Cliente
		AADD(aItens,{"C6_LOJA"		, _cLoj		, Nil}) // Loja do Cliente

		Aadd(aCamposSC6,aItens)
		
		If DTQ->DTQ_TIPTRA == "3"
			aItens := {}
			AADD(aItens,{"C6_FILIAL"	, xFilial("SC6") 			, Nil}) // Filial 
			AADD(aItens,{"C6_NUM"		, cNumSC5		 	   		, Nil}) // Numero do Pedido
			AADD(aItens,{"C6_ITEM"		, StrZero(I+1,2)   	   		, Nil}) // Itens 
			AADD(aItens,{"C6_PRODUTO"	, ''		 	   			, Nil}) // Material
			AADD(aItens,{"C6_QTDVEN"	, 1				 			, Nil}) // Quantidade
			AADD(aItens,{"C6_PRCVEN"	, Round(DTQ->DTQ_AFRMM,2)	, Nil}) // Preco de Venda / Valor Frete
			AADD(aItens,{"C6_VALOR"	    , Round(DTQ->DTQ_AFRMM,2)	, Nil}) // Valor total do item
			AADD(aItens,{"C6_TES"		, DTQ->DTQ_TES2	 			, Nil}) // TES   
			AADD(aItens,{"C6_QTDEMP"	, Iif(cTipo="N",1,0)		, Nil}) // Quantidade liberada
			AADD(aItens,{"C6_LOCAL"		, "01"	         	   		, Nil}) // Armazem padrao
			AADD(aItens,{"C6_CLI"		, _cCli			, Nil}) // Cliente
			AADD(aItens,{"C6_ENTREG"	, dDataBase		 			, Nil}) // Data da entrega
			AADD(aItens,{"C6_DESCONT"	, 0              			, Nil}) // Percentual de Desconto
			AADD(aItens,{"C6_COMIS1"	, 0              			, Nil}) // Comissao Vendedor
			AADD(aItens,{"C6_LOJA"		, _cLoj			, Nil})  // Loja do Cliente
			AADD(aItens,{"C6_QTDLIB"	, Iif(cTipo="N",1,0)		, Nil}) // Quantidade liberada
			AADD(aItens,{"C6_PRUNIT"	, Round(DTQ->DTQ_AFRMM,2)	, Nil}) // Preco Unitário / Valor Frete
			AADD(aItens,{"C6_MUNOBRA"	, DTC->DTC_DESTIN			, Nil}) // Municipio da Obra 
			AADD(aItens,{"C6_XCLVL"		, DTQ->DTQ_AS		   		, Nil})  // Classe valor

			Aadd(aCamposSC6,aItens)
		EndIf                                      

		
		If cTipo $ "I|C"					// Complemento de ICMS ou Preço
			nRecDTQ  := DTQ->(Recno())
			cNfOri   := Posicione("DTQ",1,xFilial("DTQ") + cCTROri,"DTQ_NUMCTR")
			cSeriOri := Posicione("DTQ",1,xFilial("DTQ") + cCTROri,"DTQ_SERCTR")               
			DTQ->(dbGoTo(nRecDTQ))
			Aadd(aCamposSC6[i],{"C6_VALOR"		, nValTot	, Nil})	 // Valor Total
			Aadd(aCamposSC6[i],{"C6_NFORI"		, cNfOri	, Nil})	 // Valor Total
			Aadd(aCamposSC6[i],{"C6_SERIORI"	, cSeriOri	, Nil})	 // Valor Total 
		EndIf

	Next

Next

Begin Transaction

IF Len(aCamposSC5) > 0 .And. Len(aCamposSC6) > 0
	
	cOldReadVar := ReadVar()
	SetFunName("MATA410")       
	
	ZT0_UFORI := GetMV("MV_ESTADO") // forca a criacao da variavel por questao de error.log	

	MSExecAuto({|x,y,z| Mata410(x,y,z)},aCamposSC5,aCamposSC6,3)
	
	SetFunName( cOldReadVar )
	
	If lMsErroAuto
		MostraErro()
			   	
		RollBackSX8()
	Else
	
		RecLock("SC5",.F.)
		SC5->C5_CLIENTE	:=	If( empty(DTC->DTC_CLIDEV), _cCli , DTC->DTC_CLIDEV ) // Frank Z Fuga DTC2
		SC5->C5_LOJACLI	:=  If( empty(DTC->DTC_LOJDEV), _cLoj , DTC->DTC_LOJDEV ) // Frank Z Fuga DTC2
		SC5->C5_CLIENT	:=	Iif(!Empty(DTC->DTC_CLIREC),DTC->DTC_CLIREC,Iif( empty(DTC->DTC_CLIDES), _cCli , DTC->DTC_CLIDES ))// Frank Z Fuga DTC2
		SC5->C5_LOJAENT	:=  Iif(!Empty(DTC->DTC_LOJREC),DTC->DTC_LOJREC,Iif( empty(DTC->DTC_LOJDES), _cLoj , DTC->DTC_LOJDES ))// Frank Z Fuga DTC2
		SC5->(MsUnLock())
	
		SC6->(DBGoTop())
		SC6->(DbSeek(xFilial("SC6")+SC5->C5_NUM))
		While !Eof() .And. SC6->C6_FILIAL+SC6->C6_NUM == xFilial("SC6")+SC5->C5_NUM    
			RecLock("SC6",.F.)
			SC6->C6_QTDEMP	:=	0
			SC6->(MsUnLock())
			DbSkip()
		EndDo

	
	   ConfirmSX8()

		DbSelectArea("SC6")
		DbSetOrder(1)
		DbSeek(xFilial("SC6")+cNumSC5)
		While !Eof() .And. SC6->C6_FILIAL+SC6->C6_NUM == xFilial("SC6")+cNumSC5    
			MaLibDoFat(SC6->(Recno()),SC6->C6_QTDVEN,@lCredito,@lEstoque,lAvCred,lAvEst,lLiber,lTransf)
			DbSelectArea("SC6")
			DbSkip()
		EndDo
    
	 	If nTipoPed <> 2 // Se não for pedido de seviço.
			 LjMsgRun("Aguarde...Gerando Nota Fiscal CT-e...",,{|| IncNota(cNumSC5,cSerie,"",@aNotas)})
		
			IF Len(aNotas) > 0

			   //ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			   //³Gera os arquivos com as notas fiscais            ³
			   //ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			   cSerie 	:= aNotas[1][1]
			   cNota 	:= aNotas[1][2]

			   //----------------------- Ajustes solicitados pelo Anderson - Cristiam Rossi em 09/09/2015

			   aAreaSE1 := SE1->( getArea() )
			   SE1->( dbSetOrder(1) )	// E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO

			   aAreaSC5 := SC5->( getArea() )
			   SC5->( dbSetOrder(1) )	// F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA+F2_FORMUL+F2_TIPO
			   SC5->( dbSeek( xFilial("SC5") + cNumSC5, .T.) )

			   aAreaSF2 := SF2->( getArea() )
			   SF2->( dbSetOrder(1) )	// F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA+F2_FORMUL+F2_TIPO
			   if SF2->( dbSeek( xFilial("SF2") + cNota + cSerie, .T.) )
			       RecLock("SF2", .F.)
			       SF2->F2_VOLUME1 := SC5->C5_VOLUME1
			       SF2->F2_PLIQUI  := SC5->C5_PESOL
			       SF2->F2_PBRUTO  := SC5->C5_PBRUTO
			       MsUnlock()
			   endif
			   
				//_cPcCli  := SC5->C5_NUM
				// Alterado por Frank Zwarg Fuga em 11/08/2016
				_cPcCli     := ""	
				cQueryX 	:= "SELECT ZA6.ZA6_PEDCLI AS PEDCLI "
				cQueryX 	+= "FROM ZA6010 ZA6, ZA7010 ZA7, DTQ010 DTQ "
				cQueryX 	+= "WHERE ZA6.D_E_L_E_T_ = '' AND ZA7.D_E_L_E_T_ = '' AND DTQ.D_E_L_E_T_ = '' AND "
				cQueryX 	+= "ZA6.ZA6_PROJET = ZA7.ZA7_PROJET AND ZA6.ZA6_OBRA = ZA7.ZA7_OBRA AND	ZA6.ZA6_SEQTRA = ZA7.ZA7_SEQTRA AND "
				cQueryX 	+= "ZA7.ZA7_VIAGEM = DTQ.DTQ_VIAGEM AND "
				cQueryX 	+= "DTQ.DTQ_VIAGEM = '"+DTQ->DTQ_VIAGEM+"' "
				If Select("TRBX") > 0
					TRBX->(dbCloseArea())	 
				endif
				TCQUERY cQueryX NEW ALIAS "TRBX"              
				_cPcCli     :=  TRBX->PEDCLI
				TRBX->(dbCloseArea())

				_cFatCli := SF2->F2_DOC

			   SE1->( dbSeek( xFilial("SE1") + SF2->(F2_PREFIXO + F2_DUPL), .T. ) )
			   while ! SE1->( EOF() ) .and. SE1->(E1_FILIAL+E1_PREFIXO+E1_NUM)==xFilial("SE1")+SF2->(F2_PREFIXO + F2_DUPL)
			       if SE1->E1_TIPO == "NF "
						If RecLock("SE1", .F.)
							SE1->E1_FILDEB := cFilAnt
							SE1->E1_CCONT  := cCCZA7
							If Empty(StrTran(Alltrim(GetMv("IT_RPJFIAT")),".","")) .or.;
							   Substr(Alltrim(Posicione("SA1",1,xFilial("SA1") + SF2->F2_CLIENTE+SF2->F2_LOJA, "A1_CGC")),1,8) $ StrTran(Alltrim(GetMv("IT_RPJFIAT")),".","")
								SE1->E1_XPCCLI  := _cPcCli
								SE1->E1_PLANID  := _cPlanId
								SE1->E1_NUMAST  := _cNumAst
								SE1->E1_XFATCLI := _cFatCli
								SE1->E1_DATAAST := _dDatAst
							EndIf
							SE1->(MsUnlock())
						EndIf
					EndIf
			       SE1->( dbSkip() )
			   end
			
			   SF2->( restArea( aAreaSF2 ) )
			   SC5->( restArea( aAreaSC5 ) )
			   SE1->( restArea( aAreaSE1 ) ) 
			   	
			   //-----------------------

		       aAreaDTC:=DTC->(GetArea())
		       Dbselectarea("DTC")
			   
			   //Incluido Condicao para que seja gravado em todos os itens da NF da tabela DTC.
		       DbOrderNickname('DTCIND09')
		       DbSeek(xFilial("DTC")+cViagem)
			   //DbGoto(aDTC[1])
			        
			   While DTC->(!Eof()) .and. DTC->DTC_VIAGEM == cViagem
					Reclock("DTC",.F.)         
					DTC->DTC_FILDOC := cFilant
				    DTC->DTC_DOC    := cNota
				    DTC->DTC_SERIE  := cSerie
					MsUnlock()          
					DTC->(DBSKIP())
			   Enddo     
			    
			   dbGoto(aDTC[1]) 
			   RestArea(aAreaDTC)
			   aAreaDTQ := DTQ->(GetArea())
			   
			   DbSelectArea("DTQ")
		       DbSetOrder(1)
			   DbGoto(nRegDTQ)
			   
			   Reclock("DTQ",.F.)         
			     DTQ->DTQ_NUMPV     := cNumSC5
			     DTQ->DTQ_NUMCTR    := cNota
			     DTQ->DTQ_SERCTR	:= cSerie
			     DTQ->DTQ_XLEGEN	:= "C"
			   MsUnlock()
			   
			   dbSelectArea("ZUC")
			   dbSetOrder(4)	// FILIAL+VIAGEM
			   dbSeek( xFilial("ZUC") + DTQ->DTQ_VIAGEM )
		       While !Eof() .and. ZUC_FILIAL+ZUC_VIAGEM == xFilial("ZUC")+DTQ->DTQ_VIAGEM 		
		       		RecLock("ZUC", .F.)
               		ZUC->ZUC_NUMCTR := cNota
               		ZUC->ZUC_SERCTR := cSerie
		       		MsUnlock()
		       		dbSkip()
		       EndDo
		       
	       	   If nTipoPed == 1                                               
	       	       	// -------------------------------------------------------
	       	   		// Atualizar a tabela DT8 com a numeracao dos itens da SD2
	       	   		// -------------------------------------------------------
					dbSelectARea("SD2")
					dbSetOrder(8)
					dbSeek(xFilial("SD2")+cNumSC5)
					While D2_FILIAL+D2_PEDIDO == xFilial("SD2")+cNumSC5
						For _nX:=1 to Len(_aNotas)
							If _aNotas[_nX][1] == D2_COD
								dbSelectArea("DT8")
								dbOrderNickName("ITUPDT8001") // xviage+codpas
								dbSeek(DTQ->DTQ_VIAGEM+_aNotas[_nX][2])
								If !Eof()
									RecLock("DT8",.F.)
									DT8->DT8_ITEMD2 := SD2->D2_ITEM
									DT8->DT8_FILDOC := cFilant
									DT8->DT8_DOC    := cNota
									DT8->DT8_SERIE  := cSerie
									MsUnlock()
									Exit
								EndIF
							EndIF
						Next        
						dbSelectARea("SD2")
						dbSkip()
					EndDo							    
	   		   EndIF

		       
		       RestArea(aAreaDTQ)

		       AcertoICMS(cNota,cSerie,cTipo)	

		       MsgAlert("Foi gerada a Nota Fiscal CT-e de numero "+ cNota)

		    Endif                                                         
		Else                                                          
		   
			DbSelectArea("DTQ")
			Reclock("DTQ",.F.)         
			DTQ->DTQ_NUMPV  := cNumSC5 
			DTQ->DTQ_NUMCTR := "X"       
			DTQ->DTQ_XLEGEN	:= "D" 
			MsUnlock()
			MsgAlert("Foi gerado Pedido de Serviço numero "+ cNumSC5)
	  	EndIf
 
	EndIF
 
Endif

End Transaction 
	If (GetMv("MV_NUMITEN",.T.))
   		SX6->(MSUNLOCK())
	EndIf

Return .T.


//--------------------- baca, correção numero da AS
User Function XASCER
Local cQuery
Local aArea := getArea()

	cQuery	:=	"UPDATE "+RetSqlName("ZA6")+" SET ZA6_AS = SUBSTRING(ZA6_AS,1,7)+ZA6_OBRA+SUBSTRING(ZA6_AS,11,5) FROM "+RetSqlName("ZA6")+" WHERE ZA6_OBRA > "+"'999'"+" "   
	TCSQLEXEC(cQuery)

	cQuery	:=	"UPDATE "+RetSqlName("ZA7")+" SET ZA7_AS = SUBSTRING(ZA7_AS,1,7)+ZA7_OBRA+SUBSTRING(ZA7_AS,11,5) FROM "+RetSqlName("ZA7")+" WHERE ZA7_OBRA > "+"'999'"+" "    
	TCSQLEXEC(cQuery)

	cQuery	:=	"UPDATE "+RetSqlName("DTQ")+" SET DTQ_AS = SUBSTRING(DTQ_AS,1,7)+DTQ_OBRA+SUBSTRING(DTQ_AS,11,5) FROM "+RetSqlName("DTQ")+" WHERE DTQ_OBRA > "+"'999'"+" "
	TCSQLEXEC(cQuery)
    
	cQuery	:=	"UPDATE "+RetSqlName("ZUC")+" SET ZUC_AS = DTQ_AS FROM "+RetSqlName("ZUC")+" INNER JOIN "+RetSqlName("DTQ")+" ON ZUC_VIAGEM = DTQ_VIAGEM WHERE DTQ_OBRA > "+"'999'"+" "
	TCSQLEXEC(cQuery)

	restArea( aArea )
	
	alert(" OK ")
return nil




/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³AtuDT8L   ºAutor  ³Frank Zwarg Fuga    º Data ³  04/08/16   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³No momento da geracao da nota, atualizo DT8, DTQ e ZA7      º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ AP                                                        º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Static Function AtuDT8L()
Local   _nBaseAD    := 0
Local   nAliqAdv    := DTQ->DTQ_PERADV
Local   aAreaDTC    := DTC->( getArea() )
Local   _nPGride    := 0

Private _n00Base    := _n01Base:=_n02Base:=_n03Base:=_n04Base:=0
Private _n00Aliq    := _n01Aliq:=_n02Aliq:=_n03Aliq:=_n04Aliq:=0
Private _n00VlrI    := _n01VlrI:=_n02VlrI:=_n03VlrI:=_n04VlrI:=0
Private nFreteT     := 0
Private _aCampos    := {}
Private _nBaseICMS  := 0
Private _nAliqICMS  := 0	
Private _nValorICMS := 0

Private _nFrete  := DTQ->DTQ_XFRETE
Private _nImpFre := 0	// DTQ->DTQ_VALICM
Private _nFreteP := 0	// DTQ->DTQ_TOTFRE

Private _nAdvAlo := 0	// DTQ->DTQ_VALADV
Private _nImpAdv := 0
Private _nFreVlr := 0	// DTQ->DTQ_VALADV

Private _nPedagi := DTQ->DTQ_VRPEDA
Private _nImpPed := 0
Private _nTotPed := 0	// DTQ->DTQ_VRPEDA

Private _nOutros := DTQ->DTQ_VROUTR
Private _nImpOut := 0
Private _nTotOut := 0	// DTQ->DTQ_VROUTR

Private _nGris	 := 0

// Atualiza o valor advalorem
	DTC->( dbOrderNickName("DTCIND09") )
	DTC->( dbSeek( xFilial("DTC") + DTQ->DTQ_VIAGEM ) )
	while ! DTC->( EOF() ) .and. DTC->DTC_VIAGEM == DTQ->DTQ_VIAGEM
		_nBaseAD += DTC->DTC_VALOR
		DTC->( dbSkip() )
	End

	DTC->( restArea( aAreaDTC ) )

	If _nBaseAD > 0
	    _nAdvAlo := (_nBaseAD * nAliqAdv) / 100
	EndIf

	ZA0->( dbSetOrder(1) )
	ZA0->( dbSeek( xFilial("ZA0") + DTQ->DTQ_SOT ) )

	ZA6->( dbSetOrder(1) )
	ZA6->( dbSeek( Right( alltrim( DTQ->DTQ_AS ) , 2) + DTQ->DTQ_SOT + DTQ->DTQ_OBRA ) )

	ZT0->( dbSetOrder(1) )	// filial+codtab+vertab+codcli+lojcli+tiptab+itemtb
	ZT0->( dbSeek( xFilial("ZT0") + ZA6->ZA6_TABVEN + ZA6->ZA6_VERVEN + ZA0->ZA0_CLI + ZA0->ZA0_LOJA + ZA6->ZA6_TPTRAN + ZA6->ZA6_ITTABV , .T. ) )
	If ZT0->(!eof())
		_nPGride := ZT0->ZT0_PGRIS 
	EndIF

	If _nBaseAD > 0
	    _nGris := (_nBaseAD * _nPGride) / 100
	EndIf


// --------- Variaveis para o funcionamento do Tget dinamico - Frank Z Fuga --------------
	dbSelectArea("SX5")
	dbSetOrder(1)
	dbSeek(xFilial("SX5")+"_C000000")       
	_nX := 0
	While !eof() .and. X5_TABELA == "_C"
		_nX ++   
		&("cVar"+alltrim(str(_nX)))  := 0

		If _nX == 1 // Representa o componente dinamico do gride
			&("_nCpa"+alltrim(str(_nX))) := _nGris
		Else                                 
			&("_nCpa"+alltrim(str(_nX))) := 0
		EndIF

		&("_nCpb"+alltrim(str(_nX))) := 0
		&("_nCpc"+alltrim(str(_nX))) := 0
		dbSkip()
	EndDo

	dbSelectArea("SX5")
	dbSetOrder(1)
	dbSeek(xFilial("SX5")+"_C000003")       
	dbSkip()
	// Habilitar os componentes dinamicos somente para o caso de não ser um complemento.
	While !eof() .and. X5_TABELA == "_C" .and. empty(DTQ->DTQ_CTRORI) 
		dbSelectARea("DT3")
		dbSetOrder(1)
		dbSeek(xFilial("DT3")+substr(SX5->X5_DESCRI,1,2))
		If Eof()
			_cDescr := "DT3-EOF"
		Else
			_cDescr := alltrim(DT3->DT3_DESCRI)
		EndIF
		dbSelectArea("SX5")

		aadd(_aCampos, {_cDescr, X5_CHAVE, substr(X5_DESCRI,1,2 ) }  )
		dbSkip()
	EndDo
// ---------------------------------------------------------------------------------------

	U_VALOUTX( .F. )	// Cálculo e atribuição das variáveis Private
	
	u_AtuDT8()		// atualiza DT8 e ZA7
        

Return nil


Static Function MyError( oError )
	BREAK          
Return( NIL )
