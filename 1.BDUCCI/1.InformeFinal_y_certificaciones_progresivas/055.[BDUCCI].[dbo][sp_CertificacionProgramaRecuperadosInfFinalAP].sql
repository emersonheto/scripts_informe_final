USE BDUCCI;

CREATE PROCEDURE [dbo].[sp_CertificacionProgramaRecuperadosInfFinalAP] 
(
	 @ProgramCode VARCHAR(20),
	 @IdDocumentoFinalReportAp VARCHAR(15)
)

AS 
SET NOCOUNT ON
BEGIN
	BEGIN TRY

		CREATE TABLE #RESULTADO ( 
          Codigo VARCHAR(10),
	      Apellidos_Nombres  VARCHAR(200)
       )

	   INSERT INTO #RESULTADO
	   SELECT  DISTINCT 
			   Codigo ,
			   Apellidos_Nombres
		   FROM [dbo].[tblInfFinalMemorandumRecuperados]  --[dbo].[tblInfFinal_Memorandum_Recuperados] 
		   WHERE Programa_Codigo=@ProgramCode 
			 AND IdDocumentoFinalReportAp = @IdDocumentoFinalReportAp 
			 
		   --ORDER BY Apellidos_Nombres

	   SELECT 
			   STR(ROW_NUMBER() OVER (ORDER BY Apellidos_Nombres))   AS 'No', 
			   Codigo,Apellidos_Nombres
		   FROM #RESULTADO;

	   DROP TABLE #RESULTADO

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
END