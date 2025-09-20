USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [dbo].[sp_DatosInfFinalReport]
FECHA	: 17/09/2025
AUTOR	: Brus Paucar (Waytech)
OBJETIVO: Lista los datos generales del Informe solo con el IdDocumentoFinalReportAp
====================================================================================================*/

CREATE PROCEDURE [dbo].[sp_DatosInfFinalReport] 
(	 
    @p_IdDocumentoFinalReportAp VARCHAR(50)
)
AS
SET NOCOUNT ON
BEGIN
	BEGIN TRY
	
		SET LANGUAGE Spanish

		SELECT 
			Seccion,
			ISNULL(Nombre_Programa,' ') AS  Nombre_Programa,
			ISNULL(Nombre_Sede,' ') AS  Nombre_Sede,
			ISNULL(Edicion,' ') AS Edicion,
			ISNULL(Ciclo,' ') AS Ciclo ,
			CONVERT(VARCHAR(20),DATENAME(MONTH,GETDATE())) Mes_Crea,
			CONVERT(VARCHAR(4),DATEPART(yy,GETDATE())) Anio_Crea,
			(DATENAME(DAY,Fecha_Inicio) + ' de '+ DATENAME(MONTH,Fecha_Inicio) + ' del ' + DATENAME(year,Fecha_Inicio)) AS Fecha_Inicio,
			(DATENAME(DAY,Fecha_Fin) + ' de '+ DATENAME(MONTH,Fecha_Fin) + ' del ' + DATENAME(year,Fecha_Fin)) AS Fecha_Fin,
			'' AS Empresa
		FROM [dbo].[tblInfFinalSeccionCertificar]
		WHERE IdDocumentoFinalReportAp = @p_IdDocumentoFinalReportAp
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