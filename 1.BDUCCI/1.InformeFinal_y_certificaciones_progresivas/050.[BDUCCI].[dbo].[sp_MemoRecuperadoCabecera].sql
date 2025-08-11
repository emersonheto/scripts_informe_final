USE [BDUCCI]
GO
/*====================================================================================================
NOMBRE	: dbo.sp_MemoRecuperadoCabecera
FECHA	: 25/01/2024
AUTOR	: Marcelo Cipriano (SOLMIT)
OBJETIVO: Lista los datos que se necesita para el reporte de memorandum de recuperados, en la aplicación Informe Final (CUS-020)
MODIFICACIONES:
NRO					FECHA					USUARIO					MODIFICACION
001				03/06/2025				Brus Paucar (Waytech)	se añade Tipo_Reporte=4 y se controla cuando EDICION = null
====================================================================================================*/

ALTER PROCEDURE [dbo].[sp_MemoRecuperadoCabecera]
(
	 @Seccion VARCHAR(20),
	 @SeccionAntigua VARCHAR(20),
	 @DNI  VARCHAR(20)
)
AS
SET NOCOUNT ON;
BEGIN
	BEGIN TRY
		SET LANGUAGE Spanish;

		DECLARE @correlativo CHAR(8),
			@fecha_actual DATE = GETDATE();

	   DECLARE  @BDOracle varchar(10)='BANNER';

       CREATE TABLE #RESULTADO ( 
          Codigo VARCHAR(10),
          Apellidos_Nombres  VARCHAR(200),
	      Nombre_Programa VARCHAR(200),
          Curso VARCHAR(200),
       )

       DECLARE @QUERY NVARCHAR(MAX) = '
       SELECT DNI,NOMBRE,PROGRAM_DESC,NOMBRE_CURSO
		   FROM OPENQUERY ('+@BDOracle+',''
		   SELECT DNI,NOMBRE,PROGRAM_DESC,NOMBRE_CURSO
			   FROM BANINST1.SZVALDI
			   WHERE DNI=''''' + @DNI + ''''' 
				   AND NVL(STUDYPATH_BLOQUE,'''' '''')=''''' + @SeccionAntigua + '''''
				   AND BLOQUE_MATRICULA=''''' + @Seccion + ''''' 
				   AND SUBSTR(AREA_CODE,4,1)<>''''C''''
       '')'
       
	   INSERT INTO #RESULTADO
       EXEC (@QUERY)

	   DECLARE @Curso VARCHAR(100)
	   DECLARE @Alumno VARCHAR(100)

	   SELECT @Alumno=Apellidos_Nombres, @Curso=CURSO 
		   FROM #RESULTADO

		--obtenemos el correlativo con el formato '000-[anho 4 digitos]'
		EXEC sp_MemoRecuperadoCorrelativo @correlativo OUTPUT;

		SELECT @correlativo Correlativo,
				  'Gabriela Jurado Chamorro' NombreEncargado,
				  'Jefe de Admision, Registros y Certificacion - Posgrado - Lima' Cargo,
				  'Universidad Continental' Uni,
				  'Jesus Augusto martinez Campian' NombreCargo,
				  CONCAT(	'Huancayo, ', DATENAME(DAY, @fecha_actual), ' de ', DATENAME(MONTH, @fecha_actual), ' del ', DATENAME(YEAR, @fecha_actual)) Sedefecha,
				  @Alumno NombreEstudiante,
				  Nombre_Programa AS NombrePrograma_A,
				  Nombre_Programa AS NombrePrograma_B,
				  SUBSTRING(@SeccionAntigua,LEN(@SeccionAntigua)-1,2) AS NroEdicion_A,
				  ISNULL(EDICION, '') AS NroEdicion_B,
				  @DNI CodigoEstudiante,
				  'S/.350.00' Monto,
				  @Curso NombreAsignatura
			FROM dbo.tblInfFinalSeccionCertificar
			WHERE Seccion=@Seccion
			AND (Tipo_Reporte=1 OR Tipo_Reporte=4)

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
END;

