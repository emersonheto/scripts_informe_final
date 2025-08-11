USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [dbo].[sp_GetAllPrograms]
FECHA	: 03/06/2025
AUTOR	: Brus Paucar (Waytech)
OBJETIVO: Muestra la lista de programas
====================================================================================================*/

CREATE PROCEDURE [dbo].[sp_GetAllPrograms]
AS
SET NOCOUNT ON
BEGIN
	BEGIN TRY
		
		SELECT ProgramCode, ProgramDescription
		FROM 
		OPENQUERY(BANNER,'	SELECT DISTINCT SMRPRLE_PROGRAM AS "ProgramCode",
							NVL(SMRPRLE_DESCRIPTION, SMRPRLE_PROGRAM_DESC) AS "ProgramDescription"
							FROM SATURN.SMRPRLE								
							WHERE SMRPRLE_LEVL_CODE IN (''PS'',''EC'',''CO'')')		
	END TRY
	BEGIN CATCH
		DECLARE	@ErrorMessage VARCHAR(4000),
				@ErrorSeverity INT,
				@ErrorState INT;
		SELECT	@ErrorMessage =ERROR_MESSAGE(),
				@ErrorSeverity=ERROR_SEVERITY(),
				@ErrorState=ERROR_STATE();
				RAISERROR(@ErrorMessage,@ErrorSeverity,@ErrorState);
	END CATCH
END