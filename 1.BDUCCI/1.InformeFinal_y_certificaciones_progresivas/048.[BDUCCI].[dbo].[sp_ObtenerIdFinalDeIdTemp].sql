
USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [dbo].[sp_ObtenerIdFinalDeIdTemp]
FECHA	: 17/09/2025
AUTOR	: Brus Paucar (Waytech)
OBJETIVO: Obtiene el id: IdDocumentoFinalReportAp a partir del IdDocumentoFinalReportApTMP
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