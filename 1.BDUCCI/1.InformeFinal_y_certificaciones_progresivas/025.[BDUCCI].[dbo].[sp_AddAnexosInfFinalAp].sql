USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [dbo].[sp_AddAnexosInfFinalAp]
FECHA	: 03/06/2025
AUTOR	: Alvaro Laveriano (Waytech)
OBJETIVO: Adiciona o elimina archivos anexos
NRO		    FECHA		USUARIO					    MODIFICACION
1           17/09/2025  Emerson Herrera(Waytech)	Se agrega funcionalidad para verificar el último intento
====================================================================================================*/

ALTER PROCEDURE [dbo].[sp_AddAnexosInfFinalAp]	
	@p_Orden VARCHAR(50),
	@p_NameFile VARCHAR(50),
	@p_Fecha VARCHAR(200),
	@p_TipoReporte INT,
	@p_Area VARCHAR(20),
	@p_Accion VARCHAR(200),
    @p_IdDocumentoFinalReportAp VARCHAR(50)
AS
SET NOCOUNT ON
BEGIN
	BEGIN TRY
		 IF(@p_Accion=1)
			BEGIN
					INSERT [dbo].[tblInfFinalAnexos]([Seccion],[Archivo],[Orden],[Fecha],[Tipo_Reporte],[Area], [IdDocumentoFinalReportAp]) 
						VALUES ('',@p_NameFile,@p_Orden,@p_Fecha,@p_TipoReporte,@p_Area, @p_IdDocumentoFinalReportAp)

					SELECT 0 AS 'NRO_RESPUESTA','SE INSERTO CORRECTAMENTE EL ANEXO A LA SECCIÓN' AS 'MSG'
			END
		 ELSE IF(@p_Accion=2)
				BEGIN
					DELETE FROM [dbo].[tblInfFinalAnexos] 
					WHERE IdDocumentoFinalReportAp=@p_IdDocumentoFinalReportAp

					SELECT 1 AS 'NRO_RESPUESTA','SE ELIMINARON CORRECTAMENTE LOS ANEXOS DE LA SECCION' AS 'MSG'
			END

	END TRY 
	BEGIN CATCH
	  SELECT -1 AS 'NRO_RESPUESTA',ERROR_MESSAGE() AS 'MSG'
	END CATCH
END