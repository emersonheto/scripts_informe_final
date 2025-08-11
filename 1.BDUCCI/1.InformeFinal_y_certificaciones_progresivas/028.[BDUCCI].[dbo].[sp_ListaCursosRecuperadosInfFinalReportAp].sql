USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [dbo].[sp_ListaCursosRecuperadosInfFinalReportAp]
FECHA	: 03/06/2025
AUTOR	: Alvaro Laveriano (Waytech)
OBJETIVO: Reporte que lista los cursos recuperados
====================================================================================================*/

CREATE PROCEDURE [dbo].[sp_ListaCursosRecuperadosInfFinalReportAp] 
(	
	@ProgramCode VARCHAR(3),
	@TipoReporte INT,
	@IdDocumentoFinalReportAp VARCHAR(15)
)
AS
SET NOCOUNT ON
BEGIN
	BEGIN TRY
		SELECT Curso 
			FROM [dbo].[tblInfFinalConsolidadoNotasEstudiantesRecuperadosCursos]
			WHERE  Programa_Codigo = @ProgramCode			
				AND Tipo_Reporte = @TipoReporte
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