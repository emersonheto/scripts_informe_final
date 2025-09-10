USE [BDUCCI]
GO
/* ===================================================================================================================
FECHA		: 09/09/2025
AUTOR		: Brus Paucar (WAYTECH)
OBJETIVO	: guardar los datos de configuración de cabecera para el documento MEMORANDUM
=================================================================================================================== */
BEGIN
	SET FMTONLY OFF
	BEGIN TRY
		BEGIN TRANSACTION
            INSERT INTO [dbo].[tblDatosMemoFinalReportAp] (
                NombreEncargado,
                Cargo,
                Uni,
                NombreCargo,
                Ciudad,
                NroEdicionA,
                NroEdicionB,
                Monto
            ) VALUES (
                'José Carlos Palomino Marmolejo',
                'Jefe de Registros Académicos de la Escuela de Posgrado - Lima',
                'Universidad Continental',
                'Jesus Augusto martinez Campian',
                'Huancayo',
                '',
                '',
                350.00
            );
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