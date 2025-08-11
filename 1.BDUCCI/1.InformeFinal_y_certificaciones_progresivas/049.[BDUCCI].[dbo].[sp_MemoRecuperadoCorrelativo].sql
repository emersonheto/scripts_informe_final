USE [BDUCCI]
GO
/*====================================================================================================
NOMBRE	: dbo.sp_MemoRecuperadoCorrelativo
FECHA	: 25/01/2024
AUTOR	: Marcelo Cipriano (SOLMIT)
OBJETIVO: Generar correlativo por año para el reporte de memorandum de recuperados, en la aplicación Informe Final (CUS-020)
MODIFICACIONES:
NRO					FECHA					USUARIO					MODIFICACION
001					03/06/2025				Brus Paucar (Waytech)	Se cambia de nombre a tblInfFinalMemoRecuperadoCorrelativo, que es el que existe en BD
====================================================================================================*/

ALTER PROCEDURE [dbo].[sp_MemoRecuperadoCorrelativo]
	@correlativo CHAR(8) OUTPUT
AS
SET NOCOUNT OFF;
BEGIN
	BEGIN TRY
		DECLARE @anho CHAR(4) = YEAR(GETDATE()),
			@numerocorrelativo INT;

		SELECT @numerocorrelativo = NumeroCorrelativo + 1
			FROM dbo.tblInfFinalMemoRecuperadoCorrelativo
			WHERE AnhoCorrelativo = @anho;

		IF @numerocorrelativo IS NULL
		BEGIN
			INSERT INTO dbo.tblInfFinalMemoRecuperadoCorrelativo (NumeroCorrelativo,AnhoCorrelativo)
				VALUES (1,@anho);

			SET @correlativo = '001' + '-' + @anho;
		END;
		ELSE
		BEGIN
			UPDATE dbo.tblInfFinalMemoRecuperadoCorrelativo
				SET NumeroCorrelativo = @numerocorrelativo
				WHERE AnhoCorrelativo = @anho;

			SET @correlativo = FORMAT(@numerocorrelativo, '000') + '-' + @anho;
		END;

		RETURN;
	END TRY
	BEGIN CATCH
		DECLARE	@ErrorMessage VARCHAR(4000),
				@ErrorSeverity INT,
				@ErrorState INT;
		SELECT	@ErrorMessage =ERROR_MESSAGE(),
				@ErrorSeverity=ERROR_SEVERITY(),
				@ErrorState=ERROR_STATE();
				RAISERROR(@ErrorMessage,@ErrorSeverity,@ErrorState);
				SELECT @ErrorMessage AS status
	END CATCH
END;

