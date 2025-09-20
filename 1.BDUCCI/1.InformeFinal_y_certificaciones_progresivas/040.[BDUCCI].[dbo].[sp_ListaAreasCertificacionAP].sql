USE [BDUCCI]
GO
/*====================================================================================================
NOMBRE	: dbo.sp_ListaAreasCertificacionAp
FECHA	: 03/06/2025
AUTOR	: Saul Muñoz (SOLMIT)
OBJETIVO: Muestra la programacion de horarios de los docentes de la sección y certificación, para la aplicación Informe Final

MODIFICACIONES:
NRO		    FECHA		USUARIO					    MODIFICACIÓN
1           17/09/2025  Emerson Herrera(Waytech)	Se agrega funcionalidad para verificar el último intento y solo se tome en cuenta el id del codigo de reporte de informe final
====================================================================================================*/
ALTER PROCEDURE [dbo].[sp_ListaAreasCertificacionAp] 
(
	 @studentCode VARCHAR(12),
	 @Programa VARCHAR(200)
)
AS
SET NOCOUNT ON
BEGIN
	BEGIN TRY
	   DECLARE  @BDOracle VARCHAR(10)='BANNER';

       CREATE TABLE #RESULTADO ( 
       Area VARCHAR(20)
       )

	   DECLARE @QUERY NVARCHAR(MAX) = '
       SELECT AREA_CODE 
		   FROM OPENQUERY ('+@BDOracle+',''
			  SELECT DISTINCT B.AREA_CODE 
				  FROM BANINST1.SZVALDI A
					INNER JOIN SATURN.SMRALIB C 
					ON C.SMRALIB_AREA=A.AREA_CODE
				  INNER JOIN BANINST1.SZVMALLA B 
					  ON B.PROGRAM=A.PROGRAM_CODE 
					  AND B.TERM_CODE_EFF=A.VERSION_PLAN 
					  AND B.KEY_RULE=A.ASIGNATURA 
					  AND B.AREA_CODE=A.AREA_CODE 
					  AND SUBSTR(B.AREA_CODE,4,1)=''''C''''
				  WHERE A.DNI=''''' + @studentCode + '''''
					  AND C.SMRALIB_DESCRIPTION=''''' + @Programa + '''''
          ''
          )
          '
       INSERT INTO #RESULTADO
       EXEC (@QUERY)

       SELECT 
			 Area
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