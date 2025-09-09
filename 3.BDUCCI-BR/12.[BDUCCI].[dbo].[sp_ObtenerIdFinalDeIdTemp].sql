
USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [dbo].[sp_ObtenerIdFinalDeIdTemp]
FECHA	: 03/06/2025
AUTOR	: Brus Paucar (Waytech)
OBJETIVO: Lista los datos generales del Informe solo con el IdDocumentoFinalReportAp
====================================================================================================*/
CREATE PROCEDURE [dbo].[sp_ObtenerIdFinalDeIdTemp]
    @IdDocumentoFinalReportApTMP VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT 
            IdDocumentoFinalReportAp AS 'IdDocumentoFinalReportAp'
        FROM 
            [dbo].[tblDocumentoFinalReportAp]
        WHERE 
            IdDocumentoFinalReportApTMP = @IdDocumentoFinalReportApTMP;

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