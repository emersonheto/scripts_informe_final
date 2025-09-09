USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [dbo].[sp_ResultadoOrdenMeritoFinalReportAp]
FECHA	: 03/06/2025
AUTOR	: Brus Paucar (Waytech)
OBJETIVO: Muestra los resultados de orden de mérito de los alumnos
NRO		    FECHA		USUARIO					    MODIFICACION
1           08/09/2025  Emerson Herrera(Waytech)	Se agrega funcionalidad para verificar el último intento
====================================================================================================*/

ALTER PROCEDURE [dbo].[sp_ResultadoOrdenMeritoFinalReportAp] 
(
    @XmlStudents XML,
    @ProgramCode VARCHAR(3)
)
AS 
SET NOCOUNT ON
BEGIN
    BEGIN TRY
        -- Validar XML de entrada
        IF @XmlStudents IS NULL OR @XmlStudents.exist('/Students[1]') = 0
        BEGIN
            RAISERROR('El parámetro @XmlStudents debe contener datos XML válidos', 16, 1)
            RETURN
        END
        
        -- Crear tabla temporal para los estudiantes
        DECLARE @Students TABLE (
            StudentCode VARCHAR(9)
        )

        -- Insertar datos del XML
        INSERT INTO @Students (StudentCode)
        SELECT 
            Student.value('(StudentCode)[1]', 'VARCHAR(9)') AS StudentCode
        FROM @XmlStudents.nodes('/Students/Student') AS T(Student)

        DECLARE @BDOracle VARCHAR(10) = 'BANNER';

        -- Construir lista de Students para Oracle
        DECLARE @StudentList NVARCHAR(MAX) = ''
        SELECT @StudentList = @StudentList + '''' + REPLACE(StudentCode, '''', '''''') + ''',' 
        FROM @Students
        
        IF LEN(@StudentList) > 0
            SET @StudentList = LEFT(@StudentList, LEN(@StudentList) - 1)

        -- Tabla temporal para resultados (igual a la original)
        CREATE TABLE #RESULTADO ( 
            Codigo VARCHAR(10),
            Apellidos_Nombres VARCHAR(200),
            Curso VARCHAR(200),
            Nota INT,
            Promedio FLOAT,
            Orden VARCHAR(30)
        )
				 

        -- Consulta dinámica manteniendo la estructura original pero con nuevos filtros
        DECLARE @OracleQuery NVARCHAR(MAX) = N'	
				WITH datos_base AS (
						SELECT DISTINCT
								PIDM, DNI, STUDYPATH_STATUS_DESC, NOMBRE,
								A.SUBJ_CODE||A.CRSE_NUMB||'' - ''||A.NOMBRE_CURSO AS NOMBRE_CURSO,
								VERSION_PLAN, PROGRAM_CODE, DEPT_CODE, ASIGNATURA, 
								ESTADO_ASIGNATURA, PORCENT_INASISTENCIA, 
								TO_NUMBER(NVL(GRDE_CODE,''0'')) AS NOTA,
								COUNT(A.NRC) OVER (PARTITION BY A.DNI, A.SUBJ_CODE, A.CRSE_NUMB) AS total_intentos,
								ROW_NUMBER() OVER (PARTITION BY A.DNI, A.SUBJ_CODE, A.CRSE_NUMB ORDER BY A.FECHA_INICIO_NRC ASC) AS primer_intento,
								ROW_NUMBER() OVER (PARTITION BY A.DNI, A.SUBJ_CODE, A.CRSE_NUMB ORDER BY A.FECHA_INICIO_NRC DESC) AS ultimo_intento 
						FROM BANINST1.SZVALDI A
						WHERE   
								A.DNI IN (' + @StudentList + ')     
								AND  A.PROGRAM_CODE =  ''' + @ProgramCode + ''' 
								AND SUBSTR(A.AREA_CODE,4,1) <> ''C''
				),		
				T_NOTAS AS (
						SELECT 
								PIDM, DNI, STUDYPATH_STATUS_DESC, NOMBRE, NOMBRE_CURSO, 
								VERSION_PLAN, PROGRAM_CODE, DEPT_CODE, ASIGNATURA, 
								ESTADO_ASIGNATURA, PORCENT_INASISTENCIA, NOTA
						FROM datos_base
						WHERE ultimo_intento = 1
				)
				 ,T_RESUMEN AS (
						SELECT 
								PIDM, DNI, NOMBRE, VERSION_PLAN, PROGRAM_CODE, DEPT_CODE,
								SUM(CASE WHEN ESTADO_ASIGNATURA=''Aprobado'' AND PORCENT_INASISTENCIA<=20 THEN 1 ELSE 0 END) AS CursosAprobados,
								SUM(CASE WHEN ESTADO_ASIGNATURA=''Aprobado'' AND PORCENT_INASISTENCIA<=20 THEN NOTA ELSE 0 END) AS SumaNotas,
								COUNT(*) AS TotalCursos
						FROM T_NOTAS
						GROUP BY PIDM, DNI, NOMBRE, VERSION_PLAN, PROGRAM_CODE, DEPT_CODE
				)
				 , T_APROBADOS AS (
						SELECT 
								A.PIDM, A.DNI, A.NOMBRE, 
								A.SUMANOTAS, B.CANTCURSOS, A.CURSOSAPROBADOS,
								ROUND(AVG(A.SUMANOTAS / B.CANTCURSOS), 2) AS PROMEDIO
						FROM T_RESUMEN A
						INNER JOIN (
								SELECT TERM_CODE_EFF, PROGRAM, MODALIDAD,  COUNT(KEY_RULE) AS CANTCURSOS
								FROM BANINST1.SZVMALLA
								WHERE SUBSTR(AREA_CODE,4,1) <> ''C''
								GROUP BY TERM_CODE_EFF, PROGRAM, MODALIDAD
						) B ON B.TERM_CODE_EFF = A.VERSION_PLAN 
							 AND B.PROGRAM = A.PROGRAM_CODE 
							 AND B.MODALIDAD = A.DEPT_CODE 
						WHERE A.CURSOSAPROBADOS = B.CANTCURSOS  -- Solo estudiantes que completaron todo
						 GROUP BY A.PIDM, A.DNI, A.NOMBRE,  A.SUMANOTAS, B.CANTCURSOS , A.CURSOSAPROBADOS
				) 

				,T_RANKING AS (
						SELECT 
								PIDM, DNI, NOMBRE, PROMEDIO,
								DENSE_RANK() OVER (ORDER BY PROMEDIO DESC) AS ORDEN
						FROM  
						T_APROBADOS 
				),
				T_TOP3 AS (
						SELECT *
						FROM T_RANKING
						WHERE ORDEN <= 3
				)
				-- ==========================================
				-- CONSULTA FINAL PARA EL ORDEN DE MÉRITO
				-- ==========================================
				SELECT 
						-- ROW_NUMBER() OVER (ORDER BY R.ORDEN, R.PROMEDIO DESC, R.NOMBRE) AS Nro,
						R.DNI AS Codigo,
						R.NOMBRE AS Apellidos_Nombres,
						N.NOMBRE_CURSO AS Curso,
						N.NOTA AS Nota,						
						R.PROMEDIO AS Promedio,
						CASE 
								WHEN R.ORDEN = 1 THEN ''PRIMER LUGAR''
								WHEN R.ORDEN = 2 THEN ''SEGUNDO LUGAR'' 
								WHEN R.ORDEN = 3 THEN ''TERCER LUGAR''
								ELSE TO_CHAR(R.ORDEN)
						END AS Orden
				FROM T_TOP3 R
				INNER JOIN T_NOTAS N ON R.PIDM = N.PIDM
				WHERE N.ESTADO_ASIGNATURA = ''Aprobado'' AND N.PORCENT_INASISTENCIA <= 20
				-- GROUP BY R.DNI, R.NOMBRE, R.PROMEDIO, R.ORDEN
				ORDER BY R.ORDEN, R.PROMEDIO DESC, R.NOMBRE
			 '

        DECLARE @QUERY NVARCHAR(MAX) = N'
        INSERT INTO #RESULTADO (Codigo, Apellidos_Nombres, Curso, Nota, Promedio, Orden)
        SELECT Codigo, 
               Apellidos_Nombres,
               Curso,
               Nota,
               Promedio,
               Orden
        FROM OPENQUERY(' + @BDOracle + ', ''' + REPLACE(@OracleQuery, '''', '''''') + ''')'

        EXEC sp_executesql @QUERY

        -- Resultados finales (igual al original)
        SELECT 
            STR(ROW_NUMBER() OVER (ORDER BY Promedio DESC)) AS 'No',  
            Codigo,
            Apellidos_Nombres,
            Curso,
            CONVERT(VARCHAR,Nota) AS Nota,
            CONVERT(VARCHAR,ROUND(Promedio,2)) AS Promedio,
            Orden
        FROM #RESULTADO 
        ORDER BY Promedio DESC, Apellidos_Nombres

        DROP TABLE #RESULTADO
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000),
                @ErrorSeverity INT,
                @ErrorState INT;
        SELECT @ErrorMessage = ERROR_MESSAGE(),
               @ErrorSeverity = ERROR_SEVERITY(),
               @ErrorState = ERROR_STATE();
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        SELECT @ErrorMessage AS status
    END CATCH
END