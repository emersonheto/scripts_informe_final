USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [BANNER].[sp_AddInfFinalSeccionCertificarAP]
FECHA	: 03/06/2025
AUTOR	: Alvaro Laveriano (Waytech)
OBJETIVO: Registro de la información de la sección a certificar

NRO		    FECHA		USUARIO					    MODIFICACIÓN
1           17/09/2025  Emerson Herrera(Waytech)	Se agrega funcionalidad para verificar el último intento y solo se tome en cuenta el id del codigo de reporte de informe final
====================================================================================================*/

ALTER PROCEDURE [BANNER].[sp_AddInfFinalSeccionCertificarAP] 
(
	 @Seccion VARCHAR(20),
     @Estudiante VARCHAR(20),
     @ProgramCode VARCHAR(3),
	 @p_Tipo_Reporte INT,
	 @p_user_creacion VARCHAR(200),
	 @p_Area VARCHAR(20) = NULL,
	 @p_Accion INT
)
AS 
SET NOCOUNT ON
BEGIN
   BEGIN TRY

		IF (@p_Accion=1)
		BEGIN
			DECLARE        
	        @BDOracle VARCHAR(10) = 'BANNER'
	        
	        CREATE TABLE #RESULTADO (
	            PROGRAMA VARCHAR(100),
	            SEDE VARCHAR(20),
	            FECHA_INICIO DATETIME,
	            FECHA_FIN DATETIME
	        )
	        
	        DECLARE @OracleQuery NVARCHAR(MAX) = N'
	        SELECT PROGRAM_DESC
	        	  ,REPLACE(REPLACE (CAMP_DESC, ''SEDE '', ''''), ''FILIAL '', '''') AS CAMP_DESC
	        	  ,MIN(FECHA_INICIO_NRC) AS FECHA_INICIO_NRC
	        	  ,MAX(FECHA_TERMINO_NRC) AS FECHA_TERMINO_NRC
			FROM BANINST1.SZVALDI
			WHERE PROGRAM_CODE = ''' + @ProgramCode + ''' AND DNI = ''' + @Estudiante + ''' 
			GROUP BY PROGRAM_DESC, CAMP_DESC'
	        
			DECLARE @QUERY NVARCHAR(MAX) = N'
	        INSERT INTO #RESULTADO (PROGRAMA, SEDE, FECHA_INICIO, FECHA_FIN)
	        SELECT PROGRAM_DESC, CAMP_DESC, FECHA_INICIO_NRC, FECHA_TERMINO_NRC
	        FROM OPENQUERY(' + @BDOracle + ', ''' + REPLACE(@OracleQuery, '''', '''''') + ''')'
	
	        EXEC sp_executesql @QUERY
			
			INSERT INTO [dbo].[tblInfFinalSeccionCertificar]
			SELECT
				@Seccion
			   ,PROGRAMA
			   ,SEDE
			   ,NULL
			   ,NULL
			   ,CONVERT(DATETIME, FECHA_INICIO)
			   ,CONVERT(DATETIME, FECHA_FIN)
			   ,NULL
			   ,NULL
			   ,GETDATE()
			   ,NULL
			   ,@p_user_creacion
			   ,NULL
			   ,@p_Tipo_Reporte
			   ,CASE
				   	WHEN @p_Tipo_Reporte = 4 THEN ''
				   	WHEN @p_Tipo_Reporte = 5 Then @p_Area
				END [Area]
			FROM #RESULTADO
			
			SELECT 0 AS 'NRO_RESPUESTA',
		           'SE INSERTÓ CORRECTAMENTE LOS PARTICIPANTES' AS 'MSG'
		END
		ELSE IF(@p_Accion=2)
		BEGIN
				DELETE FROM [dbo].[tblInfFinalSeccionCertificar] WHERE Seccion=@Seccion
				SELECT 1 AS 'NRO_RESPUESTA',
		              'SE ELIMINÓ CORRECTAMENTE RESULTADO DE NOTAS DE LOS PARTICIPANTES' AS 'MSG'
		END
   END TRY
   BEGIN CATCH
	SELECT 
     ERROR_NUMBER() AS ERROR_NUMBER,
     ERROR_MESSAGE() AS ERROR_MESSAGE
   END CATCH
END