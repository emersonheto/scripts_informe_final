USE [BDUCCI]
GO
/* ===================================================================================================================
FECHA		: 03/06/2025
AUTOR		: Emerson Herrera (WAYTECH)
OBJETIVO	: Registrar nueva variable que se usa en la emisión de programas de certificación progresiva para Maestrias
=================================================================================================================== */
BEGIN
	SET FMTONLY OFF
	BEGIN TRY
		BEGIN TRANSACTION
           INSERT INTO pgpt.tblEmiParametro_UC ([Codigo], [Nombre], [Descripcion], [ValorTexto]) 
 		   VALUES ( 'RutC9', 'Ruta Certificacion Progr MaeAP', 'Ruta certificación progresiva Maestrias Report AP', 'CertProgMaeAP');
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
END
