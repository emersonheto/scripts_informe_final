USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [dbo].[sp_AddAnexosInfFinalAp]
FECHA	: 03/06/2025
AUTOR	: Alvaro Laveriano (Waytech)
OBJETIVO: Adiciona o elimina archivos anexos
====================================================================================================*/

CREATE PROCEDURE [dbo].[sp_AddAnexosInfFinalAp]
	@p_Seccion VARCHAR(50),
	@p_Orden VARCHAR(50),
	@p_NameFile VARCHAR(50),
	@p_Fecha VARCHAR(200),
	@p_TipoReporte INT,
	@p_Area VARCHAR(20),
	@p_Accion VARCHAR(200),
	@ProgramCode VARCHAR(3),
	@p_user_creacion VARCHAR(200),
    @p_IdDocumento VARCHAR(5),
    @p_IdDocumentoFinalReportAp VARCHAR(50)
AS
SET NOCOUNT ON
BEGIN
	BEGIN TRY
		SET @p_IdDocumentoFinalReportAp = (
			SELECT CONCAT(IdAnio, IdInforme, IdDocumento, IdPrograma, IdSede, FORMAT(NroCorrelativo + 1, 'TMP000'), REPLACE(@p_user_creacion, ' ', ''))
			FROM [dbo].[tblCodigoInformeFinal]
			WHERE IdDocumento = @p_IdDocumento
			  AND IdPrograma = @ProgramCode
		)
	
		 IF(@p_Accion=1)
			BEGIN
					INSERT [dbo].[tblInfFinalAnexos]([Seccion],[Archivo],[Orden],[Fecha],[Tipo_Reporte],[Area], [IdDocumentoFinalReportAp]) 
						VALUES (@p_Seccion,@p_NameFile,@p_Orden,@p_Fecha,@p_TipoReporte,@p_Area, @p_IdDocumentoFinalReportAp)

					SELECT 0 AS 'NRO_RESPUESTA','SE INSERTO CORRECTAMENTE EL ANEXO A LA SECCIÓN' AS 'MSG'
			END
		 ELSE IF(@p_Accion=2)
				BEGIN
					DELETE FROM [dbo].[tblInfFinalAnexos] 
					WHERE Seccion=@p_Seccion 
						AND Tipo_Reporte=@p_TipoReporte
						AND UPPER(ISNULL(Area,'')) = (CASE @p_TipoReporte WHEN 2 THEN UPPER(@p_Area) ELSE UPPER(ISNULL(Area,'')) END )

					SELECT 1 AS 'NRO_RESPUESTA','SE ELIMINARON CORRECTAMENTE LOS ANEXOS DE LA SECCION' AS 'MSG'
			END

	END TRY 
	BEGIN CATCH
	  SELECT -1 AS 'NRO_RESPUESTA',ERROR_MESSAGE() AS 'MSG'
	END CATCH
END