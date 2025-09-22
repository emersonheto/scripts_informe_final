USE [BDUCCI]
GO
/*====================================================================================================
NOMBRE	: [dbo].[sp_GuardarDocumentoFinalReportAp]
FECHA	: 03/06/2025
AUTOR	: Alvaro Laveriano (Waytech)
OBJETIVO: Almacenar los Datos Generales del Informe Final AP.
MODIFICACIONES:
NRO					FECHA					USUARIO					MODIFICACION
001             22/09/2025         Brus Paucar (Waytech)          Se trae el id temporal que se cre� previamente evitando as� volver a crearlo aqu�.
====================================================================================================*/

ALTER PROCEDURE [dbo].[sp_GuardarDocumentoFinalReportAp]
    @PathDocumento VARCHAR(255),
    @UsuarioCreacion VARCHAR(200),
    @ProgramCode VARCHAR(3),
    @TipoReporte INT,
    @p_IdDocumento VARCHAR(5),
    @IdDocumentoFinalReportApTMP VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;        
DECLARE
        @IdDocumentoFinalReportAp VARCHAR(15),            
        @CleanUsuario VARCHAR(200),
        @IdSemiLimpio VARCHAR(20),
        @IdBase VARCHAR(15),      
        @NuevoCorrelativo VARCHAR(3);            
        
        SET @NuevoCorrelativo = (
            SELECT FORMAT(NroCorrelativo + 1, '000')
            FROM [dbo].[tblCodigoInformeFinal]
            WHERE IdDocumento = @p_IdDocumento
              AND IdPrograma = @ProgramCode
        );

        SET @CleanUsuario = REPLACE(@UsuarioCreacion, ' ', '');
        SET @IdSemiLimpio = REPLACE(
            REPLACE(@IdDocumentoFinalReportApTMP, @CleanUsuario, ''), 
            'TMP', 
            ''
        );

        SET @IdBase = LEFT(@IdSemiLimpio, LEN(@IdSemiLimpio) - 6);

        SET @IdDocumentoFinalReportAp = CONCAT(@IdBase, @NuevoCorrelativo);

        --Si el id ya existe, no guarda ni actualiza nada, solo retorna el id existente
        IF EXISTS (
            SELECT 1
            FROM [dbo].[tblDocumentoFinalReportAp]
            WHERE IdDocumentoFinalReportApTMP = @IdDocumentoFinalReportApTMP
        )
        BEGIN            
            SELECT 0 AS 'NRO_RESPUESTA',
            ( SELECT IdDocumentoFinalReportAp
            FROM [dbo].[tblDocumentoFinalReportAp]
            WHERE IdDocumentoFinalReportApTMP = @IdDocumentoFinalReportApTMP) AS 'MSG';
            RETURN;
        END

        BEGIN TRANSACTION GuardarInfFinalAP;

        BEGIN TRY
		
            SET @PathDocumento = REPLACE(@PathDocumento, '[CODIGO]', @IdDocumentoFinalReportAp)

            INSERT INTO [dbo].[tblDocumentoFinalReportAp] (
                IdDocumentoFinalReportAp,
                PathDocumento,
                FechaRegistro,
                UsuarioCreacion,
                TipoReporte,
                IdDocumentoFinalReportApTMP
            )
            VALUES (
                @IdDocumentoFinalReportAp,
                @PathDocumento,
                GETDATE(),
                @UsuarioCreacion,
                @TipoReporte,
                @IdDocumentoFinalReportApTMP
            )
            
            UPDATE [tblInfFinalSeccionCertificar] SET IdDocumentoFinalReportAp = @IdDocumentoFinalReportAp WHERE IdDocumentoFinalReportAp = @IdDocumentoFinalReportApTMP
            UPDATE [tblInfFinalProgramacionDocente] SET IdDocumentoFinalReportAp = @IdDocumentoFinalReportAp WHERE IdDocumentoFinalReportAp = @IdDocumentoFinalReportApTMP
            UPDATE [tblInfFinalResultadoParticipantes1FinalReportAp] SET IdDocumentoFinalReportAp = @IdDocumentoFinalReportAp WHERE IdDocumentoFinalReportAp = @IdDocumentoFinalReportApTMP
            UPDATE [tblInfFinalResultadoParticipantes2FinalReportAp] SET IdDocumentoFinalReportAp = @IdDocumentoFinalReportAp WHERE IdDocumentoFinalReportAp = @IdDocumentoFinalReportApTMP
            UPDATE [tblInfFinalResultadoNotasParticipantesCursos] SET IdDocumentoFinalReportAp = @IdDocumentoFinalReportAp WHERE IdDocumentoFinalReportAp = @IdDocumentoFinalReportApTMP
            UPDATE [tblInfFinalResultadoNotasParticipantes] SET IdDocumentoFinalReportAp = @IdDocumentoFinalReportAp WHERE IdDocumentoFinalReportAp = @IdDocumentoFinalReportApTMP
            UPDATE [tblInfFinalMemorandumFinalReportAp] SET IdDocumentoFinalReportAp = @IdDocumentoFinalReportAp WHERE IdDocumentoFinalReportAp = @IdDocumentoFinalReportApTMP
            UPDATE [tblInfFinalConsolidadoNotasEstudiantesRecuperadosCursos] SET IdDocumentoFinalReportAp = @IdDocumentoFinalReportAp WHERE IdDocumentoFinalReportAp = @IdDocumentoFinalReportApTMP
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