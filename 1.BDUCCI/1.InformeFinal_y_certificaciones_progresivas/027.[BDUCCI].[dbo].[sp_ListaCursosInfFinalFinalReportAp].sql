USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [dbo].[sp_ListaCursosInfFinalFinalReportAp]
FECHA	: 03/06/2025
AUTOR	: Alvaro Laveriano (Waytech)
OBJETIVO: Report que lista los cursos
NRO		    FECHA		USUARIO					    MODIFICACI�N
1           22/09/2025  Emerson Herrera(Waytech)	Se agrega funcionalidad para verificar el �ltimo intento y solo se tome en cuenta el id del codigo de reporte de informe final
====================================================================================================*/

ALTER PROCEDURE [dbo].[sp_ListaCursosInfFinalFinalReportAp] 
(
	@IdDocumentoFinalReportAp VARCHAR(50)
)
AS
SET NOCOUNT ON
BEGIN
	BEGIN TRY
		SELECT Curso 
			FROM [dbo].[tblInfFinalResultadoNotasParticipantesCursos]
			WHERE IdDocumentoFinalReportAp = @IdDocumentoFinalReportAp 
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