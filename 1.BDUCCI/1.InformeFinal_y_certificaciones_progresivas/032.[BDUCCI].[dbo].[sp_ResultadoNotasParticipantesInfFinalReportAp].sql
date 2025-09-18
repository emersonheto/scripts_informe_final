USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [dbo].[sp_ResultadoNotasParticipantesInfFinalReportAp]
FECHA	: 03/06/2025
AUTOR	: Alvaro Laveriano (Waytech)
OBJETIVO: Muestra los resultados de notas de los participantes en el archivo

NRO		    FECHA		USUARIO					    MODIFICACIÓN
1           17/09/2025  Emerson Herrera(Waytech)	Se agrega funcionalidad para verificar el último intento y solo se tome en cuenta el id del codigo de reporte de informe final
====================================================================================================*/

ALTER PROCEDURE [dbo].[sp_ResultadoNotasParticipantesInfFinalReportAp] 
(
	--@XmlStudents XML,
	@ProgramCode VARCHAR(3),
	@TipoReporte INT,
	@Area VARCHAR(20),
	@IdDocumentoFinalReportAp VARCHAR(15)
)
AS
SET NOCOUNT ON
BEGIN
	BEGIN TRY
		SELECT 
			CONVERT(VARCHAR(20),ROW_NUMBER() OVER (PARTITION BY Codigo,Apellidos_Nombres ORDER BY Codigo,Apellidos_Nombres,No))  AS 'No',  
			Codigo ,
			Apellidos_Nombres ,
			Curso ,
			Nota ,
			Promedio ,
			TipoAlumno AS Tipo_Alumno,
			Estado_Academico ,
			Estado_CAPP 
		FROM [dbo].[tblInfFinalResultadoNotasParticipantes] 
		WHERE 
			IdDocumentoFinalReportAp = @IdDocumentoFinalReportAp 
		ORDER BY Apellidos_Nombres,Codigo
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