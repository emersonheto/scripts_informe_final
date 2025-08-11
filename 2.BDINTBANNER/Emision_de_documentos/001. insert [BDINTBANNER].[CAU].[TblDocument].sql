USE [BDINTBANNER]
GO
/* ===================================================================================================================
FECHA		: 03/06/2025
AUTOR		: Emerson Herrera (WAYTECH)
OBJETIVO	: Registrar nuevo documento de programas de certificación que se usa en el sp [pgpt].[tblGeneratedDocuments].
=================================================================================================================== */
BEGIN
	SET FMTONLY OFF
	BEGIN TRY
		BEGIN TRANSACTION
            INSERT INTO [CAU].[TblDocument] ([document], [documentName], [updateDate], [div], [generateDocument], [generateDebt], [OnlyFlow], [Description], [Enrrolment], [estimatedDays], [DateInit], [DateEnd], [documentExample], [CategoryId]) 
            VALUES (218, 'Certificado de Programas de Especialización AP', '2025-05-07 16:19:55.260', 'UCCI', '1', '1', '0', 'EPG-EMDOC-06', '0', -1, '2000-01-01 00:00:00.000', '2099-12-31 00:00:00.000', NULL, NULL); --1
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
