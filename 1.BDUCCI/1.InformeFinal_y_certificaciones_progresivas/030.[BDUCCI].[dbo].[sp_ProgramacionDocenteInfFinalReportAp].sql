USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [dbo].[sp_ProgramacionDocenteInfFinalReportAp]
FECHA	: 03/06/2025
AUTOR	: Alvaro Laveriano (Waytech)
OBJETIVO: Reporte de programacion de horarios de docentes
====================================================================================================*/

CREATE PROCEDURE [dbo].[sp_ProgramacionDocenteInfFinalReportAp] 
(
	 @ProgramCode VARCHAR(3),
	 @TipoReporte INT,
	 @Area VARCHAR(20),
	 @IdDocumentoFinalReportAp VARCHAR(15)
)
AS
SET NOCOUNT ON
BEGIN
	BEGIN TRY

  SELECT  Ciclo,Seccion,Asignaturas,Docente,Horas_Lectivas,Fecha_Inicio,Fecha_Fin
	  FROM [dbo].[tblInfFinalProgramacionDocente]
	  WHERE Programa_Codigo= @ProgramCode 
		  AND Tipo_Reporte = @TipoReporte 
		  AND UPPER(ISNULL(Area,''))= (CASE @TipoReporte WHEN 5 THEN UPPER(@Area) ELSE UPPER(ISNULL(Area,'')) END )
	  	  AND IdDocumentoFinalReportAp = @IdDocumentoFinalReportAp 
	  ORDER BY CICLO,Asignaturas

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