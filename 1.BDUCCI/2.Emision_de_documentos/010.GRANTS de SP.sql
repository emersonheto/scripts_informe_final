USE [BDUCCI]
GO
/* ===================================================================================================================
NOMBRE      : Grant BDINTBANNER SPs
FECHA       : 22/09/2025
AUTOR       : Brus Paucar (WAYTECH)
OBJETIVO    : Asignar los grants requeridos
================================================================================================================== */
BEGIN
    SET FMTONLY OFF
    BEGIN TRY
        BEGIN TRANSACTION  
            -- Otorgar permisos para los procedimientos almacenados
            -- Procedimientos principales del informe final
            GRANT EXECUTE ON [dbo].[sp_FinalReportAp] TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_ProgramacionEquipoDocenteFinalReportAp] TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_ResultadoTipoAlumnoFinalReportAp] TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_ResultadoEstadoAlumnoFinalReportAp] TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_ResultadoNotasParticipantesFinalReportAp] TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_ResultadoNotasParticipantesCursosFinalReportAp] TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_NotaAlumnoRecuperadoFinalReportAp] TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_NotaAlumnoRecuperadoCursosFinalReportAp] TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_ResultadoOrdenMeritoFinalReportAp] TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_CertificacionProgramaFinalReportAp] TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_DatosAlumnoFinalReportAp] TO [ssapplinux];

            -- Procedimientos adicionales
            GRANT EXECUTE ON [dbo].[sp_AddAnexosInfFinalAp] TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_GuardarDocumentoFinalReportAp] TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_ListaCursosInfFinalFinalReportAp] TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_ProgramacionDocenteInfFinalReportAp] TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_ResultadoNotasParticipantesInfFinalReportAp] TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_ResultadoOrdenMeritoInfFinalReportAp] TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_ListarAnexosInfFinalReportAp] TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_ListaProgramasCertificacionAp] TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_ListaAreasCertificacionAp] TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_SeccionCertificarCertificacionAp] TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_ProgramacionEquipoDocenteCertificacionAp] TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_ResultadoEstadoAlumnoCertificacionAp] TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_ResultadoNotasParticipantesCursosCertificacionAp] TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_ResultadoNotasParticipantesCertificacionAp] TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_CertificacionProgramaCertificacionAp] TO [ssapplinux];

            -- Procedimientos BANNER que se ejecutaron exitosamente
            GRANT EXECUTE ON [BANNER].[sp_AddInfFinalProgramacionDocenteFinalReportAp] TO [ssapplinux];
            GRANT EXECUTE ON [BANNER].[SP_AddInfFinalResultadoParticipantes1FinalReportAp] TO [ssapplinux];
            GRANT EXECUTE ON [BANNER].[sp_AddInfFinalResultadoParticipantes2FinalReportAp] TO [ssapplinux];
            GRANT EXECUTE ON [BANNER].[sp_AddInfFinalResultadoNotasParticipantesCursosFinalReportAp] TO [ssapplinux];
            GRANT EXECUTE ON [BANNER].[sp_AddInfFinalResultadoNotasParticipantesFinalReportAp] TO [ssapplinux];
            GRANT EXECUTE ON [BANNER].[sp_AddInfFinalNotaAlumnoRecuperadoFinalReportAp] TO [ssapplinux];
            GRANT EXECUTE ON [BANNER].[SP_AddInfFinalResultadoOrdenMeritoParticipantesFinalReportAp] TO [ssapplinux];
            GRANT EXECUTE ON [BANNER].[sp_AddInfFinalCertificacionProgramaFinalReportAp] TO [ssapplinux];
            GRANT EXECUTE ON [BANNER].[sp_AddInfFinalDatosAlumnoFinalReportAp] TO [ssapplinux];
            GRANT EXECUTE ON [BANNER].[sp_AddInfFinalSeccionCertificarAp] TO [ssapplinux];

            -- Procedimientos Emisi�n de documentos
            GRANT EXECUTE ON [pgpt].[sp_ListSendingDocumentsByIdDocumentoFinalReportAp] TO [ssapplinux];
            GRANT EXECUTE ON [pgpt].[sp_SelInformeFinalByCodigo_UC] TO [ssapplinux];
            GRANT EXECUTE ON [pgpt].[sp_EmiConstanciaIns_UC] TO [ssapplinux];
            GRANT EXECUTE ON [pgpt].[sp_generatedDocumentsCRUD] TO [ssapplinux];
            GRANT EXECUTE ON [pgpt].[sp_listHistorialSendingDocuments] TO [ssapplinux];
            GRANT EXECUTE ON [pgpt].[sp_EmiConstanciaUpd_UC] TO [ssapplinux];
            GRANT EXECUTE ON [pgpt].[sp_EmiConstanciaSel_UC] TO [ssapplinux];
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
