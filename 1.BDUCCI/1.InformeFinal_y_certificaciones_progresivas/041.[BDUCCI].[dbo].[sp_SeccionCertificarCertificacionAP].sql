USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [dbo].[sp_SeccionCertificarCertificacionAP]
FECHA	: 03/06/2025
AUTOR	: Emerson Herrera (Waytech)
OBJETIVO: Obtiene información necesaria para el archivo de informe final
====================================================================================================*/

CREATE PROCEDURE [dbo].[sp_SeccionCertificarCertificacionAP]
	@studentCode VARCHAR(12),
	@AreaCert VARCHAR(20)
AS
SET NOCOUNT ON
BEGIN
   BEGIN TRY
   DECLARE @QUERY2 NVARCHAR(2000) 
   DECLARE @TS_QUERY VARCHAR(MAX)
   DECLARE @BDOracle VARCHAR(10)='BANNER'

   SET @QUERY2= '
   SELECT DISTINCT STUDYPATH_BLOQUE AS Seccion,
		   (CASE WHEN SUBJ_CODE = ''''PSDP'''' THEN ''''DIPLOMAS''''
				 WHEN SUBJ_CODE = ''''PSEV'''' THEN ''''EVENTOS''''
				 WHEN SUBJ_CODE = ''''PSMA'''' THEN ''''MAESTRIA''''
				 WHEN SUBJ_CODE = ''''PSPA'''' THEN ''''PASANTIA''''
				 WHEN SUBJ_CODE = ''''PSPE'''' THEN ''''PROGRAMAS DE ESPECIALIZACION''''
				 WHEN SUBJ_CODE = ''''PSCC'''' THEN ''''CURSO CERRADO''''
				 WHEN SUBJ_CODE = ''''PSCU'''' THEN ''''CURSO''''
				 WHEN SUBJ_CODE = ''''PSDI'''' THEN ''''DIPLOMADO''''
				 WHEN SUBJ_CODE = ''''PSDO'''' THEN ''''DOCTORADO'''' END) AS TipoPrograma,
		   B.AREA_DESC AS Programa,
		   NOMBRE_CURSO AS Asignatura,
		   ESTADO_ASIGNATURA AS "EstadoAsignatura",
		   TERM_CTLG AS Periodo,
		   (CASE WHEN INSTR(DEPT_DESC,''''SEMI'''') > 0 THEN ''''SEMIPRESENCIAL''''
				 WHEN INSTR(DEPT_DESC,''''VIRTUAL'''') > 0 THEN ''''VIRTUAL''''
				 WHEN INSTR(DEPT_DESC,''''PRESENCIAL'''') > 0 THEN ''''PRESENCIAL''''
				 WHEN INSTR(DEPT_DESC,''''DISTANCIA'''') > 0 THEN ''''A DISTANCIA'''' END) AS Modalidad,
	       (CASE CAMP_CODE WHEN ''''F01'''' THEN ''''AREQUIPA''''
					       WHEN ''''F03'''' THEN ''''CUSCO''''
					       WHEN ''''S01'''' THEN ''''HUANCAYO''''
				 	       WHEN ''''F02'''' THEN ''''LIMA'''' END) AS SEDE,
			DNI AS "Codigo",
        	NOMBRE AS "ApellidosNombres",
        	PROGRAM_CODE AS "ProgramCode"
	   FROM BANINST1.SZVALDI A
	   INNER JOIN BANINST1.SZVMALLA B 
		   ON B.PROGRAM=A.PROGRAM_CODE 
		   AND B.TERM_CODE_EFF=A.VERSION_PLAN 
		   AND B.KEY_RULE=A.ASIGNATURA 
		   AND B.AREA_CODE='''''+@AreaCert+'''''
	   WHERE A.DNI=''''' + @studentCode +''''' 
   '

   SET @TS_QUERY= '
   SELECT Codigo, ApellidosNombres, ProgramCode, Seccion,TipoPrograma,Programa,Asignatura,Periodo,Modalidad,Sede, EstadoAsignatura
	   FROM OPENQUERY('+@BDOracle+','''+@QUERY2+''')';
 
   EXEC (@TS_QUERY)
END TRY
BEGIN CATCH
	SELECT 
     ERROR_NUMBER() AS ERROR_NUMBER,
     ERROR_MESSAGE() AS ERROR_MESSAGE
END CATCH
END