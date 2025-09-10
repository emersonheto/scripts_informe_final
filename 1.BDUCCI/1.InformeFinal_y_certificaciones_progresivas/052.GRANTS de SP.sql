USE [BDUCCI]
GO
/* ===================================================================================================================
NOMBRE      : Grant BDINTBANNER SPs
FECHA       : 09/09/2025
AUTOR       : Brus Paucar (WAYTECH)
OBJETIVO    : Asignar los grants requeridos
================================================================================================================== */
BEGIN
    SET FMTONLY OFF
    BEGIN TRY
        BEGIN TRANSACTION  
            -- Otorgar permisos para los procedimientos almacenados
            GRANT EXECUTE ON [dbo].[sp_MemorandoRecuperadoFinalReportAp] TO [ssapplinux];  
            GRANT EXECUTE ON [dbo].[sp_GetAllPrograms] TO [ssapplinux];
            GRANT EXECUTE ON [BANNER].[sp_AddInfFinalMemorandoRecuperadoFinalReportAp] TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_MemoRecuperadoCabeceraFinalReportAp] TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_MemorandoRecuperadoAsignaturaFRAp] TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_CursoMemoFinalReportAp] TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_IdFinalReportAp] TO [ssapplinux];
            GRANT EXECUTE ON [BANNER].[SP_AddInfFinalSeccionCertificarAPFinalReport] TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_DatosInfFinalReport] TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_ObtenerIdFinalDeIdTemp] TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_MemoRecuperadoCabecera] TO [ssapplinux];
            GRANT EXECUTE ON [BANNER].[sp_AddInfFinalNotaAlumnoRecuperadoCursosFinalReportAp] TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_CertificacionProgramaRecuperadosInfFinalAP] TO [ssapplinux];
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
