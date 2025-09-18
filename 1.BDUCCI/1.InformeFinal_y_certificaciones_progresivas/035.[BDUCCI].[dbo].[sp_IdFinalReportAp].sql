USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [dbo].[sp_IdFinalReportAp]
FECHA	: 17/09/2025
AUTOR	: Brus Paucar (Waytech)
OBJETIVO: Obtiene el id: IdDocumentoFinalReportApTMP
====================================================================================================*/

CREATE PROCEDURE [dbo].[sp_IdFinalReportAp]
(
    @ProgramCode VARCHAR(3),
    @IdDocumento VARCHAR(5),
    @UsuarioCreacion VARCHAR(200)
)
AS
SET NOCOUNT ON
BEGIN
    BEGIN TRY
        SELECT
            CONCAT(
                IdAnio,
                IdInforme,
                IdDocumento,
                IdPrograma,
                IdSede,
                'TMP',
                UPPER(SUBSTRING(REPLACE(CAST(NEWID() AS VARCHAR(36)), '-', ''), 1, 6)),
                REPLACE(@UsuarioCreacion, ' ', '')
            ) AS idFinalReportAp
        FROM
            [dbo].[tblCodigoInformeFinal]
        WHERE
            IdDocumento = @IdDocumento
            AND IdPrograma = @ProgramCode;

    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000),
                @ErrorSeverity INT,
                @ErrorState INT;
        SELECT @ErrorMessage = ERROR_MESSAGE(),
               @ErrorSeverity = ERROR_SEVERITY(),
               @ErrorState = ERROR_STATE();
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        SELECT @ErrorMessage AS status
    END CATCH
END