USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [dbo].[sp_ResultadoParticipantesInfFinalReportAp]
FECHA	: 03/06/2025
AUTOR	: Alvaro Laveriano (Waytech)
OBJETIVO: Genera el resumen por estado de alumno para el archivo
====================================================================================================*/

CREATE PROCEDURE [dbo].[sp_ResultadoParticipantesInfFinalReportAp]
	@ProgramCode VARCHAR(3),
	@TipoReporte INT,
	@Area VARCHAR(20),
	@IdDocumentoFinalReportAp VARCHAR(15)
AS
SET NOCOUNT ON
BEGIN
	BEGIN TRY
	
	CREATE TABLE #RESULTADO ( 
		Tipo VARCHAR(100),
		Cantidad_Alumnos INT
	)
	
	INSERT INTO #RESULTADO
	SELECT Estado  AS 'Estado', 
	       Nro_Estudiantes AS No_estudiantes
		FROM [dbo].[tblInfFinalResultadoParticipantes2FinalReportAp]
		WHERE Programa_Codigo = @ProgramCode
			AND Tipo_Reporte= @TipoReporte 
			AND UPPER(ISNULL(Area,'')) = (CASE @TipoReporte  WHEN 5 THEN UPPER(@Area) ELSE UPPER(ISNULL(Area,'')) END )
			AND IdDocumentoFinalReportAp = @IdDocumentoFinalReportAp 
	SELECT 
			CONVERT(INT,0) AS 'No',
			Tipo  AS 'Estado',
			CONVERT(INT,Cantidad_Alumnos) AS 'No_estudiantes'
		FROM #RESULTADO 
		ORDER BY Tipo

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


