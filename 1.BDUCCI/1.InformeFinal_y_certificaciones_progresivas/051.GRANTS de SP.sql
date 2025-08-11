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
            GRANT EXECUTE ON [dbo].[sp_FinalReportAP] TO [ssapplinux];  
            GRANT EXECUTE ON [dbo].[sp_GetAllPrograms] TO [ssapplinux];  
            GRANT EXECUTE ON [dbo].[sp_ProgramacionEquipoDocenteFinalReportAp] TO [ssapplinux];  
            GRANT EXECUTE ON [dbo].[sp_ResultadoEstadoAlumnoFinalReportAp] TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_ResultadoTipoAlumnoFinalReportAp] TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_ResultadoNotasParticipantesFinalReportAp] TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_ResultadoNotasParticipantesCursosFinalReportAp] TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_NotaAlumnoRecuperadoFinalReportAp] TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_NotaAlumnoRecuperadoCursosFinalReportAp] TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_ResultadoOrdenMeritoFinalReportAp] TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_CertificacionProgramaFinalReportAp] TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_DatosAlumnoFinalReportAp] TO [ssapplinux];
            GRANT EXECUTE ON [BANNER].[SP_AddInfFinalProgramacionDocenteFinalReportAp] TO [ssapplinux];
            GRANT EXECUTE ON [BANNER].[SP_AddInfFinalResultadoParticipantes1FinalReportAp] TO [ssapplinux];
            GRANT EXECUTE ON [BANNER].[sp_AddInfFinalResultadoParticipantes2FinalReportAp] TO [ssapplinux];
            GRANT EXECUTE ON [BANNER].[sp_AddInfFinalResultadoNotasParticipantesCursosFinalReportAp] TO [ssapplinux];
            GRANT EXECUTE ON [BANNER].[sp_AddInfFinalResultadoNotasParticipantesFinalReportAp] TO [ssapplinux];
            GRANT EXECUTE ON [BANNER].[sp_AddInfFinalNotaAlumnoRecuperadoFinalReportAp] TO [ssapplinux];
            GRANT EXECUTE ON [BANNER].[SP_AddInfFinalResultadoOrdenMeritoParticipantesFinalReportAp] TO [ssapplinux];
            GRANT EXECUTE ON [BANNER].[sp_AddInfFinalCertificacionProgramaFinalReportAp]  TO [ssapplinux];
            GRANT EXECUTE ON [BANNER].[sp_AddInfFinalDatosAlumnoFinalReportAp] TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_AddAnexosInfFinalAp] TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_GuardarDocumentoFinalReportAp] TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_ListaCursosInfFinalFinalReportAp]  TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_ListaCursosRecuperadosInfFinalReportAp]  TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_DatosInfFinalFinalReportAp]  TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_ProgramacionDocenteInfFinalReportAp]  TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_ResultadoParticipantesInfFinalReportAp] TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_ResultadoNotasParticipantesInfFinalReportAp]  TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_NotaAlumnoRecuperadoInfFinalReportAp] TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_ResultadoOrdenMeritoInfFinalReportAp] TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_CertificacionProgramaInfFinalReportAp] TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_DatosAlumnoInfFinalReportAp]  TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_ListarAnexosInfFinalReportAp]  TO [ssapplinux];
            GRANT EXECUTE ON [BANNER].[sp_AddInfFinalSeccionCertificarAP]  TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_ListaProgramasCertificacionAP]  TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_ListaAreasCertificacionAP]  TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_SeccionCertificarCertificacionAP] TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_ProgramacionEquipoDocenteCertificacionAP]  TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_ResultadoTipoAlumnoCertificacionAP] TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_ResultadoEstadoAlumnoCertificacionAP] TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_ResultadoNotasParticipantesCursosCertificacionAP] TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_ResultadoNotasParticipantesCertificacionAP] TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_CertificacionProgramaCertificacionAP] TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_DatosAlumnoCertificacionAP] TO [ssapplinux];
            GRANT EXECUTE ON [pgpt].[sp_generatedDocumentsCRUD] TO [ssapplinux];            
            GRANT EXECUTE ON [pgpt].[sp_EmiConstanciaIns_UC] TO [ssapplinux];
            GRANT EXECUTE ON [dbo].[sp_MemoRecuperadoCorrelativo] TO [ssapplinux];

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
