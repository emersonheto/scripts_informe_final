USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: dbo.sp_MemorandoRecuperadoAsignaturaFrAp
FECHA	: 22/09/2025
AUTOR	: Brus Paucar (WAYTECH)
OBJETIVO: Lista todas las notas de las asignaturas que ha cursado el alumno durante todo el programa.
MODIFICACIONES:
NRO					FECHA					USUARIO					MODIFICACION
====================================================================================================*/
CREATE PROCEDURE [dbo].[sp_MemorandoRecuperadoAsignaturaFrAp]
(
     @programCode VARCHAR(20),
     @DNI  VARCHAR(20)
)

AS 
SET NOCOUNT ON
BEGIN
	BEGIN TRY
	   DECLARE  @BDOracle VARCHAR(10)='BANNER';

       CREATE TABLE #RESULTADO ( 
	      Seccion  VARCHAR(20),
          Codigo VARCHAR(10),
          Apellidos_Nombres  VARCHAR(200),
	      Tipo_Programa  VARCHAR(100),
	      Nombre_Programa VARCHAR(200),
          Curso VARCHAR(200),
          Nota INT,
          Estado_Academico VARCHAR(20),
          Asignatura VARCHAR(10)
       )


       DECLARE @QUERY NVARCHAR(MAX) = '
            SELECT BLOQUE_MATRICULA,DNI,NOMBRE,TIPO,PROGRAM_DESC,NOMBRE_CURSO,GRDE_CODE,ESTADO_ASIGNATURA,ASIGNATURA
                FROM OPENQUERY ('+@BDOracle+',''
                SELECT
                    T1.BLOQUE_MATRICULA,
                    T1.DNI,
                    T1.NOMBRE,
                    (CASE WHEN T1.SUBJ_CODE = ''''PSDP'''' THEN ''''DIPLOMAS''''
                        WHEN T1.SUBJ_CODE = ''''PSEV'''' THEN ''''EVENTOS''''
                        WHEN T1.SUBJ_CODE = ''''PSMA'''' THEN ''''MAESTRIA''''
                        WHEN T1.SUBJ_CODE = ''''PSPA'''' THEN ''''PASANTIA''''
                        WHEN T1.SUBJ_CODE = ''''PSPE'''' THEN ''''PROGRAMAS DE ESPECIALIZACION''''
                        WHEN T1.SUBJ_CODE = ''''PSCC'''' THEN ''''CURSO CERRADO''''
                        WHEN T1.SUBJ_CODE = ''''PSCU'''' THEN ''''CURSO''''
                        WHEN T1.SUBJ_CODE = ''''PSDI'''' THEN ''''DIPLOMADO''''
                        WHEN T1.SUBJ_CODE = ''''PSDO'''' THEN ''''DOCTORADO'''' END) AS TIPO,
                    T1.PROGRAM_DESC,
                    T1.NOMBRE_CURSO,
                    T1.GRDE_CODE,    
                    T1.ESTADO_ASIGNATURA,
                    T1.ASIGNATURA
                FROM
                    BANINST1.SZVALDI T1
                WHERE
                    T1.DNI = ''''' + @DNI + ''''' 
                    AND T1.PROGRAM_CODE = ''''' + @programCode + ''''' 
                    AND SUBSTR(T1.AREA_CODE, 4, 1) <>''''C''''
                    AND T1.FECHA_TERMINO_NRC = (
                        SELECT
                            MAX(T2.FECHA_TERMINO_NRC)
                        FROM
                            BANINST1.SZVALDI T2
                        WHERE
                            T2.DNI = T1.DNI
                            AND T2.PROGRAM_CODE = T1.PROGRAM_CODE
                            AND T2.ASIGNATURA = T1.ASIGNATURA
                    )
                ORDER BY
                    T1.ASIGNATURA 
		   ''
		   )'
       
	   INSERT INTO #RESULTADO
       EXEC (@QUERY)

       SELECT 
			  Seccion,
			  Codigo ,
			  Apellidos_Nombres ,
			  Tipo_Programa,
			  Nombre_Programa,
			  Curso ,
			  ISNULL(Nota,0) AS Nota,
			  ISNULL(Estado_Academico,'') AS Estado_Academico,
              Asignatura AS Codigo_Curso
		   FROM #RESULTADO 
		   ORDER BY 1,2

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