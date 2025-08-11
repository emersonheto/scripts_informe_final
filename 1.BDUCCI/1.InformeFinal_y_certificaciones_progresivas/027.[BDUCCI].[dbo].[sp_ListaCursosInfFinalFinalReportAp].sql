USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [dbo].[sp_ListaCursosInfFinalFinalReportAp]
FECHA	: 03/06/2025
AUTOR	: Alvaro Laveriano (Waytech)
OBJETIVO: Report que lista los cursos
====================================================================================================*/

CREATE PROCEDURE [dbo].[sp_ListaCursosInfFinalFinalReportAp] 
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
		SELECT Curso 
			FROM [dbo].[tblInfFinalResultadoNotasParticipantesCursos]
			WHERE Programa_Codigo = @ProgramCode								
				AND Tipo_Reporte = @TipoReporte 
				AND UPPER(ISNULL(Area,'')) = (CASE @TipoReporte WHEN 5 THEN UPPER(@Area) ELSE UPPER(ISNULL(Area,'')) END)
				AND IdDocumentoFinalReportAp = @IdDocumentoFinalReportAp 
			ORDER BY Curso;
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