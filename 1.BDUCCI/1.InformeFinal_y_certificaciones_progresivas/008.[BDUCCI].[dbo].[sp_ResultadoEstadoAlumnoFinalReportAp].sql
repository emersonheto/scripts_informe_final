USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [dbo].[sp_ResultadoEstadoAlumnoFinalReportAp]
FECHA	: 03/06/2025
AUTOR	: Brus Paucar (Waytech)
OBJETIVO: Muestra los resultados por estado de alumno
NRO		    FECHA		USUARIO					    MODIFICACION
1           22/09/2025  Emerson Herrera(Waytech)	Se agrega funcionalidad para verificar el �ltimo intento
====================================================================================================*/

ALTER PROCEDURE [dbo].[sp_ResultadoEstadoAlumnoFinalReportAp] 
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
            RAISERROR('El par�metro @XmlStudents debe contener datos XML v�lidos', 16, 1)
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

        -- Tabla temporal para resultados
        CREATE TABLE #RESULTADO ( 
            Estado VARCHAR(20),
            IDAlumno INT
        )

        -- Consulta din�mica simplificada
        DECLARE @OracleQuery NVARCHAR(MAX) = N'
				WITH EstadosPorArea AS (
							SELECT 
									A.PIDM,
									A.AREA_CODE,
									-- Calculamos cursos aprobados una sola vez
									SUM(CASE 
											WHEN A.ESTADO_ASIGNATURA = ''Aprobado'' 
													 AND A.PORCENT_INASISTENCIA <= 20 
											THEN 1 ELSE 0 
									END) AS CursosAprobados,
									B.CANTCURSOS_MALLA,
									MAX(A.STUDYPATH_STATUS_DESC) AS STUDYPATH_STATUS_DESC,
									-- Estado del �rea
									CASE 
											WHEN SUM(CASE 
															WHEN A.ESTADO_ASIGNATURA = ''Aprobado'' 
																	 AND A.PORCENT_INASISTENCIA <= 20 
															THEN 1 ELSE 0 
													 END) = B.CANTCURSOS_MALLA THEN ''APROBADO''
											WHEN MAX(A.STUDYPATH_STATUS_DESC) <> ''Activo'' THEN MAX(A.STUDYPATH_STATUS_DESC)
											ELSE ''DESAPROBADO''
									END AS ESTADO_AREA
							FROM BANINST1.SZVALDI A
							INNER JOIN (
									SELECT TERM_CODE_EFF, PROGRAM, MODALIDAD, AREA_CODE, COUNT(KEY_RULE) AS CANTCURSOS_MALLA
									FROM BANINST1.SZVMALLA
									GROUP BY TERM_CODE_EFF, PROGRAM, MODALIDAD, AREA_CODE
							) B ON B.TERM_CODE_EFF = A.VERSION_PLAN
									AND B.PROGRAM = A.PROGRAM_CODE
									AND B.MODALIDAD = A.DEPT_CODE
									AND B.AREA_CODE = A.AREA_CODE
							WHERE A.DNI IN (' + @StudentList + ')
								AND SUBSTR(A.AREA_CODE,4,1) <> ''C''
								AND A.PROGRAM_CODE = ''' + @ProgramCode + '''
							GROUP BY A.PIDM, A.AREA_CODE, B.CANTCURSOS_MALLA
					)

					SELECT 
							PIDM,
							CASE 
									WHEN COUNT(CASE WHEN ESTADO_AREA = ''DESAPROBADO'' THEN 1 END) > 0 THEN ''DESAPROBADO''
									WHEN COUNT(CASE WHEN ESTADO_AREA != ''APROBADO'' THEN 1 END) > 0 THEN MAX(ESTADO_AREA)
									ELSE ''APROBADO''
							END AS Estado_Academico
					FROM EstadosPorArea
					GROUP BY PIDM
					ORDER BY PIDM
				
				'

        DECLARE @QUERY NVARCHAR(MAX) = N'
        INSERT INTO #RESULTADO (Estado, IDAlumno)
        SELECT Estado_Academico AS Estado, PIDM AS IDAlumno
        FROM OPENQUERY(' + @BDOracle + ', ''' + REPLACE(@OracleQuery, '''', '''''') + ''')'

        EXEC sp_executesql @QUERY

        -- Resultados finales
        SELECT 
            Estado,
            COUNT(IDAlumno) AS Cantidad_Alumnos
        FROM #RESULTADO 
        GROUP BY Estado
        ORDER BY Estado

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