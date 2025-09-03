/*====================================================================================================
NOMBRE	: dbo.sp_ListaAreasCertificacionAP
FECHA	: 25/01/2024
AUTOR	: Saul Muñoz (SOLMIT)
OBJETIVO: Muestra la programacion de horarios de los docentes de la sección y certificación, para la aplicación Informe Final
MODIFICACIONES:
NRO					FECHA					USUARIO					MODIFICACION
====================================================================================================*/
ALTER PROCEDURE [dbo].[sp_ListaAreasCertificacionAP] 
(
	 @studentCode VARCHAR(12),
	 @Programa VARCHAR(200)
)
AS
SET NOCOUNT ON
BEGIN
	BEGIN TRY
	   DECLARE  @BDOracle VARCHAR(10)='DEVL';

       CREATE TABLE #RESULTADO ( 
       Area VARCHAR(20)
       )

	   DECLARE @QUERY NVARCHAR(MAX) = '
       SELECT AREA_CODE 
		   FROM OPENQUERY ('+@BDOracle+',''
			  SELECT DISTINCT B.AREA_CODE
				-- SELECT DISTINCT NVL(C.SMRALIB_DESCRIPTION,B.AREA_DESC) AREA_DESC
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