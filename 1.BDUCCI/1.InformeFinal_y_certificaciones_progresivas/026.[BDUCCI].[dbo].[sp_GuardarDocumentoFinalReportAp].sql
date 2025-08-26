USE [BDUCCI]
GO
/*====================================================================================================
NOMBRE	: [dbo].[sp_GuardarDocumentoFinalReportAp]
FECHA	: 03/06/2025
AUTOR	: Alvaro Laveriano (Waytech)
OBJETIVO: Almacenar los Datos Generales del Informe Final AP.
====================================================================================================*/

CREATE PROCEDURE [dbo].[sp_GuardarDocumentoFinalReportAp]
    @PathDocumento VARCHAR(255),
    @UsuarioCreacion VARCHAR(200),
    @ProgramCode VARCHAR(3),
    @TipoReporte INT,
    @p_IdDocumento VARCHAR(5)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION GuardarInfFinalAP
        
        DECLARE
        @IdDocumentoFinalReportAp VARCHAR(15),
        @IdDocumentoFinalReportApTMP VARCHAR(50)
        
        SET @IdDocumentoFinalReportAp = (
			SELECT CONCAT(IdAnio, IdInforme, IdDocumento, IdPrograma, IdSede, FORMAT(NroCorrelativo + 1, '000'))
			FROM [dbo].[tblCodigoInformeFinal]
			WHERE IdDocumento = @p_IdDocumento
			  AND IdPrograma = @ProgramCode
		)
		
		SET @IdDocumentoFinalReportApTMP = (
			SELECT CONCAT(IdAnio, IdInforme, IdDocumento, IdPrograma, IdSede, FORMAT(NroCorrelativo + 1, 'TMP000'), REPLACE(@UsuarioCreacion, ' ', ''))
			FROM [dbo].[tblCodigoInformeFinal]
			WHERE IdDocumento = @p_IdDocumento
			  AND IdPrograma = @ProgramCode
		)
		
		SET @PathDocumento = REPLACE(@PathDocumento, '[CODIGO]', @IdDocumentoFinalReportAp)

        INSERT INTO [dbo].[tblDocumentoFinalReportAp] (
            IdDocumentoFinalReportAp,
            PathDocumento,
            FechaRegistro,
            UsuarioCreacion,
            TipoReporte
        )
        VALUES (
            @IdDocumentoFinalReportAp,
            @PathDocumento,
            GETDATE(),
            @UsuarioCreacion,
            @TipoReporte
        )
        
        UPDATE [tblInfFinalProgramacionDocente] SET IdDocumentoFinalReportAp = @IdDocumentoFinalReportAp WHERE IdDocumentoFinalReportAp = @IdDocumentoFinalReportApTMP
		UPDATE [tblInfFinalResultadoParticipantes1FinalReportAp] SET IdDocumentoFinalReportAp = @IdDocumentoFinalReportAp WHERE IdDocumentoFinalReportAp = @IdDocumentoFinalReportApTMP
		UPDATE [tblInfFinalResultadoParticipantes2FinalReportAp] SET IdDocumentoFinalReportAp = @IdDocumentoFinalReportAp WHERE IdDocumentoFinalReportAp = @IdDocumentoFinalReportApTMP
		UPDATE [tblInfFinalResultadoNotasParticipantesCursos] SET IdDocumentoFinalReportAp = @IdDocumentoFinalReportAp WHERE IdDocumentoFinalReportAp = @IdDocumentoFinalReportApTMP
		UPDATE [tblInfFinalResultadoNotasParticipantes] SET IdDocumentoFinalReportAp = @IdDocumentoFinalReportAp WHERE IdDocumentoFinalReportAp = @IdDocumentoFinalReportApTMP
		UPDATE [tblInfFinalMemorandumFinalReportAp] SET IdDocumentoFinalReportAp = @IdDocumentoFinalReportAp WHERE IdDocumentoFinalReportAp = @IdDocumentoFinalReportApTMP
		UPDATE [tblInfFinalConsolidadoNotasEstudiantesRecuperados] SET IdDocumentoFinalReportAp = @IdDocumentoFinalReportAp WHERE IdDocumentoFinalReportAp = @IdDocumentoFinalReportApTMP
		UPDATE [tblInfFinalResultadoOrdenMeritoParticipantes] SET IdDocumentoFinalReportAp = @IdDocumentoFinalReportAp WHERE IdDocumentoFinalReportAp = @IdDocumentoFinalReportApTMP
		UPDATE [tblInfFinalCertificacionPrograma] SET IdDocumentoFinalReportAp = @IdDocumentoFinalReportAp WHERE IdDocumentoFinalReportAp = @IdDocumentoFinalReportApTMP
		UPDATE [tblInfFinalDatosdelosEstudiantes] SET IdDocumentoFinalReportAp = @IdDocumentoFinalReportAp WHERE IdDocumentoFinalReportAp = @IdDocumentoFinalReportApTMP
		UPDATE [tblInfFinalAnexos] SET IdDocumentoFinalReportAp = @IdDocumentoFinalReportAp WHERE IdDocumentoFinalReportAp = @IdDocumentoFinalReportApTMP

		UPDATE [dbo].[tblCodigoInformeFinal] SET NroCorrelativo = NroCorrelativo + 1 WHERE IdDocumento = @p_IdDocumento AND IdPrograma = @ProgramCode
		
        COMMIT TRAN GuardarInfFinalAP;
        
        SELECT 0 AS 'NRO_RESPUESTA', @IdDocumentoFinalReportAp AS 'MSG'
        
        DROP TABLE #RESULTADO
    END TRY
    BEGIN CATCH
		ROLLBACK TRAN GuardarInfFinalAP
    
        DECLARE @ErrorMessage NVARCHAR(4000);  
		DECLARE @ErrorSeverity INT;  
		DECLARE @ErrorState INT;
        
        SELECT -1 AS 'NRO_RESPUESTA',
            ERROR_MESSAGE() AS 'MSG';
		
		RAISERROR (@ErrorMessage,
		  @ErrorSeverity,
		  @ErrorState);
		
        DROP TABLE #RESULTADO
    END CATCH
END