USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [dbo].[sp_NotaAlumnoRecuperadoInfFinalReportAp]
FECHA	: 03/06/2025
AUTOR	: Alvaro Laveriano (Waytech)
OBJETIVO: Lista las notas de los alumnos recuperados
====================================================================================================*/

CREATE PROCEDURE [dbo].[sp_NotaAlumnoRecuperadoInfFinalReportAp]
(
	 @ProgramCode VARCHAR(3),
	 @TipoReporte INT,
	 @IdDocumentoFinalReportAp VARCHAR(15)
)
AS 
SET NOCOUNT ON
BEGIN
	BEGIN TRY
		SELECT 
				STR(ROW_NUMBER() OVER(PARTITION BY Codigo,Apellidos_Nombres ORDER BY Codigo,Apellidos_Nombres,No)) AS No,
				Codigo ,
				Apellidos_Nombres ,
				ISNULL(Seccion_Origen,'') AS Seccion_Antigua,
				Curso ,
				Nota ,
				Estado_Recuperacion
			FROM [dbo].[tblInfFinalConsolidadoNotasEstudiantesRecuperados] 
			WHERE Programa_Codigo = @ProgramCode
				AND Tipo_Reporte = @TipoReporte 
				AND IdDocumentoFinalReportAp = @IdDocumentoFinalReportAp
			ORDER BY Codigo,Apellidos_Nombres

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

