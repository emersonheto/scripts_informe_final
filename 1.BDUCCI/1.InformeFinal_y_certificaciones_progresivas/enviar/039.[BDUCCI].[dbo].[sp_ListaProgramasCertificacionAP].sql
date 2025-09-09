USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [dbo].[sp_ListaProgramasCertificacionAP]
FECHA	: 03/06/2025
AUTOR	: Alvaro Laveriano (Waytech)
OBJETIVO: Muestra la programacion de horarios de los docentes de la certificación

MODIFICACIONES:
NRO		    FECHA		USUARIO					    MODIFICACIÓN
1           08/09/2025  Emerson Herrera(Waytech)	Se agrega funcionalidad para verificar el último intento y solo se tome en cuenta el id del codigo de reporte de informe final
====================================================================================================*/

CREATE PROCEDURE [dbo].[sp_ListaProgramasCertificacionAP] 
(
	@studentCode VARCHAR(12),
    @programa VARCHAR(12)
)
AS 
SET NOCOUNT ON
BEGIN
	BEGIN TRY
	   DECLARE  @BDOracle VARCHAR(10)='BANNER'
   	   DECLARE @WHERE_CLAUSE NVARCHAR(1000) = ''

	   IF @studentCode IS NOT NULL
		SET @WHERE_CLAUSE += ' AND A.DNI=''''' + @studentCode +''''''
	   
	   IF @programa IS NOT NULL
	   	SET @WHERE_CLAUSE += ' AND A.PROGRAM_CODE=''''' + @programa +''''''
	   
       CREATE TABLE #RESULTADO ( 
		Programa VARCHAR(40)
       )

	   DECLARE @QUERY NVARCHAR(MAX) = '
       	SELECT AREA_DESC 
		FROM OPENQUERY ('+@BDOracle+',''
			SELECT DISTINCT NVL(C.SMRALIB_DESCRIPTION,B.AREA_DESC) AREA_DESC
			FROM BANINST1.SZVALDI A
			INNER JOIN SATURN.SMRALIB C 
			ON C.SMRALIB_AREA=A.AREA_CODE
			INNER JOIN BANINST1.SZVMALLA B 
				ON B.PROGRAM=A.PROGRAM_CODE 
				AND B.TERM_CODE_EFF=A.VERSION_PLAN 
				AND B.KEY_RULE=A.ASIGNATURA 
				AND B.AREA_CODE=A.AREA_CODE 
				AND SUBSTR(B.AREA_CODE,4,1)=''''C''''
				' + @WHERE_CLAUSE + '
		''
		)
		'
		   
       INSERT INTO #RESULTADO
       EXEC (@QUERY)

       SELECT 
			 Programa
		   FROM #RESULTADO 

       DROP TABLE #RESULTADO
	END TRY
	BEGIN CATCH
		DECLARE	@ErrorMessage VARCHAR(4000),
				@ErrorSeverity INT,
				@ErrorState INT;
		SELECT	@ErrorMessage =ERROR_MESSAGE(),
				@ErrorSeverity=ERROR_SEVERITY(),
				@ErrorState=ERROR_STATE();
				RAISERROR(@ErrorMessage,@ErrorSeverity,@ErrorState);
				SELECT @ErrorMessage AS status
	END CATCH
END