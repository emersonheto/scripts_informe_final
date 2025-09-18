USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [BANNER].[sp_CertificacionProgramaRecuperadosInfFinalAP]
FECHA	: 17/09/2025
AUTOR	: Emerson Herrera (Waytech)
OBJETIVO: Se agrega funcionalidad para verificar el último intento y solo se tome en cuenta el id del codigo de reporte de informe final
====================================================================================================*/


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
			   A.Codigo ,
			   A.ApellidosNombres
		   FROM [dbo].[tblInfFinalMemorandumFinalReportAp] AS A 
			 INNER JOIN [dbo].tblInfFinalCertificacionPrograma AS B 
			 ON A.IdDocumentoFinalReportAp = B.IdDocumentoFinalReportAp 
			 AND A.Codigo = B.Codigo
			 
			 WHERE A.ProgramaCodigo=@ProgramCode 
			 AND A.IdDocumentoFinalReportAp = @IdDocumentoFinalReportAp 

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