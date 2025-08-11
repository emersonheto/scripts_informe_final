USE [BDUCCI]
GO
/* ===================================================================================================================
NOMBRE      : Grant BDINTBANNER SPs
FECHA       : 03/06/2025
AUTOR       : Brus Paucar (WAYTECH)
OBJETIVO    : Asignar los grants requeridos
================================================================================================================== */
BEGIN
    SET FMTONLY OFF
    BEGIN TRY
        BEGIN TRANSACTION  
            -- Otorgar permisos para los procedimientos almacenados
            GRANT EXECUTE ON [pgpt].[sp_ListSendingDocumentsByIdDocumentoFinalReportAp] TO [ssapplinux];
            GRANT EXECUTE ON [pgpt].[sp_SelInformeFinalByCodigo_UC] TO [ssapplinux];
        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        --THROW;
        --INSTRUCCIONES EN CASO DE ERRORES
        DECLARE @ErrorMessage NVARCHAR(4000);  
        DECLARE @ErrorSeverity INT;  
        DECLARE @ErrorState INT;  

        SELECT   
            @ErrorMessage = ERROR_MESSAGE(),  
            @ErrorSeverity = ERROR_SEVERITY(),  
            @ErrorState = ERROR_STATE();  

        RAISERROR (
            @ErrorMessage, -- Message text.  
            @ErrorSeverity, -- Severity.  
            @ErrorState -- State.  
            );  
        ROLLBACK TRANSACTION
    END CATCH
END;
