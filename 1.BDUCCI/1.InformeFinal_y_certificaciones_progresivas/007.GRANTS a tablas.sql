USE [BDUCCI]
GO
/* ===================================================================================================================
NOMBRE      : Grant BDUCCI tablas creadas
FECHA       : 03/06/2025
AUTOR       : Brus Paucar (WAYTECH)
OBJETIVO    : Asignar los grants requeridos
================================================================================================================== */
BEGIN
    SET FMTONLY OFF
    BEGIN TRY
        BEGIN TRANSACTION
            -- Otorgar permisos para acceder a las tablas involucradas
            GRANT SELECT, INSERT, UPDATE ON [dbo].[tblCodigoInformeFinal] TO [ssapplinux];
            GRANT SELECT, INSERT, UPDATE ON [dbo].[tblDocumentoFinalReportAp] TO [ssapplinux];
            GRANT SELECT, INSERT, UPDATE ON [dbo].[tblInfFinalResultadoParticipantes1FinalReportAp] TO [ssapplinux];
            GRANT SELECT, INSERT, UPDATE ON [dbo].[tblInfFinalResultadoParticipantes2FinalReportAp] TO [ssapplinux]; 
        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
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
