USE [BDUCCI]
GO
/* ===================================================================================================================
NOMBRE      : Grant BDUCCI tablas creadas
FECHA       : 09/09/2025
AUTOR       : Brus Paucar (WAYTECH)
OBJETIVO    : Asignar los grants requeridos
================================================================================================================== */
BEGIN
    SET FMTONLY OFF
    BEGIN TRY
        BEGIN TRANSACTION
            -- Otorgar permisos para acceder a las tablas involucradas
            GRANT SELECT, INSERT, UPDATE ON [dbo].[tblInfFinalMemorandumFinalReportAp] TO [ssapplinux];
            GRANT SELECT, INSERT, UPDATE ON [dbo].[tblDatosMemoFinalReportAp] TO [ssapplinux];
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
            @ErrorMessage,
            @ErrorSeverity,
            @ErrorState
            );  
        ROLLBACK TRANSACTION
    END CATCH
END;
