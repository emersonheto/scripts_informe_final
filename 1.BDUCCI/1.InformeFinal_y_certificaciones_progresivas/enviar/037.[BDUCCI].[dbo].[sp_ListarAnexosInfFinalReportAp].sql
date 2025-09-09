USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [dbo].[sp_ListarAnexosInfFinalReportAp]
FECHA	: 03/06/2025
AUTOR	: Alvaro Laveriano (Waytech)
OBJETIVO: Lista los archivos anexos

NRO		    FECHA		USUARIO					    MODIFICACIÓN
1           08/09/2025  Emerson Herrera(Waytech)	Se agrega funcionalidad para verificar el último intento y solo se tome en cuenta el id del codigo de reporte de informe final
====================================================================================================*/

ALTER PROCEDURE [dbo].[sp_ListarAnexosInfFinalReportAp] 
(
	@IdDocumentoFinalReportAp VARCHAR(15)
)
AS 
SET NOCOUNT ON
BEGIN
	BEGIN TRY
       SELECT --[Seccion] AS 'sSeccion', --para los tipos 4 y 5, sección es NULL
	          [Orden] AS 'nOrden',
			  [Archivo] AS 'sNameFile',
			  [Fecha] AS 'sFecha',
	          Tipo_Reporte AS 'nTipo', 
			  Area AS 'sArea'
		   FROM [dbo].[tblInfFinalAnexos]
		   WHERE [IdDocumentoFinalReportAp]=@IdDocumentoFinalReportAp
			--    AND Tipo_Reporte=@TipoReporte
			--    AND UPPER(ISNULL(Area,'')) = (CASE @TipoReporte WHEN 5 THEN upper(@Area) ELSE UPPER(ISNULL(Area,'')) END)
		   ORDER BY [Orden]
	END TRY
	BEGIN CATCH
		DECLARE	@ErrorMessage VARCHAR(4000),
				@ErrorSeverity INT,
				@ErrorState INT;
		SELECT	@ErrorMessage =ERROR_MESSAGE(),
				@ErrorSeverity=ERROR_SEVERITY(),
				@ErrorState=ERROR_STATE();
				RAISERROR(@ErrorMessage,@ErrorSeverity,@ErrorState);
	END CATCH
END









