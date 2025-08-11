USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [dbo].[sp_ResultadoNotasParticipantesFinalReportAp]
FECHA	: 03/06/2025
AUTOR	: Brus Paucar (Waytech)
OBJETIVO: Muestra los resultados de notas de los participantes
====================================================================================================*/

CREATE PROCEDURE [dbo].[sp_ResultadoNotasParticipantesFinalReportAp] 
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

        -- Tabla temporal para resultados
        CREATE TABLE #RESULTADO ( 
            Codigo VARCHAR(10),
            Apellidos_Nombres VARCHAR(200),
            Curso VARCHAR(200),
            Nota INT,
            Promedio INT,
            Tipo_Alumno VARCHAR(30),
            Estado_Academico VARCHAR(20),
            Estado_CAPP VARCHAR(10)
        )

        -- Consulta dinámica simplificada
        DECLARE @OracleQuery NVARCHAR(MAX) = N'
        WITH T_NOTAS AS (
            SELECT PIDM, DNI, STUDYPATH_BLOQUE, STUDYPATH_STATUS_DESC, NOMBRE, 
                   NRC||'' - ''||NOMBRE_CURSO AS NOMBRE_CURSO,
                   NVL(STYP_DESC,'' '') AS TIPO_ALUMNO, VERSION_PLAN, PROGRAM_CODE, 
                   DEPT_CODE, ASIGNATURA, ESTADO_ASIGNATURA,
                   PORCENT_INASISTENCIA, TO_NUMBER(NVL(GRDE_CODE,''0'')) AS NOTA
            FROM BANINST1.SZVALDI
            WHERE DNI IN (' + @StudentList + ')
                AND PROGRAM_CODE = ''' + @ProgramCode + '''
                AND SUBSTR(AREA_CODE,4,1)<>''C''                
                AND NVL(STUDYPATH_BLOQUE, '' '') = BLOQUE_MATRICULA
        ),
        T_RESUMEN AS (
            SELECT PIDM, STUDYPATH_BLOQUE, STUDYPATH_STATUS_DESC, VERSION_PLAN, 
                   PROGRAM_CODE, DEPT_CODE,
                   SUM(CASE WHEN ESTADO_ASIGNATURA=''Aprobado'' AND PORCENT_INASISTENCIA<=20 THEN 1 ELSE 0 END) AS CursosAprobados,
                   SUM(NOTA) AS SumaNotas
            FROM T_NOTAS
            GROUP BY PIDM, STUDYPATH_BLOQUE, STUDYPATH_STATUS_DESC, VERSION_PLAN, PROGRAM_CODE, DEPT_CODE
        )
        SELECT C.DNI AS CODIGO, C.NOMBRE AS APELLIDOS_NOMBRES, C.NOMBRE_CURSO AS CURSO, 
               C.NOTA, D.PROMEDIO, TIPO_ALUMNO, D.ESTADO_ACADEMICO,
               (CASE WHEN (SELECT MAX(NVL(SMBPOGN_REQUEST_NO,0))
                      FROM SATURN.SMBPOGN PO
                      WHERE PO.SMBPOGN_TERM_CODE_EFF=C.VERSION_PLAN 
                        AND PO.SMBPOGN_PROGRAM=C.PROGRAM_CODE 
                        AND PO.SMBPOGN_PIDM=C.PIDM)=0 THEN ''NO CAPP'' 
                                                   ELSE ''OK'' END) ESTADO_CAPP
        FROM T_NOTAS C
        INNER JOIN (
            SELECT A.PIDM, ROUND(A.SUMANOTAS/B.CANTCURSOS,0) AS PROMEDIO, 
                  (CASE WHEN A.CURSOSAPROBADOS=B.CANTCURSOS THEN ''APROBADO'' 
                        ELSE (CASE WHEN A.STUDYPATH_STATUS_DESC<>''Activo'' THEN A.STUDYPATH_STATUS_DESC 
                              ELSE ''DESAPROBADO'' END) END) AS ESTADO_ACADEMICO
            FROM T_RESUMEN A
            INNER JOIN (
                SELECT TERM_CODE_EFF, PROGRAM, MODALIDAD, COUNT(KEY_RULE) AS CANTCURSOS
                FROM BANINST1.SZVMALLA
                GROUP BY TERM_CODE_EFF, PROGRAM, MODALIDAD
            ) B ON B.TERM_CODE_EFF=A.VERSION_PLAN 
                AND B.PROGRAM=A.PROGRAM_CODE 
                AND B.MODALIDAD=A.DEPT_CODE
        ) D ON D.PIDM=C.PIDM'

        DECLARE @QUERY NVARCHAR(MAX) = N'
        INSERT INTO #RESULTADO (Codigo, Apellidos_Nombres, Curso, Nota, Promedio, Tipo_Alumno, Estado_Academico, Estado_CAPP)
        SELECT CODIGO, APELLIDOS_NOMBRES, CURSO, NOTA, PROMEDIO, TIPO_ALUMNO, ESTADO_ACADEMICO, ESTADO_CAPP
        FROM OPENQUERY(' + @BDOracle + ', ''' + REPLACE(@OracleQuery, '''', '''''') + ''')'

        EXEC sp_executesql @QUERY

        -- Resultados finales
        SELECT 
            STR(ROW_NUMBER() OVER (ORDER BY Codigo)) AS 'No',  
            Codigo,
            Apellidos_Nombres,
            Curso,
            Nota,
            Promedio,
            Tipo_Alumno,
            Estado_Academico,
            Estado_CAPP
        FROM #RESULTADO 
        ORDER BY Codigo, Apellidos_Nombres

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