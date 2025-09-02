USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [dbo].[sp_IdFinalReportAp]
FECHA	: 03/06/2025
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
				--FORMAT(NroCorrelativo + 1, 'TMP000'), 
				CONCAT('TMP', FORMAT(NroCorrelativo + 1, '000')),
				REPLACE(@UsuarioCreacion, ' ', '')
			) AS idFinalReportAp
		FROM 
			[dbo].[tblCodigoInformeFinal]
		WHERE 
			IdDocumento = @IdDocumento 
			AND IdPrograma = @ProgramCode;

		DROP TABLE #RESULTADO
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
