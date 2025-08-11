USE [BDUCCI]
GO

/* ===================================================================================================================
FECHA		: 03/06/2025
AUTOR		: Alvaro Laveriano (WAYTECH)
OBJETIVO	: Insertar registros en la tabla tblCodigoInformeFinal
=================================================================================================================== */
BEGIN
	SET FMTONLY OFF
	BEGIN TRY
		BEGIN TRANSACTION
            INSERT INTO [dbo].[tblCodigoInformeFinal] VALUES ('INF', 'IF', 'MGP', 'AP', 0)
            INSERT INTO [dbo].[tblCodigoInformeFinal] VALUES ('INF', 'IF', 'MGR', 'AP', 0)
            INSERT INTO [dbo].[tblCodigoInformeFinal] VALUES ('INF', 'IF', 'MGS', 'AP', 0)
            INSERT INTO [dbo].[tblCodigoInformeFinal] VALUES ('INF', 'IF', 'MGD', 'AP', 0)
            INSERT INTO [dbo].[tblCodigoInformeFinal] VALUES ('INF', 'IF', 'MCI', 'AP', 0)
            INSERT INTO [dbo].[tblCodigoInformeFinal] VALUES ('INF', 'IF', 'MSH', 'AP', 0)
            INSERT INTO [dbo].[tblCodigoInformeFinal] VALUES ('INF', 'IF', 'MDU', 'AP', 0)
            INSERT INTO [dbo].[tblCodigoInformeFinal] VALUES ('INF', 'IF', 'MAF', 'AP', 0)
            INSERT INTO [dbo].[tblCodigoInformeFinal] VALUES ('INF', 'IF', 'MPS', 'AP', 0)
            INSERT INTO [dbo].[tblCodigoInformeFinal] VALUES ('INF', 'IF', 'MSI', 'AP', 0)
            INSERT INTO [dbo].[tblCodigoInformeFinal] VALUES ('INF', 'IF', 'MNE', 'AP', 0)
            INSERT INTO [dbo].[tblCodigoInformeFinal] VALUES ('INF', 'IF', 'MSU', 'AP', 0)
            INSERT INTO [dbo].[tblCodigoInformeFinal] VALUES ('INF', 'IF', 'MNI', 'AP', 0)
            INSERT INTO [dbo].[tblCodigoInformeFinal] VALUES ('INF', 'IF', 'MDG', 'AP', 0)

            INSERT INTO [dbo].[tblCodigoInformeFinal] VALUES ('INF', 'IF', 'AEM', 'AP', 0)
            INSERT INTO [dbo].[tblCodigoInformeFinal] VALUES ('INF', 'IF', 'CGR', 'AP', 0)
            INSERT INTO [dbo].[tblCodigoInformeFinal] VALUES ('INF', 'IF', 'NIF', 'AP', 0)
            INSERT INTO [dbo].[tblCodigoInformeFinal] VALUES ('INF', 'IF', 'PMA', 'AP', 0)
            INSERT INTO [dbo].[tblCodigoInformeFinal] VALUES ('INF', 'IF', 'PGT', 'AP', 0)
            INSERT INTO [dbo].[tblCodigoInformeFinal] VALUES ('INF', 'IF', 'HSE', 'AP', 0)
            INSERT INTO [dbo].[tblCodigoInformeFinal] VALUES ('INF', 'IF', 'REH', 'AP', 0)
            INSERT INTO [dbo].[tblCodigoInformeFinal] VALUES ('INF', 'IF', 'DFO', 'AP', 0)
            INSERT INTO [dbo].[tblCodigoInformeFinal] VALUES ('INF', 'IF', 'RIB', 'AP', 0)
            INSERT INTO [dbo].[tblCodigoInformeFinal] VALUES ('INF', 'IF', 'VAL', 'AP', 0)

            INSERT INTO [dbo].[tblCodigoInformeFinal] VALUES ('INF', 'CP', 'MGP', 'AP', 0)
            INSERT INTO [dbo].[tblCodigoInformeFinal] VALUES ('INF', 'CP', 'MGR', 'AP', 0)
            INSERT INTO [dbo].[tblCodigoInformeFinal] VALUES ('INF', 'CP', 'MGS', 'AP', 0)
            INSERT INTO [dbo].[tblCodigoInformeFinal] VALUES ('INF', 'CP', 'MGD', 'AP', 0)
            INSERT INTO [dbo].[tblCodigoInformeFinal] VALUES ('INF', 'CP', 'MCI', 'AP', 0)
            INSERT INTO [dbo].[tblCodigoInformeFinal] VALUES ('INF', 'CP', 'MSH', 'AP', 0)
            INSERT INTO [dbo].[tblCodigoInformeFinal] VALUES ('INF', 'CP', 'MDU', 'AP', 0)
            INSERT INTO [dbo].[tblCodigoInformeFinal] VALUES ('INF', 'CP', 'MAF', 'AP', 0)
            INSERT INTO [dbo].[tblCodigoInformeFinal] VALUES ('INF', 'CP', 'MPS', 'AP', 0)
            INSERT INTO [dbo].[tblCodigoInformeFinal] VALUES ('INF', 'CP', 'MSI', 'AP', 0)
            INSERT INTO [dbo].[tblCodigoInformeFinal] VALUES ('INF', 'CP', 'MNE', 'AP', 0)
            INSERT INTO [dbo].[tblCodigoInformeFinal] VALUES ('INF', 'CP', 'MSU', 'AP', 0)
            INSERT INTO [dbo].[tblCodigoInformeFinal] VALUES ('INF', 'CP', 'MNI', 'AP', 0)
            INSERT INTO [dbo].[tblCodigoInformeFinal] VALUES ('INF', 'CP', 'MDG', 'AP', 0)
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