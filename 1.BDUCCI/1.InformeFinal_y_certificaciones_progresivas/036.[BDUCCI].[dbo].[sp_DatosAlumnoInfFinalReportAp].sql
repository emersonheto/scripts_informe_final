USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [dbo].[sp_DatosAlumnoInfFinalReportAp]
FECHA	: 03/06/2025
AUTOR	: Alvaro Laveriano (Waytech)
OBJETIVO: Lista los alumnos matriculados para el archivo
====================================================================================================*/

CREATE PROCEDURE [dbo].[sp_DatosAlumnoInfFinalReportAp] 
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
		
		SELECT No,Codigo,Apellidos_Nombres,Telefono,Correo_Continental,Correo_Personal  
			FROM [dbo].[tblInfFinalDatosdelosEstudiantes]
			WHERE Programa_Codigo = @ProgramCode
				AND Tipo_Reporte=@TipoReporte 
				AND UPPER(ISNULL(Area,'')) = (CASE @TipoReporte WHEN 5 THEN UPPER(@Area) ELSE UPPER(ISNULL(Area,'')) END )
				AND IdDocumentoFinalReportAp = @IdDocumentoFinalReportAp 
			ORDER BY No
		;
 
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

