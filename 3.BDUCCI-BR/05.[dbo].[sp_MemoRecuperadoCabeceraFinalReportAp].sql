USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: dbo.sp_MemoRecuperadoCabecera
FECHA	: 14/10/2023
AUTOR	: Brus Paucar (WAYTECH)
OBJETIVO: Datos para la cabecera del MEMORANDUM, se obtienen de la tabla de configuración.
MODIFICACIONES:
NRO					FECHA					USUARIO					MODIFICACION
====================================================================================================*/

CREATE PROCEDURE [dbo].[sp_MemoRecuperadoCabeceraFinalReportAp]
(
	 @DNI  VARCHAR(20),
     @ProgramCode VARCHAR(3),
     @CodigoAsignatura VARCHAR(10)
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
				   AND PROGRAM_CODE=''''' + @ProgramCode + '''''
				   AND ASIGNATURA=''''' + @CodigoAsignatura + ''''' 
				   AND SUBSTR(AREA_CODE,4,1)<>''''C''''
       '')'
       
	   INSERT INTO #RESULTADO
       EXEC (@QUERY)

	   DECLARE @Curso VARCHAR(100)
	   DECLARE @Alumno VARCHAR(100)
       DECLARE @Nombre_Programa VARCHAR(200)

	   SELECT @Alumno=Apellidos_Nombres, @Curso=CURSO, @Nombre_Programa=Nombre_Programa
		   FROM #RESULTADO

		--obtenemos el correlativo con el formato '000-[anho 4 digitos]'
		EXEC sp_MemoRecuperadoCorrelativo @correlativo OUTPUT;

		SELECT
			@correlativo AS Correlativo,
			NombreEncargado,
			Cargo,
			Uni,
			NombreCargo,
			CONCAT(Ciudad, ', ', DATENAME(DAY, @fecha_actual), ' de ', DATENAME(MONTH, @fecha_actual), ' del ', DATENAME(YEAR, @fecha_actual)) AS Sedefecha,
			@Alumno AS NombreEstudiante,
			@Nombre_Programa AS NombrePrograma_A,
			@Nombre_Programa AS NombrePrograma_B,
			NroEdicionA AS NroEdicion_A,
			NroEdicionB AS NroEdicion_B,
			@DNI AS CodigoEstudiante,
			CONCAT('S/.', Monto) AS Monto,
			@Curso AS NombreAsignatura
		FROM dbo.tblDatosMemoFinalReportAp;

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

